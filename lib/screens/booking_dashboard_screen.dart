import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:math' as math;
import 'package:vehicle_registration_app/models/vehicle_model.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';
import 'package:vehicle_registration_app/services/vehicle_service.dart';
import 'package:vehicle_registration_app/screens/vehicle_detail_sheet.dart';
import 'package:vehicle_registration_app/screens/edit_vehicle_screen.dart';
import 'package:vehicle_registration_app/screens/book_inspection_screen.dart';

class BookingDashboardScreen extends StatefulWidget {
  const BookingDashboardScreen({super.key});

  @override
  State<BookingDashboardScreen> createState() => _BookingDashboardScreenState();
}

class _BookingDashboardScreenState extends State<BookingDashboardScreen> {
  int _currentIndex = 0;
  List<VehicleModel> _vehicles = [];
  bool _vehiclesLoading = true;
  String? _vehiclesError;
  final VehicleService _vehicleService = VehicleService();

  @override
  void initState() {
    super.initState();
    // Gọi load sau 1 frame để token từ login đã kịp gắn vào ApiClient và storage đã ghi xong.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVehicles());
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _vehiclesLoading = true;
      _vehiclesError = null;
    });
    try {
      final res = await _vehicleService.getVehicles();
      setState(() {
        _vehicles = res.results;
        _vehiclesLoading = false;
      });
    } catch (e, stack) {
      String message = 'Tải danh sách xe thất bại.';
      if (e.toString().contains('SocketException')) {
        message = 'Không thể kết nối server.';
      } else if (e is DioException) {
        final statusCode = e.response?.statusCode;
        final body = e.response?.data;
        debugPrint('[Vehicle] DioException: statusCode=$statusCode, data=$body');
        debugPrint('[Vehicle] stack: $stack');
        if (statusCode == 401) {
          message = 'Chưa đăng nhập hoặc phiên hết hạn (401). Vui lòng đăng nhập lại.';
        } else if (statusCode == 403) {
          message = 'Không có quyền truy cập (403).';
        } else if (body is Map && body['detail'] != null) {
          message = body['detail'].toString();
        } else if (statusCode != null) {
          message = 'Lỗi server ($statusCode). Thử lại sau.';
        }
      } else {
        debugPrint('[Vehicle] Error: $e');
        debugPrint('[Vehicle] stack: $stack');
        message = e.toString().length > 80 ? '${e.toString().substring(0, 80)}...' : e.toString();
      }
      setState(() {
        _vehiclesError = message;
        _vehiclesLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  // ── Hero header ───────────────────────────────────
                  _buildHeroHeader(),

                  // ── Alert card: negative margin pulls it UP into header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                    child: Transform.translate(
                      offset: const Offset(0, -32),
                      child: _buildAlertCard(),
                    ),
                  ),

                  // ── Rest of content (compensate for the -32 shift)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsCard(),
                        const SizedBox(height: 22),
                        _buildSectionTitle(
                          icon: Icons.bolt,
                          iconColor: const Color(0xFFF59E0B),
                          title: 'Dịch vụ nhanh',
                        ),
                        const SizedBox(height: 12),
                        _buildQuickServices(),
                        const SizedBox(height: 22),
                        _buildAppointmentSection(),
                        const SizedBox(height: 16),
                        _buildVehicleSection(),
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
    );
  }

  // ── Hero Header ─────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B5BF5), Color(0xFF6366F1), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Grid pattern overlay
          Positioned.fill(
            child: CustomPaint(painter: _GridPatternPainter()),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 52),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PREMIUM DASHBOARD badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.auto_awesome,
                                      color: Color(0xFFFBBF24), size: 13),
                                  SizedBox(width: 5),
                                  Text(
                                    'PREMIUM DASHBOARD',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Text(
                              'Xin chào, Nam ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                              ),
                            ),
                            Text('👋', style: TextStyle(fontSize: 24)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Chào mừng bạn quay trở lại',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bell icon with badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.notifications_none_rounded,
                            color: Colors.white, size: 22),
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text('3',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.logout, color: Colors.white.withOpacity(0.9), size: 22),
                    onPressed: () => AuthStorage.logout(context),
                    tooltip: 'Đăng xuất',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Alert Card ──────────────────────────────────────────────
  Widget _buildAlertCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFFF6B35).withOpacity(0.45), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B35).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: icon + title + badge ─────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.error_outline_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: Text(
                          'Sắp hết hạn đăng kiểm!',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E4),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Khẩn',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ── Row 2: description text ──────────────────────
            RichText(
              text: const TextSpan(
                style: TextStyle(
                    fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                children: [
                  TextSpan(text: 'Xe '),
                  TextSpan(
                    text: '29A-12345',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827)),
                  ),
                  TextSpan(text: ' sẽ hết hạn vào '),
                  TextSpan(
                    text: '15/02/2026',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF97316)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // ── Row 3: CTA button ────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookInspectionScreen())),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF97316).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Đặt lịch ngay',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats Card ──────────────────────────────────────────────
  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
      child: Row(
        children: [
          // Car icon
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B5BF5), Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B5BF5).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.directions_car_filled,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tổng số xe',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: const [
                  Text('2',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827))),
                  SizedBox(width: 4),
                  Text('xe',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const Spacer(),
          // ── Status box ── "Trạng thái" + shield + "Tốt"
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFFEF2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: const Color(0xFF16A34A).withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Trạng thái',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.shield_outlined,
                        color: Color(0xFF16A34A), size: 17),
                    SizedBox(width: 5),
                    Text(
                      'Tốt',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Title ───────────────────────────────────────────
  Widget _buildSectionTitle({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 7),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        if (actionText != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onAction,
            child: Row(
              children: [
                Text(
                  actionText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF3B5BF5),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward_rounded,
                    color: Color(0xFF3B5BF5), size: 14),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Quick Services ──────────────────────────────────────────
  Widget _buildQuickServices() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookInspectionScreen())),
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B5BF5), Color(0xFF6366F1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B5BF5).withOpacity(0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Subtle dot pattern
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: CustomPaint(painter: _DotPatternPainter()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.calendar_today_rounded,
                                  color: Colors.white, size: 20),
                            ),
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_forward_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const Text(
                          'Đặt lịch',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Đăng kiểm nhanh chóng',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Hỗ trợ 24/7 card
        Expanded(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: 130,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.help_outline_rounded,
                              color: Colors.white, size: 20),
                        ),
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 16),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Text(
                      'Hỗ trợ 24/7',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tư vấn miễn phí',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Appointment Section ─────────────────────────────────────
  Widget _buildAppointmentSection() {
    return Column(
      children: [
        _buildSectionTitle(
          icon: Icons.calendar_month_rounded,
          iconColor: const Color(0xFF3B5BF5),
          title: 'Lịch hẹn sắp tới',
          actionText: 'Xem tất cả',
          onAction: () => Navigator.pushNamed(context, '/orders'),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/orderTracking', arguments: {
                'orderId': '29A-12345',
                'stationName': 'TT Đăng kiểm 29-03D',
                'stationAddress': 'Số 8 Phạm Hùng, Cầu Giấy, HN',
                'appointmentDate': '15/02/2026',
                'appointmentTime': '09:00 - 10:00',
                'completedSteps': 2,
              });
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
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
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Station row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B5BF5), Color(0xFF6366F1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.calendar_today_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TT Đăng kiểm 29-03D',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Số 8 Phạm Hùng, Cầu Giấy, HN',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B5BF5), Color(0xFF6366F1)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Đã đặt',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1, color: Color(0xFFF3F4F6)),
                    const SizedBox(height: 14),
                    // Date & time row
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(Icons.calendar_today_outlined,
                                    color: Color(0xFF3B5BF5), size: 15),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ngày hẹn',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade400)),
                                  const Text(
                                    '15/02/2026',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: const Icon(Icons.access_time_rounded,
                                    color: Color(0xFF3B5BF5), size: 15),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Giờ hẹn',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey.shade400)),
                                  const Text(
                                    '09:00 - 10:00',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Vehicle Section ─────────────────────────────────────────
  Widget _buildVehicleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          icon: Icons.directions_car_outlined,
          iconColor: const Color(0xFF3B5BF5),
          title: 'Xe của bạn',
          actionText: 'Quản lý',
          onAction: () async {
            await Navigator.pushNamed(context, '/vehicleManagement');
            if (mounted) _loadVehicles();
          },
        ),
        const SizedBox(height: 12),
        if (_vehiclesLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF3B5BF5),
                ),
              ),
            ),
          )
        else if (_vehiclesError != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _vehiclesError!,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ),
                TextButton(
                  onPressed: _loadVehicles,
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          )
        else if (_vehicles.isEmpty)
          _buildVehicleEmptyState()
        else
          ...List.generate(_vehicles.length, (i) {
            final v = _vehicles[i];
            final bgColor = i % 2 == 0
                ? const Color(0xFF3B5BF5)
                : const Color(0xFF1E1E2E);
            return Padding(
              padding: EdgeInsets.only(bottom: i < _vehicles.length - 1 ? 10 : 0),
              child: _buildVehicleCard(
                plateNumber: v.licensePlate,
                model: v.brandModel,
                type: v.vehicleTypeName,
                bgColor: bgColor,
                isDark: i % 2 == 1,
                onTap: () async {
                  final result = await VehicleDetailSheet.show(context, v);
                  if (!context.mounted) return;
                  if (result != null && result['action'] == 'edit' && result['id'] != null) {
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditVehicleScreen(vehicleId: result['id'] as int),
                      ),
                    );
                    if (context.mounted) _loadVehicles();
                  }
                },
              ),
            );
          }),
      ],
    );
  }

  /// UI khi chưa có xe (API trả về count: 0, results: []). Không hiển thị "Tải lại".
  Widget _buildVehicleEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có xe nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bấm Quản lý ở trên để thêm xe mới',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard({
    required String plateNumber,
    required String model,
    required String type,
    required Color bgColor,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    final child = Container(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: bgColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.directions_car_filled,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plateNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    model,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF16A34A), size: 15),
                    const SizedBox(width: 4),
                    const Text(
                      'Tốt',
                      style: TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.arrow_forward_rounded,
                      color: Color(0xFF3B5BF5), size: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: child,
      );
    }
    return child;
  }

  // ── Bottom Nav Bar ──────────────────────────────────────────
  Widget _buildBottomNavBar() {
    final tabs = [
      _NavTab(icon: Icons.home_rounded, label: 'Trang chủ'),
      _NavTab(icon: Icons.calendar_today_rounded, label: 'Đặt lịch'),
      _NavTab(icon: Icons.map_outlined, label: 'Bản đồ'),
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
                        width: selected ? 36 : 0,
                        height: selected ? 4 : 0,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B5BF5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Icon(
                        tabs[i].icon,
                        size: 24,
                        color: selected
                            ? const Color(0xFF3B5BF5)
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
                              ? const Color(0xFF3B5BF5)
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

// ── Data models ─────────────────────────────────────────────────
class _NavTab {
  final IconData icon;
  final String label;
  _NavTab({required this.icon, required this.label});
}

// ── Grid pattern painter ─────────────────────────────────────────
class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.07)
      ..strokeWidth = 1;
    const step = 50.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Dot pattern painter ──────────────────────────────────────────
class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    const step = 18.0;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}