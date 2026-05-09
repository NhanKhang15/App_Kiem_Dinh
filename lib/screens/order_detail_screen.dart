import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vehicle_registration_app/models/order_model.dart';
import 'package:vehicle_registration_app/screens/document_upload_screen.dart';
import 'package:vehicle_registration_app/screens/vehicle_receipt_screen.dart';
import 'package:vehicle_registration_app/screens/vehicle_return_screen.dart';
import 'package:vehicle_registration_app/services/staff_service.dart';
import 'package:vehicle_registration_app/widgets/in_app_document_viewer.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String statusLabel;
  final OrderStatusType statusType;

  const OrderDetailScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.statusLabel,
    required this.statusType,
  });

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const String _docWebAssetPath = 'text/order_2_524dab46.docx';
  static const String _pdfWebAssetPath = 'text/order_2_524dab46.pdf';
  static const Duration _minInterval = Duration(seconds: 5);
  static const Duration _maxInterval = Duration(seconds: 30);
  static const double _noiseThreshold = 5.0;
  static const double _distanceThreshold = 20.0;
  static const double _headingThreshold = 15.0;

  final StaffService _staffService = StaffService();
  OrderModel? _order;
  bool _isLoading = true;
  StreamSubscription<Position>? _positionStream;
  Position? _lastPushedPosition;
  double? _lastHeading;
  DateTime? _lastPushedTime;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _isLoading = true);
    try {
      final order = await _staffService.getOrderDetail(widget.orderId);
      debugPrint(
        'Order detail map data => address: ${order.stationAddress}, lat: ${order.stationLat}, lng: ${order.stationLng}',
      );
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
      if (_trackingStatuses.contains(order.statusType)) {
        await _startTracking();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Loi tai chi tiet: $e')),
      );
    }
  }

  static const Set<String> _trackingStatuses = {
    'confirmed',
    'en_route',
    'receiving',
    'inspecting',
    'returning',
    'in_progress',
    'waiting_payment',
  };

  Future<void> _startTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    await _sendCurrentLocation();
    await _positionStream?.cancel();
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((position) => _processNewPosition(position));

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _sendCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _processNewPosition(position, forcePush: true);
    } catch (_) {}
  }

  Future<void> _processNewPosition(Position position,
      {bool forcePush = false}) async {
    final order = _order;
    if (order == null) return;

    final now = DateTime.now();
    var shouldPush = forcePush;
    var distance = 0.0;
    var newHeading = _lastHeading;
    var timeSinceLast = Duration.zero;
    var reason = forcePush ? 'Force push' : 'Filtered';

    if (!forcePush && _lastPushedPosition != null && _lastPushedTime != null) {
      distance = Geolocator.distanceBetween(
        _lastPushedPosition!.latitude,
        _lastPushedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      newHeading = Geolocator.bearingBetween(
        _lastPushedPosition!.latitude,
        _lastPushedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      timeSinceLast = now.difference(_lastPushedTime!);

      if (distance < _noiseThreshold && timeSinceLast < _maxInterval) return;
      if (distance >= _distanceThreshold && timeSinceLast >= _minInterval) {
        shouldPush = true;
        reason = 'Distance threshold';
      } else if (_lastHeading != null) {
        final diff = (newHeading - _lastHeading!).abs();
        final normalized = diff > 180 ? 360 - diff : diff;
        if (normalized >= _headingThreshold && timeSinceLast >= _minInterval) {
          shouldPush = true;
          reason = 'Heading threshold';
        }
      }
      if (timeSinceLast >= _maxInterval) {
        shouldPush = true;
        reason = 'Heartbeat';
      }
    } else {
      shouldPush = true;
      reason = 'First push';
    }

    if (!shouldPush) return;
    try {
      await _staffService.updateDriverLocation(
        order.id,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      _lastPushedPosition = position;
      _lastPushedTime = now;
      _lastHeading = newHeading;
      debugPrint('Driver location pushed: $reason');
    } catch (_) {}
  }

  OrderStatusType _resolveStatusType(OrderModel order) {
    switch (order.statusType) {
      case 'completed':
        return OrderStatusType.done;
      case 'cancelled':
        return OrderStatusType.cancelled;
      case 'pending':
        return OrderStatusType.pending;
      default:
        return OrderStatusType.processing;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _order == null
                    ? const Center(
                        child: Text('Khong tai duoc chi tiet don hang'))
                    : RefreshIndicator(
                        onRefresh: _loadDetail,
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                          children: _buildSections(context, _order!),
                        ),
                      ),
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final order = _order;
    final statusType =
        order != null ? _resolveStatusType(order) : widget.statusType;
    final (badgeBg, badgeText) = switch (statusType) {
      OrderStatusType.pending => (
          const Color(0xFFFFF3E0),
          const Color(0xFFE65100)
        ),
      OrderStatusType.processing => (
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0)
        ),
      OrderStatusType.done => (
          const Color(0xFFE8F5E9),
          const Color(0xFF2E7D32)
        ),
      OrderStatusType.cancelled => (
          const Color(0xFFF3F4F6),
          const Color(0xFF6B7280)
        ),
    };

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_rounded,
                        size: 18, color: Color(0xFF374151)),
                    SizedBox(width: 6),
                    Text('Quay lai',
                        style:
                            TextStyle(fontSize: 14, color: Color(0xFF374151))),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chi tiet don hang',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          order?.order_code.isNotEmpty == true
                              ? order!.order_code
                              : widget.orderId,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order?.status ?? widget.statusLabel,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: badgeText),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(BuildContext context, OrderModel order) {
    final statusType = _resolveStatusType(order);
    return [
      _infoCard(
        'Thong tin khach hang',
        Icons.person_outline_rounded,
        const Color(0xFF16A34A),
        [
          _infoRow('Ho ten', order.customerName),
          _infoRow('So dien thoai', order.customerPhone),
        ],
      ),
      const SizedBox(height: 12),
      _infoCard(
        'Thong tin phuong tien',
        Icons.directions_car_outlined,
        const Color(0xFF2563EB),
        [
          _infoRow('Bien so', order.plateNumber),
          _infoRow('Loai xe', order.vehicleType),
          _infoRow('Hang xe', order.vehicleBrand),
          _infoRow('Mau sac', order.vehicleColor),
        ],
      ),
      const SizedBox(height: 12),
      _infoCard(
        'Thong tin lich hen',
        Icons.schedule_rounded,
        const Color(0xFF7C3AED),
        [
          _infoRow('Ngay hen', order.appointmentDate),
          _infoRow('Gio hen', order.appointmentTime),
          _infoRow('Dia diem', order.stationAddress, multiline: true),
        ],
      ),
      const SizedBox(height: 12),
      _buildServiceCard(order),
      const SizedBox(height: 12),
      _buildMapCard(order),
      const SizedBox(height: 12),
      InAppDocumentViewer(
        orderId: order.id,
      ),
      if ((order.note ?? '').trim().isNotEmpty) ...[
        const SizedBox(height: 12),
        _buildNoteCard(order.note!.trim()),
      ],
      const SizedBox(height: 20),
      _buildStatusActions(context, order, statusType),
    ];
  }

  Widget _infoCard(
      String title, IconData icon, Color color, List<Widget> rows) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool multiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(OrderModel order) {
    final services = order.services ?? const <OrderServiceItem>[];
    return _infoCard(
      'Dich vu',
      Icons.check_circle_outline_rounded,
      const Color(0xFF16A34A),
      [
        if (services.isEmpty)
          const Text('Chua co dich vu duoc khai bao',
              style: TextStyle(fontSize: 13))
        else
          ...services.map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                      child: Text(service.name,
                          style: const TextStyle(fontSize: 13))),
                  Text(service.price,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        const Divider(height: 20),
        Row(
          children: [
            const Text('Tong cong',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(order.totalCost ?? '0',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildMapCard(OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_rounded,
                    color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Text('Ban do tram dang kiem',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                child: _buildMapContent(
                    order.stationLat, order.stationLng, order.stationAddress),
              ),
            ),
            if (order.stationAddress.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(order.stationAddress,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent(double? lat, double? lng, String address) {
    // Mặc định: trung tâm Hà Nội nếu không có tọa độ
    const defaultCenter = LatLng(21.0285, 105.8542);
    final hasCoords = lat != null && lng != null;
    final center = hasCoords ? LatLng(lat, lng) : defaultCenter;

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: center,
        zoom: hasCoords ? 15 : 12,
      ),
      markers: hasCoords
          ? {
              Marker(
                markerId: const MarkerId('station'),
                position: center,
                infoWindow: InfoWindow(
                    title: address.isNotEmpty ? address : 'Trạm đăng kiểm'),
              ),
            }
          : {},
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }

  Widget _buildNoteCard(String note) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(note,
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFFB45309)))),
        ],
      ),
    );
  }

  Widget _buildStatusActions(
      BuildContext context, OrderModel order, OrderStatusType statusType) {
    switch (statusType) {
      case OrderStatusType.pending:
        return _actionButtons(context, order, pending: true);
      case OrderStatusType.processing:
        return _actionButtons(context, order);
      case OrderStatusType.done:
        return const Center(child: Text('Da hoan thanh'));
      case OrderStatusType.cancelled:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButtons(BuildContext context, OrderModel order,
      {bool pending = false}) {
    return Column(
      children: [
        if (pending)
          Row(
            children: [
              Expanded(
                  child:
                      _primaryButton('Goi khach', Icons.phone_rounded, () {})),
              const SizedBox(width: 12),
              Expanded(
                  child: _primaryButton('Bat dau',
                      Icons.play_circle_outline_rounded, _startTracking)),
            ],
          )
        else ...[
          _outlineButton('Huy bat dau va quay lai', _stopTracking),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _primaryButton(
                    'Nhan xe', Icons.check_circle_outline_rounded, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VehicleReceiptScreen(
                        orderId: order.id,
                        customerName: order.customerName,
                        plate: order.plateNumber,
                        vehicleType: order.vehicleType,
                        brand: order.vehicleBrand,
                        totalCost: order.totalCost ?? '0',
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _primaryButton(
                    'Tra xe', Icons.assignment_return_outlined, () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => VehicleReturnScreen(
                        orderId: order.id,
                        customerName: order.customerName,
                        plate: order.plateNumber,
                        vehicleType: order.vehicleType,
                        brand: order.vehicleBrand,
                        color: order.vehicleColor,
                        orderStatusType: order.statusType,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _primaryButton('Chup va tai anh giay to', Icons.camera_alt_outlined,
              () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DocumentUploadScreen(
                  plate: order.plateNumber,
                  customerName: order.customerName,
                ),
              ),
            );
          }, fullWidth: true),
        ],
      ],
    );
  }

  Widget _primaryButton(String label, IconData icon, VoidCallback onTap,
      {bool fullWidth = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFFDC2626), fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomTab(Icons.home_rounded, 'Trang chu', false),
          _BottomTab(Icons.receipt_long_outlined, 'Don hang', true),
          _BottomTab(Icons.person_outline_rounded, 'Ca nhan', false),
        ],
      ),
    );
  }
}

enum OrderStatusType { pending, processing, done, cancelled }

class _BottomTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _BottomTab(this.icon, this.label, this.selected);

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF16A34A) : Colors.grey.shade400;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
