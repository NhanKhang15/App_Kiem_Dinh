import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/screens/booking_dashboard_screen.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVipBanner(),
                          const SizedBox(height: 12),
                          _buildSearchCard(
                            iconBgColor: const Color(0xFFFFEEEE),
                            iconColor: const Color(0xFFDC2626),
                            title: 'Tra Cứu Cục CSGT',
                            subtitle: 'Toàn quốc, dữ liệu Cục CSGT',
                          ),
                          const SizedBox(height: 10),
                          _buildSearchCard(
                            iconBgColor: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            title: 'Tra Cứu Cục Đăng Kiểm',
                            subtitle: 'Dữ liệu từ Cục Đăng kiểm VN',
                          ),
                          const SizedBox(height: 10),
                          _buildSearchCard(
                            iconBgColor: const Color(0xFFEFFEF2),
                            iconColor: const Color(0xFF16A34A),
                            title: 'Tra Cứu CSGT Thành Phố',
                            subtitle: 'Hà Nội, TP.HCM, Đà Nẵng',
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Tiện ích',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildUtilityGrid(),
                          const SizedBox(height: 24),
                          _buildBottomActions(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomNavBar(),
          ],
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Đăng Kiểm Việt',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tra cứu & tiện ích xe cộ',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F6FA),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(Icons.person_outline,
                color: Color(0xFF6B7280), size: 22),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF6B7280), size: 22),
            onPressed: () => AuthStorage.logout(context),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
    );
  }

  // ── VIP Banner ────────────────────────────────────────────────
  Widget _buildVipBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 5),
                decoration: const BoxDecoration(
                  color: Color(0xFF78350F),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dữ liệu lấy trực tiếp từ máy chủ chính thức tại thời điểm tra cứu',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF78350F), height: 1.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Nâng Cấp VIP',
                  style: TextStyle(
                    color: Color(0xFFB45309),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Cards ──────────────────────────────────────────────
  Widget _buildSearchCard({
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: _ShieldCheckIcon(color: iconColor, size: 20),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E),
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Utility Grid ──────────────────────────────────────────────
  Widget _buildUtilityGrid() {
    final items = [
      _UtilityItem(
        icon: Icons.directions_car_outlined,
        label: 'Đặt Lịch Đăng Kiểm',
        bgColor: const Color(0xFF16A34A),
        iconColor: Colors.white,
        isHighlighted: true,
        onTap:() {
          Navigator.pushReplacementNamed(context, '/bookingDashBoard');
        },
      ),
      _UtilityItem(
        icon: Icons.group_outlined,
        label: 'Nhóm Cộng Đồng',
        bgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _UtilityItem(
          icon: Icons.article_outlined,
          label: 'Tin Tức Xe Cộ',
          bgColor: const Color(0xFFEFF6FF),
          iconColor: Colors.black
      ),
      _UtilityItem(
        icon: Icons.help_outline,
        label: 'Giải Đáp Thắc Mắc',
        bgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _UtilityItem(
        icon: Icons.map_outlined,
        label: 'Chỉ Dẫn Đường',
        bgColor: const Color(0xFFEFF6FF),
        iconColor:  Colors.black,
      ),
      _UtilityItem(
        icon: Icons.local_taxi_outlined,
        label: 'Dịch Vụ Lái Xe',
        bgColor: const Color(0xFFEFF6FF),
        iconColor: const Color(0xFF2563EB),
      ),
      _UtilityItem(
        icon: Icons.camera_alt_outlined,
        label: 'Camera\nGiao Thông',
        bgColor: const Color(0xFFF0F9FF),
        iconColor:  Colors.black,
      ),
    ];

    // Build rows manually for tighter control
    return Column(
      children: [
        // Row 1: 3 items
        Row(
          children: [
            for (int i = 0; i < 3; i++) ...[
              Expanded(child: _buildUtilityItem(items[i])),
              if (i < 2) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: 3 items
        Row(
          children: [
            for (int i = 3; i < 6; i++) ...[
              Expanded(child: _buildUtilityItem(items[i])),
              if (i < 5) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 12),
        // Row 3: 1 item left-aligned
        Row(
          children: [
            SizedBox(
              width: (MediaQuery.of(context).size.width - 32 - 16) / 3,
              child: _buildUtilityItem(items[6]),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }

  Widget _buildUtilityItem(_UtilityItem item) {
    return GestureDetector(
      onTap: item.onTap ?? () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: item.isHighlighted
                  ? [
                BoxShadow(
                  color: const Color(0xFF16A34A).withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
              border: item.isHighlighted
                  ? Border.all(
                color: const Color(0xFF22C55E).withOpacity(0.7),
                width: 2,
              )
                  : null,
            ),
            child: Center(
              child: Icon(item.icon, color: item.iconColor, size: 26),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight:
              item.isHighlighted ? FontWeight.w700 : FontWeight.w500,
              color: item.isHighlighted
                  ? const Color(0xFF16A34A)
                  : const Color(0xFF374151),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Actions ────────────────────────────────────────────
  Widget _buildBottomActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline,
                            color: Colors.grey.shade500, size: 18),
                        const SizedBox(width: 6),
                        Text('Đánh giá ứng dụng',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
                Container(
                    width: 1, height: 20, color: const Color(0xFFE5E7EB)),
                Expanded(
                  child: GestureDetector(
                    onTap: () {},
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_outlined,
                            color: Colors.grey.shade500, size: 18),
                        const SizedBox(width: 6),
                        Text('Chia sẻ ứng dụng',
                            style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          GestureDetector(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Chính sách & điều khoản',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Nav Bar ────────────────────────────────────────────
  Widget _buildBottomNavBar() {
    final tabs = [
      _NavTab(icon: Icons.search_rounded, label: 'Tra Cứu'),
      _NavTab(icon: Icons.camera_alt_outlined, label: 'Danh Sách Cam'),
      _NavTab(icon: Icons.description_outlined, label: 'Mức Phạt'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
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
                      Icon(tabs[i].icon,
                          size: 24,
                          color: selected
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade400),
                      const SizedBox(height: 3),
                      Text(tabs[i].label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected
                                ? const Color(0xFF2563EB)
                                : Colors.grey.shade400,
                          )),
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

// ── Data models ──────────────────────────────────────────────────
class _UtilityItem {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final bool isHighlighted;
  final VoidCallback? onTap;

  _UtilityItem({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    this.isHighlighted = false,
    this.onTap,
  });
}

class _NavTab {
  final IconData icon;
  final String label;
  _NavTab({required this.icon, required this.label});
}

// ── Custom Shield Check Icon ──────────────────────────────────────
class _ShieldCheckIcon extends StatelessWidget {
  final Color color;
  final double size;
  const _ShieldCheckIcon({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _ShieldCheckPainter(color: color)),
    );
  }
}

class _ShieldCheckPainter extends CustomPainter {
  final Color color;
  const _ShieldCheckPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shield = Path();
    shield.moveTo(w * 0.50, h * 0.04);
    shield.cubicTo(
        w * 0.50, h * 0.04, w * 0.17, h * 0.17, w * 0.17, h * 0.29);
    shield.lineTo(w * 0.17, h * 0.54);
    shield.cubicTo(
        w * 0.17, h * 0.75, w * 0.33, h * 0.88, w * 0.50, h * 0.96);
    shield.cubicTo(
        w * 0.67, h * 0.88, w * 0.83, h * 0.75, w * 0.83, h * 0.54);
    shield.lineTo(w * 0.83, h * 0.29);
    shield.cubicTo(
        w * 0.83, h * 0.17, w * 0.50, h * 0.04, w * 0.50, h * 0.04);
    shield.close();
    canvas.drawPath(shield, paint);

    final check = Path();
    check.moveTo(w * 0.32, h * 0.52);
    check.lineTo(w * 0.44, h * 0.64);
    check.lineTo(w * 0.68, h * 0.40);
    canvas.drawPath(check, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}