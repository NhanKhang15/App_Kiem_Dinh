import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/widgets/app_header_with_back.dart';

/// Trạng thái đơn hàng (dùng cho filter và badge).
enum OrderStatus {
  pending,   // Chờ xác nhận
  confirmed, // Đã xác nhận
  enRoute,   // Đang đến
  receiving, // Đang nhận xe
  inspecting,// Đang đăng kiểm
  returning, // Đang trả xe
  waitingPayment, // Đang chờ thanh toán
  completed, // Hoàn thành
  cancelled, // Đã hủy
}

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending: return 'Chờ xác nhận';
      case OrderStatus.confirmed: return 'Đã xác nhận';
      case OrderStatus.enRoute: return 'Đang đến';
      case OrderStatus.receiving: return 'Đang nhận xe';
      case OrderStatus.inspecting: return 'Đang đăng kiểm';
      case OrderStatus.returning: return 'Đang trả xe';
      case OrderStatus.waitingPayment: return 'Đang chờ thanh toán';
      case OrderStatus.completed: return 'Hoàn thành';
      case OrderStatus.cancelled: return 'Đã hủy';
    }
  }
  IconData get icon {
    switch (this) {
      case OrderStatus.pending: return Icons.schedule_rounded;
      case OrderStatus.confirmed: return Icons.check_circle_outline_rounded;
      case OrderStatus.enRoute: return Icons.directions_car_rounded;
      case OrderStatus.receiving: return Icons.directions_car_rounded;
      case OrderStatus.inspecting: return Icons.build_rounded;
      case OrderStatus.returning: return Icons.directions_car_rounded;
      case OrderStatus.waitingPayment: return Icons.lock_rounded;
      case OrderStatus.completed: return Icons.check_circle_rounded;
      case OrderStatus.cancelled: return Icons.cancel_outlined;
    }
  }
  Color get badgeColor {
    switch (this) {
      case OrderStatus.pending: return const Color(0xFFEA580C);
      case OrderStatus.confirmed: return const Color(0xFF3B5BF5);
      case OrderStatus.enRoute: return const Color(0xFF7C3AED);
      case OrderStatus.receiving: return const Color(0xFF7C3AED);
      case OrderStatus.inspecting: return const Color(0xFF3B5BF5);
      case OrderStatus.returning: return Colors.grey;
      case OrderStatus.waitingPayment: return const Color(0xFFDB2777);
      case OrderStatus.completed: return const Color(0xFF16A34A);
      case OrderStatus.cancelled: return const Color(0xFFDC2626);
    }
  }
}

/// Một đơn hàng (mock).
class OrderItem {
  const OrderItem({
    required this.id,
    required this.licensePlate,
    required this.stationName,
    required this.status,
    required this.date,
    required this.time,
    required this.price,
  });
  final String id;
  final String licensePlate;
  final String stationName;
  final OrderStatus status;
  final String date;
  final String time;
  final String price;
}

