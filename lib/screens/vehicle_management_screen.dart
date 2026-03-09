import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/models/vehicle_model.dart';
import 'package:vehicle_registration_app/services/vehicle_service.dart';
import 'package:vehicle_registration_app/screens/vehicle_detail_sheet.dart';
import 'package:vehicle_registration_app/screens/add_vehicle_screen.dart';
import 'package:vehicle_registration_app/screens/edit_vehicle_screen.dart';
import 'package:vehicle_registration_app/widgets/app_header_with_back.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({super.key});

  @override
  State<VehicleManagementScreen> createState() => _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  final VehicleService _vehicleService = VehicleService();
  List<VehicleModel> _vehicles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = res.results;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().contains('SocketException')
            ? 'Không thể kết nối server.'
            : 'Tải danh sách xe thất bại.';
        _loading = false;
      });
    }
  }

  Future<void> _showDetail(VehicleModel vehicle) async {
    final result = await VehicleDetailSheet.show(context, vehicle);
    if (!mounted) return;
    if (result != null && result['action'] == 'edit' && result['id'] != null) {
      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => EditVehicleScreen(vehicleId: result['id'] as int),
        ),
      );
      if (mounted) _loadVehicles();
    }
  }

  Future<void> _openEdit(VehicleModel vehicle) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditVehicleScreen(vehicleId: vehicle.id),
      ),
    );
    if (updated == true && mounted) _loadVehicles();
  }

  Future<void> _confirmDelete(VehicleModel vehicle) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa xe'),
        content: Text(
          'Bạn có chắc muốn xóa xe ${vehicle.licensePlate}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _vehicleService.deleteVehicle(vehicle.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa xe.'), backgroundColor: Color(0xFF16A34A)),
      );
      _loadVehicles();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('SocketException') ? 'Không thể kết nối.' : 'Xóa xe thất bại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeaderWithBack(
              title: 'Quản lý xe',
              subtitle: 'Thêm và chỉnh sửa thông tin xe',
            ),
            // Add vehicle button
            SizedBox(height: 16,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Material(
                color: const Color(0xFF1D4ED8),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () async {
                    final added = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddVehicleScreen(),
                      ),
                    );
                    if (added == true && mounted) _loadVehicles();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: Colors.white, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Thêm xe mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3B5BF5)))
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: _loadVehicles,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        )
                      : _vehicles.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.directions_car_outlined,
                                      size: 56,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Chưa có xe nào',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Bấm "Thêm xe mới" ở trên để thêm xe',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _vehicles.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final v = _vehicles[index];
                                return _VehicleListCard(
                                  vehicle: v,
                                  onTap: () => _showDetail(v),
                                  onEdit: () => _openEdit(v),
                                  onDelete: () => _confirmDelete(v),
                                );
                              },
                            ),
            ),
            // Bottom nav (giống Home)
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _navItem(Icons.home_rounded, 'Trang chủ', true, () => Navigator.of(context).pop()),
              _navItem(Icons.calendar_today_rounded, 'Đặt lịch', false, () {}),
              _navItem(Icons.map_outlined, 'Bản đồ', false, () {}),
              _navItem(Icons.person_outline_rounded, 'Cá nhân', false, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: selected ? const Color(0xFF3B5BF5) : Colors.grey.shade400,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? const Color(0xFF3B5BF5) : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleListCard extends StatelessWidget {
  const _VehicleListCard({
    required this.vehicle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final VehicleModel vehicle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const Color _blueBg = Color(0xFFDBEAFE);
  static const Color _greenBg = Color(0xFFD1FAE5);

  static Color _iconBgColor(VehicleModel v) {
    final name = v.vehicleTypeName.toLowerCase();
    if (name.contains('xe máy') || name.contains('xe may')) return _greenBg;
    return _blueBg;
  }

  static IconData _vehicleIcon(VehicleModel v) {
    final name = v.vehicleTypeName.toLowerCase();
    if (name.contains('xe máy') || name.contains('xe may')) return Icons.two_wheeler_outlined;
    return Icons.directions_car_outlined;
  }

  static Color _iconColor(VehicleModel v) {
    final name = v.vehicleTypeName.toLowerCase();
    if (name.contains('xe máy') || name.contains('xe may')) return const Color(0xFF16A34A);
    return const Color(0xFF3B5BF5);
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _iconBgColor(vehicle);
    final iconColor = _iconColor(vehicle);
    final nextDate = vehicle.nextInspectionDate ?? '—';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_vehicleIcon(vehicle), color: iconColor, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.licensePlate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.vehicleTypeName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Color(0xFF3B5BF5), size: 22),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 22),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailRow('Hãng xe:', vehicle.brandModel),
            _detailRow('Màu sắc:', vehicle.color),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Hạn đăng kiểm:',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Color(0xFF3B5BF5)),
                      const SizedBox(width: 4),
                      Text(
                        nextDate,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}
