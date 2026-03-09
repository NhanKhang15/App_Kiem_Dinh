import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/screens/document_upload_screen.dart';
import 'package:vehicle_registration_app/screens/vehicle_receipt_screen.dart';
import 'package:vehicle_registration_app/screens/vehicle_return_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final String customerName;
  final String statusLabel;
  final OrderStatusType statusType;

  const OrderDetailScreen({
    super.key,
    this.orderId = 'DK001',
    this.customerName = 'Trần Minh Tuấn',
    this.statusLabel = 'Chờ xử lý',
    this.statusType = OrderStatusType.pending,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildFixedHeader(context),
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  _buildCustomerCard(),
                  const SizedBox(height: 12),
                  _buildVehicleCard(),
                  const SizedBox(height: 12),
                  _buildAppointmentCard(),
                  const SizedBox(height: 12),
                  _buildServiceCard(),
                  const SizedBox(height: 12),
                  if (statusType == OrderStatusType.pending)
                    _buildNoteCard(),
                  if (statusType == OrderStatusType.pending)
                    const SizedBox(height: 20),
                  _buildStatusActions(context),
                ],
              ),
            ),
          ),
          _buildBottomNavBar(context),
        ],
      ),
    );
  }

  Widget _buildFixedHeader(BuildContext context) {
    Color badgeBg;
    Color badgeText;
    switch (statusType) {
      case OrderStatusType.pending:
        badgeBg = const Color(0xFFFFF3E0);
        badgeText = const Color(0xFFE65100);
        break;
      case OrderStatusType.processing:
        badgeBg = const Color(0xFFE3F2FD);
        badgeText = const Color(0xFF1565C0);
        break;
      case OrderStatusType.done:
        badgeBg = const Color(0xFFE8F5E9);
        badgeText = const Color(0xFF2E7D32);
        break;
      case OrderStatusType.cancelled:
        badgeBg = const Color(0xFFF3F4F6);
        badgeText = const Color(0xFF6B7280);
        break;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_rounded,
                            size: 18, color: Color(0xFF374151)),
                        SizedBox(width: 6),
                        Text(
                          'Quay lại',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF374151),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Chi tiết đơn hàng',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              orderId,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: badgeText,
                          ),
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

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<Widget> rows,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 14),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool valueBold = false, bool wrap = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment:
        wrap ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                valueBold ? FontWeight.bold : FontWeight.w500,
                color: valueColor ?? const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return _buildSectionCard(
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF16A34A),
      title: 'Thông tin khách hàng',
      rows: [
        _buildInfoRow('Họ tên:', customerName, valueBold: true),
        _buildInfoRow('Số điện thoại:', '0123456789',
            valueColor: const Color(0xFF16A34A), valueBold: true),
      ],
    );
  }

  Widget _buildVehicleCard() {
    return _buildSectionCard(
      icon: Icons.directions_car_outlined,
      iconColor: const Color(0xFF2563EB),
      title: 'Thông tin phương tiện',
      rows: [
        _buildInfoRow('Biển kiểm soát:', '30A-123.45', valueBold: true),
        _buildInfoRow('Loại xe:', 'Ô tô con'),
        _buildInfoRow('Hãng xe:', 'Toyota Vios', valueBold: true),
        _buildInfoRow('Màu sắc:', 'Trắng'),
      ],
    );
  }

  Widget _buildAppointmentCard() {
    return _buildSectionCard(
      icon: Icons.schedule_rounded,
      iconColor: const Color(0xFF7C3AED),
      title: 'Thông tin lịch hẹn',
      rows: [
        _buildInfoRow('Ngày hẹn:', '29/01/2026', valueBold: true),
        _buildInfoRow('Giờ hẹn:', '08:30', valueBold: true),
        _buildInfoRow(
          'Địa điểm:',
          'Trạm Cầu Giấy - 123 Phố Huế, Hai Bà Trưng, Hà Nội',
          valueBold: true,
          wrap: true,
        ),
      ],
    );
  }

  Widget _buildServiceCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x07000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.check_circle_outline_rounded,
                    color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 8),
                Text(
                  'Dịch vụ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 14),
            _buildServiceRow('Kiểm tra an toàn kỹ thuật', '340.000đ'),
            const SizedBox(height: 10),
            _buildServiceRow('Kiểm tra khí thải', '120.000đ'),
            const SizedBox(height: 14),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            const SizedBox(height: 12),
            Row(
              children: const [
                Text(
                  'Tổng cộng:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Spacer(),
                Text(
                  '460.000đ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceRow(String name, String price) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ),
        Text(
          price,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildNoteCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline_rounded,
              color: Color(0xFFF59E0B), size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ghi chú',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB45309),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Khách hàng yêu cầu kiểm tra kỹ hệ thống phanh',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFB45309),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(BuildContext context) {
    switch (statusType) {
      case OrderStatusType.pending:
        return _buildPendingActions(context);
      case OrderStatusType.processing:
        return _buildProcessingActions(context);
      case OrderStatusType.done:
        return _buildDoneState();
      case OrderStatusType.cancelled:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPendingActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _btnPrimary(
              icon: Icons.phone_rounded,
              label: 'Gọi khách',
              colors: [const Color(0xFF16A34A), const Color(0xFF15803D)],
              shadowColor: const Color(0xFF16A34A),
              onTap: () {},
            )),
            const SizedBox(width: 12),
            Expanded(child: _btnPrimary(
              icon: Icons.play_circle_outline_rounded,
              label: 'Bắt đầu',
              colors: [const Color(0xFF3B5BF5), const Color(0xFF2563EB)],
              shadowColor: const Color(0xFF2563EB),
              onTap: () {},
            )),
          ],
        ),
        const SizedBox(height: 12),
        _buildSecondaryButtons(),
      ],
    );
  }

  Widget _buildProcessingActions(BuildContext context) {
    return Column(
      children: [
        _btnOutline(
          icon: Icons.cancel_outlined,
          label: 'Hủy bắt đầu & Quay lại',
          textColor: const Color(0xFFDC2626),
          borderColor: const Color(0xFFFECACA),
          bgColor: const Color(0xFFFFF5F5),
          onTap: () {},
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _btnPrimary(
              icon: Icons.check_circle_outline_rounded,
              label: 'Nhận xe',
              colors: [const Color(0xFF16A34A), const Color(0xFF15803D)],
              shadowColor: const Color(0xFF16A34A),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VehicleReceiptScreen(
                      orderId: orderId,
                      customerName: customerName,
                      plate: '29B-678.90',
                      vehicleType: 'Ô tô con',
                      brand: 'Honda City',
                      totalCost: '340.000đ',
                    ),
                  ),
                );
              },
            )),
            const SizedBox(width: 12),
            Expanded(child: _btnPrimary(
              icon: Icons.check_circle_outline_rounded,
              label: 'Trả xe',
              colors: [const Color(0xFF7C3AED), const Color(0xFF6D28D9)],
              shadowColor: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => VehicleReturnScreen(
                      orderId: orderId,
                      customerName: customerName,
                      plate: '29B-678.90',
                      vehicleType: 'Ô tô con',
                      brand: 'Honda City',
                      color: 'Đỏ',
                    ),
                  ),
                );
              },
            )),
          ],
        ),
        const SizedBox(height: 10),
        _btnPrimary(
          icon: Icons.camera_alt_outlined,
          label: 'Chụp/Tải ảnh giấy tờ',
          colors: [const Color(0xFF3B5BF5), const Color(0xFF2563EB)],
          shadowColor: const Color(0xFF2563EB),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DocumentUploadScreen(
                  plate: '29B-678.90',
                  customerName: customerName,
                ),
              ),
            );
          },
          fullWidth: true,
        ),
        const SizedBox(height: 10),
        _btnPrimary(
          icon: Icons.verified_outlined,
          label: 'Hoàn thành kiểm định',
          colors: [const Color(0xFF16A34A), const Color(0xFF15803D)],
          shadowColor: const Color(0xFF16A34A),
          onTap: () {},
          fullWidth: true,
        ),
        const SizedBox(height: 12),
        _buildSecondaryButtons(),
      ],
    );
  }

  Widget _buildDoneState() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFFEFFEF2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            children: const [
              Icon(Icons.check_circle_rounded,
                  color: Color(0xFF16A34A), size: 48),
              SizedBox(height: 10),
              Text(
                'Đã hoàn thành',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF15803D),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Đơn hàng đã được xử lý thành công',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSecondaryButtons(),
      ],
    );
  }

  Widget _btnPrimary({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required Color shadowColor,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
    return btn;
  }

  Widget _btnOutline({
    required IconData icon,
    required String label,
    required Color textColor,
    required Color borderColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButtons() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF374151), size: 17),
                  SizedBox(width: 7),
                  Text(
                    'Chat',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.navigation_outlined,
                      color: Color(0xFF374151), size: 17),
                  SizedBox(width: 7),
                  Text(
                    'Chỉ đường',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
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
              final selected = i == 1;
              return Expanded(
                child: GestureDetector(
                  onTap: () {},
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

enum OrderStatusType { pending, processing, done, cancelled }

class _NavTab {
  final IconData icon;
  final String label;
  _NavTab({required this.icon, required this.label});
}

class _CircleDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(
        Offset(size.width - 32, size.height * 0.3), 48, paint);
    canvas.drawCircle(
        Offset(size.width - 96, size.height * 0.25), 32, paint);
    canvas.drawCircle(Offset(24, size.height * 0.85), 56, paint);
    canvas.drawCircle(Offset(112, size.height * 0.9), 20, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}