/// Màn "Đơn hàng": header, search, tab lọc, danh sách đơn.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  static const List<OrderItem> _allOrders = [
    OrderItem(id: '1', licensePlate: '51F-12345', stationName: 'TT Đăng kiểm 29-03D', status: OrderStatus.pending, date: '15/02/2026', time: '09:00', price: '350.000₫'),
    OrderItem(id: '2', licensePlate: '29A-98765', stationName: 'TT Đăng kiểm 5001D', status: OrderStatus.confirmed, date: '07/02/2026', time: '14:00', price: '561.000₫'),
    OrderItem(id: '3', licensePlate: '30H-22222', stationName: 'TT Đăng kiểm Hoàn Kiếm', status: OrderStatus.confirmed, date: '07/02/2026', time: '16:30', price: '420.000₫'),
    OrderItem(id: '4', licensePlate: '30B-11111', stationName: 'TT Đăng kiểm Thanh Xuân', status: OrderStatus.enRoute, date: '06/02/2026', time: '15:30', price: '420.000₫'),
    OrderItem(id: '5', licensePlate: '51G-77777', stationName: 'TT Đăng kiểm Hà Đông', status: OrderStatus.completed, date: '06/02/2026', time: '10:30', price: '561.000₫'),
    OrderItem(id: '6', licensePlate: '51F-22222', stationName: 'TT Đăng kiểm Cầu Giấy', status: OrderStatus.enRoute, date: '06/02/2026', time: '10:00', price: '561.000₫'),
    OrderItem(id: '7', licensePlate: '29A-12345', stationName: 'TT Đăng kiểm 29-03D', status: OrderStatus.receiving, date: '06/02/2026', time: '11:30', price: '350.000₫'),
    OrderItem(id: '8', licensePlate: '51G-88888', stationName: 'TT Đăng kiểm 5001D', status: OrderStatus.inspecting, date: '02/02/2026', time: '08:45', price: '561.000₫'),
    OrderItem(id: '9', licensePlate: '51F-12345', stationName: 'TT Đăng kiểm Thanh Xuân', status: OrderStatus.returning, date: '25/01/2026', time: '09:30', price: '561.000₫'),
    OrderItem(id: '10', licensePlate: '30A-67890', stationName: 'TT Đăng kiểm Thanh Xuân', status: OrderStatus.completed, date: '05/02/2026', time: '14:30', price: '380.000₫'),
    OrderItem(id: '11', licensePlate: '51F-12345', stationName: 'TT Đăng kiểm Cầu Giấy', status: OrderStatus.cancelled, date: '03/02/2026', time: '10:30', price: '561.000₫'),
  ];

  /// 0 = Tất cả, 1..9 = OrderStatus theo thứ tự enum.
  int _selectedTabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderItem> get _filteredOrders {
    var list = _allOrders;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((o) =>
        o.id.toLowerCase().contains(query) ||
        o.licensePlate.toLowerCase().contains(query) ||
        o.stationName.toLowerCase().contains(query)).toList();
    }
    if (_selectedTabIndex == 0) return list;
    final status = OrderStatus.values[_selectedTabIndex - 1];
    return list.where((o) => o.status == status).toList();
  }

  int _countForTab(int index) {
    if (index == 0) return _allOrders.length;
    return _allOrders.where((o) => o.status == OrderStatus.values[index - 1]).length;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeaderWithBack(
              title: 'Đơn hàng',
              subtitle: '${_allOrders.length} đơn hàng',
              bottom: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Tìm mã đơn, biển số xe...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600, size: 22),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildTabs(),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildOrderCard(filtered[i]),
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    final tabCount = 1 + OrderStatus.values.length; // Tất cả + 9 trạng thái
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: tabCount,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          if (index == 0) {
            return _tabChip(
              'Tất cả',
              _countForTab(0),
              Icons.description_outlined,
              0,
            );
          }
          final status = OrderStatus.values[index - 1];
          return _tabChip(
            status.label,
            _countForTab(index),
            status.icon,
            index,
          );
        },
      ),
    );
  }

  Widget _tabChip(String label, int count, IconData icon, int index) {
    final selected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B5BF5) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              '$label $count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderItem order) {
    final status = order.status;
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_car_outlined, size: 18, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          order.licensePlate,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            order.stationName,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: status.badgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(status.icon, size: 14, color: status.badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: status.badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(order.date, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              const SizedBox(width: 14),
              Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(order.time, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              const Spacer(),
              Text(
                order.price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B5BF5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openOrderDetail(order),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18, color: Color(0xFF3B5BF5)),
                  label: const Text('Chi tiết', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF3B5BF5))),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF3B5BF5),
                    side: const BorderSide(color: Color(0xFF3B5BF5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (order.status == OrderStatus.completed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.receipt_long_rounded, size: 18, color: Colors.white),
                    label: const Text('Hóa đơn', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _openOrderDetail(OrderItem order) {
    Navigator.pushNamed(context, '/orderTracking', arguments: {
      'orderId': order.licensePlate,
      'stationName': order.stationName,
      'stationAddress': order.stationName,
      'appointmentDate': order.date,
      'appointmentTime': order.time,
      'completedSteps': _completedStepsFromStatus(order.status),
    });
  }

  int _completedStepsFromStatus(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending: return 0;
      case OrderStatus.confirmed: return 1;
      case OrderStatus.enRoute: return 2;
      case OrderStatus.receiving: return 3;
      case OrderStatus.inspecting: return 4;
      case OrderStatus.returning: return 5;
      case OrderStatus.waitingPayment: return 5;
      case OrderStatus.completed: return 7;
      case OrderStatus.cancelled: return 0;
    }
  }

  Widget _buildBottomNav(BuildContext context) {
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
              _navItem(context, Icons.home_rounded, 'Trang chủ', () => Navigator.popUntil(context, (r) => r.isFirst)),
              _navItem(context, Icons.calendar_today_rounded, 'Đặt lịch', () {}),
              _navItem(context, Icons.map_outlined, 'Bản đồ', () {}),
              _navItem(context, Icons.person_outline_rounded, 'Cá nhân', () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Colors.grey.shade400),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
