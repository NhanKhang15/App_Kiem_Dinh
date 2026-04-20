import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/models/order_model.dart';
import 'package:vehicle_registration_app/screens/order_detail_screen.dart';
import 'package:vehicle_registration_app/services/staff_service.dart';

enum OrderFilter { all, pending, processing, done }

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  OrderFilter _activeFilter = OrderFilter.all;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  
  final StaffService _staffService = StaffService();
  List<OrderModel> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    try {
      final response = await _staffService.getRecentOrders();
      setState(() {
        _allOrders = response.orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách: $e')),
        );
      }
    }
  }

  List<OrderModel> get _filtered {
    var list = _allOrders;
    if (_activeFilter != OrderFilter.all) {
      final filterMap = {
        OrderFilter.pending: ['pending', 'confirmed'],
        OrderFilter.processing: ['en_route', 'receiving', 'inspecting', 'returning', 'waiting_payment', 'in_progress'],
        OrderFilter.done: ['completed'],
      };
      list = list.where((o) => filterMap[_activeFilter]?.contains(o.statusType) ?? false).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((o) =>
      o.order_code.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.plateNumber.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  int _count(List<String> types) =>
      _allOrders.where((o) => types.contains(o.statusType)).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilterTabs(),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _fetchOrders,
                child: _filtered.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) => _buildOrderCard(ctx, _filtered[i]),
                    ),
              ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: CustomPaint(painter: _CircleDecorPainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quản lý đơn hàng',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_allOrders.length} đơn hàng',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        decoration: InputDecoration(
          hintText: 'Tìm mã đơn, khách hàng, BKS...',
          hintStyle:
          const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF9CA3AF), size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
            onTap: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            child: const Icon(Icons.close_rounded,
                color: Color(0xFF9CA3AF), size: 16),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = [
      _FilterTab(OrderFilter.all, 'Tất cả', _allOrders.length),
      _FilterTab(OrderFilter.pending, 'Chờ xử lý', _count(['pending', 'confirmed'])),
      _FilterTab(OrderFilter.processing, 'Đang xử lý', _count(['en_route', 'receiving', 'inspecting', 'returning', 'waiting_payment', 'in_progress'])),
      _FilterTab(OrderFilter.done, 'Hoàn thành', _count(['completed'])),
    ];

    return Container(
      color: const Color(0xFFF3F4F6),
      child: Column(
        children: [
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: filters.map((f) {
                final active = _activeFilter == f.filter;
                return GestureDetector(
                  onTap: () => setState(() => _activeFilter = f.filter),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            '${f.label} (${f.count})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: active
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: active
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 2.5,
                          width: active ? 60 : 0,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text('Không có đơn hàng',
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    Color badgeBg, badgeText, badgeBorder;
    IconData badgeIcon;
    switch (order.statusType) {
      case 'pending':
      case 'confirmed':
        badgeBg = const Color(0xFFFFF7ED);
        badgeText = const Color(0xFFC2410C);
        badgeBorder = const Color(0xFFFED7AA);
        badgeIcon = Icons.access_time_rounded;
        break;
      case 'en_route':
      case 'receiving':
      case 'inspecting':
      case 'returning':
      case 'waiting_payment':
      case 'in_progress':
        badgeBg = const Color(0xFFEFF6FF);
        badgeText = const Color(0xFF1D4ED8);
        badgeBorder = const Color(0xFFBFDBFE);
        badgeIcon = Icons.sync_rounded;
        break;
      case 'completed':
        badgeBg = const Color(0xFFEFFEF2);
        badgeText = const Color(0xFF15803D);
        badgeBorder = const Color(0xFFBBF7D0);
        badgeIcon = Icons.check_circle_outline_rounded;
        break;
      default:
        badgeBg = const Color(0xFFF3F4F6);
        badgeText = const Color(0xFF6B7280);
        badgeBorder = const Color(0xFFE5E7EB);
        badgeIcon = Icons.help_outline;
    }

    void goToDetail() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(
            orderId: order.id,
            customerName: order.customerName,
            statusLabel: order.status,
            statusType: ['pending', 'confirmed'].contains(order.statusType)
                ? OrderStatusType.pending
                : ['en_route', 'receiving', 'inspecting', 'returning', 'waiting_payment', 'in_progress'].contains(order.statusType)
                ? OrderStatusType.processing
                : order.statusType == 'completed'
                ? OrderStatusType.done
                : OrderStatusType.cancelled,
          ),
        ),
      ).then((_) => _fetchOrders());
    }

    return GestureDetector(
      onTap: goToDetail,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 3)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    order.order_code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: badgeBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, color: badgeText, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          order.status,
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: badgeText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.customerName,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.directions_car_outlined,
                const Color(0xFF3B5BF5),
                const Color(0xFFEFF6FF),
                '${order.plateNumber}  ·  ${order.vehicleType}',
                bold: true,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.access_time_rounded,
                const Color(0xFF7C3AED),
                const Color(0xFFF5F3FF),
                '${order.appointmentTime} - ${order.appointmentDate}',
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                Icons.location_on_outlined,
                const Color(0xFFEA580C),
                const Color(0xFFFFF7ED),
                order.stationAddress,
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFFEF2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.phone_rounded,
                                color: Color(0xFF16A34A), size: 15),
                            SizedBox(width: 6),
                            Text(
                              'Gọi ngay',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: goToDetail,
                      child: Container(
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Center(
                          child: Text(
                            'Xem chi tiết',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildInfoRow(
      IconData icon, Color iconColor, Color iconBg, String text,
      {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Icon(icon, color: iconColor, size: 14)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                bold ? FontWeight.w600 : FontWeight.normal,
                color: const Color(0xFF374151),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterTab {
  final OrderFilter filter;
  final String label;
  final int count;
  _FilterTab(this.filter, this.label, this.count);
}

class _CircleDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(Offset(size.width - 20, size.height * 0.5), 44, paint);
    canvas.drawCircle(Offset(size.width - 60, size.height * 0.3), 28, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
