import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/models/order_model.dart';
import 'package:vehicle_registration_app/screens/order_detail_screen.dart';
import 'package:vehicle_registration_app/screens/order_management_screen.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';
import 'package:vehicle_registration_app/services/staff_service.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  int _currentIndex = 0;
  final StaffService _staffService = StaffService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  int _activeCount = 0;
  int _doneCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _staffService.getRecentOrders();
      setState(() {
        _orders = response.orders;
        final activeTypes = ['pending', 'confirmed', 'en_route', 'receiving', 'inspecting', 'returning', 'waiting_payment', 'in_progress'];
        _activeCount = _orders.where((o) => activeTypes.contains(o.statusType)).length;
        _doneCount = _orders.where((o) => o.statusType == 'completed').length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải dữ liệu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F3),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  _buildHomeTab(),
                  const OrderManagementScreen(),
                  _buildProfileTab(),
                ],
              ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _buildHeaderWithOverlap(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 56, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrdersSection(),
                const SizedBox(height: 20),
                _buildQuickContactCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Cá nhân',
              style: TextStyle(fontSize: 18, color: Color(0xFF6B7280))),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () => AuthStorage.logout(context),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderWithOverlap() {
    const double cardsHeight = 240.0;
    const double cardsMargin = 16.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF16A34A),
                Color(0xFF15803D),
                Color(0xFF166534)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: CustomPaint(painter: _WavePatternPainter()),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, cardsHeight + 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Xin chào, Nhân viên!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Hệ thống quản lý kiểm định',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.5),
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: cardsMargin,
          right: cardsMargin,
          bottom: 70,
          child: _buildStatsRow(),
        ),
        Positioned(
          left: cardsMargin,
          right: cardsMargin,
          bottom: -40,
          child: _buildExplanationCard(),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            value: _activeCount.toString(),
            label: 'Đang hoạt động',
            subtitle: 'Số đơn đang chờ hoặc đang xử lý',
            iconBg: const Color(0xFFFFF0E8),
            iconColor: const Color(0xFFF97316),
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            value: _doneCount.toString(),
            label: 'Hoàn thành',
            subtitle: 'Số đơn đã hoàn thành thành công',
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF16A34A),
            icon: Icons.check_circle_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required String subtitle,
    required Color iconBg,
    required Color iconColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(child: Icon(icon, color: iconColor, size: 20)),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  color: Color(0xFF2563EB), size: 16),
              SizedBox(width: 6),
              Text(
                'Giải thích thống kê:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildExplainRow(
            '• ',
            'Đang hoạt động',
            ': Đơn chờ hoặc đang làm',
            const Color(0xFF2563EB),
          ),
          const SizedBox(height: 4),
          _buildExplainRow(
            '• ',
            'Hoàn thành',
            ': Đơn đã làm xong thành công',
            const Color(0xFF16A34A),
          ),
        ],
      ),
    );
  }

  Widget _buildExplainRow(
      String bullet, String bold, String rest, Color boldColor) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
            fontSize: 12.5, color: Color(0xFF374151), height: 1.5),
        children: [
          TextSpan(text: bullet),
          TextSpan(
            text: bold,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: boldColor),
          ),
          TextSpan(text: rest),
        ],
      ),
    );
  }

  Widget _buildOrdersSection() {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ));
    }

    final recentOrders = _orders.take(5).toList();

    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Đơn hàng gần đây',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: Row(
                children: const [
                  Text(
                    'Xem tất cả',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded,
                      color: Color(0xFF16A34A), size: 14),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: recentOrders.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('Không có đơn hàng nào'),
                )
              : Column(
                  children: List.generate(recentOrders.length, (i) {
                    final order = recentOrders[i];
                    final isLast = i == recentOrders.length - 1;
                    return Column(
                      children: [
                        _buildOrderRow(order),
                        if (!isLast)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Divider(
                                height: 1, color: Colors.grey.shade100),
                          ),
                      ],
                    );
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildOrderRow(OrderModel order) {
    return GestureDetector(
      onTap: () {
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
        ).then((_) => _loadData());
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFEFFEF2),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Icon(Icons.work_outline_rounded,
                    color: Color(0xFF16A34A), size: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.order_code,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order.customerName,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'BKS: ${order.plateNumber}',
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatusBadge(order.status, order.statusType),
                const SizedBox(height: 6),
                Text(
                  order.appointmentTime,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, String type) {
    Color bg;
    Color text;
    switch (type) {
      case 'pending':
      case 'confirmed':
        bg = const Color(0xFFFFF3E0);
        text = const Color(0xFFE65100);
        break;
      case 'en_route':
      case 'receiving':
      case 'inspecting':
      case 'returning':
      case 'waiting_payment':
      case 'in_progress':
        bg = const Color(0xFFE3F2FD);
        text = const Color(0xFF1565C0);
        break;
      case 'completed':
        bg = const Color(0xFFE8F5E9);
        text = const Color(0xFF2E7D32);
        break;
      default:
        bg = const Color(0xFFF3F4F6);
        text = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11.5, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }

  Widget _buildQuickContactCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.phone_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Liên hệ nhanh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Gọi cho khách hàng để xác nhận lịch hẹn',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Gọi ngay',
                style: TextStyle(
                  color: Color(0xFF16A34A),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final tabs = [
      _NavTab(icon: Icons.home_rounded, label: 'Trang chủ'),
      _NavTab(icon: Icons.receipt_long_outlined, label: 'Đơn hàng'),
      _NavTab(icon: Icons.person_outline_rounded, label: 'Cá nhân'),
    ];

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
            children: List.generate(tabs.length, (i) {
              final selected = _currentIndex == i;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selected ? 32 : 0,
                        height: 3,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Icon(
                        tabs[i].icon,
                        size: 24,
                        color: selected
                            ? const Color(0xFF16A34A)
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        tabs[i].label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: selected
                              ? const Color(0xFF16A34A)
                              : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  _NavTab({required this.icon, required this.label});
}

class _WavePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.2), 80, paint);
    canvas.drawCircle(
        Offset(size.width * 1.1, size.height * 0.9), 100, paint);
    canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.8), 60, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
