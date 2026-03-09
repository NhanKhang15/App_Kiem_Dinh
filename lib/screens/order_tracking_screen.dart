import 'package:agora_chat_sdk/agora_chat_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vehicle_registration_app/config/agora_config.dart';
import 'package:vehicle_registration_app/screens/agora_call_screen.dart';
import 'package:vehicle_registration_app/services/agora_chat_service.dart';
import 'package:vehicle_registration_app/widgets/app_header_with_back.dart';

/// Màn "Theo dõi đơn hàng": tiến độ 7 bước, nhân viên đang đến, vị trí, thông tin NV, chi phí.
class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({
    super.key,
    this.orderId = '29A-12345',
    this.stationName = 'TT Đăng kiểm 29-03D',
    this.stationAddress = 'Số 8 Phạm Hùng, Cầu Giấy, HN',
    this.appointmentDate = '15/02/2026',
    this.appointmentTime = '09:00 - 10:00',
    this.completedSteps = 2,
    this.staffPhone,
  });

  final String orderId;
  final String stationName;
  final String stationAddress;
  final String appointmentDate;
  final String appointmentTime;
  /// Số bước đã hoàn thành (1–7). Mặc định 2: Xác nhận, Đang đến.
  final int completedSteps;
  /// SĐT nhân viên (để gọi tel / mở Zalo).
  final String? staffPhone;

  static const List<String> _stepLabels = [
    'Xác nhận',
    'Đang đến',
    'Nhận xe',
    'TT lần 1',
    'Đăng kiểm',
    'Trả xe',
    'Hoàn thành',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeaderWithBack(
              title: 'Theo dõi đơn hàng',
              subtitle: orderId,
              bottom: _buildProgressStepper(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStaffEnRouteCard(),
                    const SizedBox(height: 14),
                    _buildRealtimeLocationCard(),
                    const SizedBox(height: 14),
                    _buildStaffInfoCard(context),
                    const SizedBox(height: 14),
                    _buildEstimatedCostCard(),
                  ],
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStepper() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (int i = 0; i < 7; i++) ...[
            if (i > 0)
              Expanded(
                flex: 1,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  height: 2,
                  alignment: Alignment.center,
                  child: (i <= completedSteps)
                      ? Container(
                          color: const Color(0xFF3B5BF5),
                          height: 2,
                          width: double.infinity,
                        )
                      : CustomPaint(
                          painter: _DashedLinePainter(
                            color: Colors.grey.shade300,
                          ),
                        ),
                ),
              ),
            Expanded(
              flex: 3,
              child: _buildStepItem(i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepItem(int i) {
    final index = i + 1;
    final isCompleted = index <= completedSteps;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted
                ? const Color(0xFF3B5BF5)
                : Colors.grey.shade300,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: isCompleted
              ? const Icon(Icons.check_rounded,
                  color: Colors.white, size: 18)
              : Center(
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 4),
        Text(
          _stepLabels[i],
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            color: isCompleted
                ? const Color(0xFF3B5BF5)
                : Colors.grey.shade500,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStaffEnRouteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: Color(0xFFDC2626), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhân viên đang đến',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhân viên Nguyễn Văn B đang trên đường đến địa chỉ của bạn để nhận xe.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 16, color: const Color(0xFF3B5BF5).withOpacity(0.9)),
                    const SizedBox(width: 6),
                    Text(
                      'Dự kiến đến lúc 08:45',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3B5BF5).withOpacity(0.95),
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

  Widget _buildRealtimeLocationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Vị trí realtime',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            height: 140,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 56,
                  color: Color(0xFF3B5BF5),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car_rounded,
                            color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Đang di chuyển',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 20, color: Color(0xFF3B5BF5)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stationName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stationAddress,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChatBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => _ChatSheetContent(
          scrollController: scrollController,
          onClose: () => Navigator.of(ctx).pop(),
          staffChatUserId: 'staff_1',
        ),
      ),
    );
  }

  void _showCallOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chọn cách liên hệ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 16),
            _contactOptionTile(
              context: ctx,
              icon: Icons.phone_in_talk_rounded,
              iconColor: const Color(0xFF3B5BF5),
              label: 'Gọi trong app',
              subtitle: 'Gọi thoại qua Agora (trong ứng dụng)',
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => AgoraCallScreen(
                      channelId: 'order_${orderId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
                      remoteTitle: 'Nhân viên',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _contactOptionTile(
              context: ctx,
              icon: Icons.phone_rounded,
              iconColor: const Color(0xFF16A34A),
              label: 'Gọi điện thoại',
              subtitle: staffPhone != null && staffPhone!.isNotEmpty
                  ? 'Gọi $staffPhone'
                  : 'Gọi bằng app Điện thoại',
              onTap: () {
                Navigator.pop(ctx);
                _launchCall(context);
              },
            ),
            const SizedBox(height: 10),
            _contactOptionTile(
              context: ctx,
              icon: Icons.chat_rounded,
              iconColor: const Color(0xFF0068FF),
              label: 'Mở Zalo',
              subtitle: 'Chat hoặc gọi qua Zalo',
              onTap: () {
                Navigator.pop(ctx);
                _launchZalo(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchCall(BuildContext context) async {
    final phone = staffPhone?.trim();
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có số điện thoại nhân viên')),
        );
      }
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng gọi điện')),
      );
    }
  }

  Future<void> _launchZalo(BuildContext context) async {
    final phone = staffPhone?.trim();
    if (phone == null || phone.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chưa có số điện thoại để mở Zalo')),
        );
      }
      return;
    }
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://zalo.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở Zalo')),
      );
    }
  }

  Widget _contactOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffInfoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin nhân viên',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade300,
                child: Icon(Icons.person_rounded,
                    size: 32, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nguyễn Văn B',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mã NV: NV-12345',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 18, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        const Text(
                          '4.9',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.directions_car_rounded,
                                  size: 14, color: Color(0xFF3B5BF5)),
                              SizedBox(width: 4),
                              Text(
                                '29X-98765',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF3B5BF5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  _contactButton(
                    icon: Icons.phone_rounded,
                    color: const Color(0xFF16A34A),
                    onTap: () => _showCallOptions(context),
                  ),
                  const SizedBox(height: 10),
                  _contactButton(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: const Color(0xFF3B5BF5),
                    onTap: () => _showChatBottomSheet(context),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildEstimatedCostCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi phí dự kiến',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Phí đăng kiểm:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              const Text(
                '350.000₫',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const Text(
                '350.000₫',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3B5BF5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
              _navItem(context, Icons.home_rounded, 'Trang chủ', () {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }),
              _navItem(context, Icons.calendar_today_rounded, 'Đặt lịch', () {}),
              _navItem(context, Icons.map_outlined, 'Bản đồ', () {}),
              _navItem(context, Icons.person_outline_rounded, 'Cá nhân', () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Colors.grey.shade400),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nội dung khung chat trong bottom sheet (header xanh, tin nhắn, ô nhập).
/// Nếu cấu hình [AgoraConfig.chatToken] thì chat realtime qua Agora; không thì dùng tin mẫu.
class _ChatSheetContent extends StatefulWidget {
  const _ChatSheetContent({
    required this.scrollController,
    required this.onClose,
    this.staffChatUserId = 'staff_1',
  });

  final ScrollController scrollController;
  final VoidCallback onClose;
  final String staffChatUserId;

  @override
  State<_ChatSheetContent> createState() => _ChatSheetContentState();
}

class _ChatSheetContentState extends State<_ChatSheetContent> {
  final TextEditingController _messageController = TextEditingController();
  /// Mặc định hiển thị tin mẫu để màn không trống; nếu bật Agora sẽ thay bằng lịch sử thật.
  final List<Map<String, dynamic>> _messages = [
    {'fromStaff': true, 'text': 'Xin chào! Tôi đã nhận xe của bạn và đang trên đường đến trạm đăng kiểm.', 'time': '09:15'},
    {'fromStaff': false, 'text': 'Cảm ơn anh. Cho em hỏi mất bao lâu ạ?', 'time': '09:16'},
    {'fromStaff': true, 'text': 'Dự kiến khoảng 2 tiếng nữa là xong nhé bạn.', 'time': '09:17'},
  ];
  bool _agoraReady = false;
  bool _loading = !AgoraConfig.hasChatToken;
  String? _agoraError;

  @override
  void initState() {
    super.initState();
    _initAgoraChat();
  }

  Future<void> _initAgoraChat() async {
    if (!AgoraConfig.hasChatToken) {
      debugPrint('[Chat] Chưa cấu hình chatToken → giữ ${_messages.length} tin mẫu (đã có sẵn)');
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (mounted) setState(() => _loading = true);
    _messages.clear();
    debugPrint('[Chat] Đang đăng nhập Agora Chat (userId=${AgoraConfig.chatUserId})...');
    try {
      await AgoraChatService.instance.init();
      await AgoraChatService.instance.loginWithToken();
      final list = await AgoraChatService.instance.loadMessages(widget.staffChatUserId);
      final currentUserId = AgoraConfig.chatUserId;
      final items = list.map((m) => _chatMessageToItem(m, currentUserId)).toList();
      items.sort((a, b) => (a['timestamp'] as int).compareTo(b['timestamp'] as int));
      if (mounted) {
        setState(() {
          _messages.addAll(items);
          if (_messages.isEmpty) {
            _messages.add({
              'fromStaff': true,
              'text': 'Chào bạn! Nhân viên sẽ phản hồi khi có thể. Bạn có thể nhắn tin bên dưới.',
              'time': _formatTimeFromTs(DateTime.now().millisecondsSinceEpoch),
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'msgId': 'welcome',
            });
          }
          _loading = false;
          _agoraReady = true;
        });
        debugPrint('[Chat] Hiển thị ${_messages.length} tin');
      }
      AgoraChatService.instance.addMessagesListener(_onAgoraMessagesReceived);
      debugPrint('[Chat] Agora OK, hiển thị ${_messages.length} tin (lịch sử + realtime)');
    } catch (e, st) {
      debugPrint('[Chat] Lỗi Agora: $e');
      debugPrint('[Chat] Stack: $st');
      if (mounted) {
        setState(() {
          _agoraError = e.toString();
          _messages.addAll(_mockMessages);
          _loading = false;
          _agoraReady = false;
        });
      }
    }
  }

  void _onAgoraMessagesReceived(List<ChatMessage> list) {
    if (!mounted || !_agoraReady) return;
    final currentUserId = AgoraConfig.chatUserId;
    for (final m in list) {
      if (m.conversationId != widget.staffChatUserId) continue;
      final item = _chatMessageToItem(m, currentUserId);
      if (!_messages.any((e) => e['msgId'] == m.msgId)) {
        setState(() => _messages.add(item));
      }
    }
  }

  static Map<String, dynamic> _chatMessageToItem(ChatMessage m, String currentUserId) {
    final body = m.body;
    String text = '';
    if (body is ChatTextMessageBody) text = body.content;
    final fromStaff = m.from != null && m.from != currentUserId;
    final ts = m.serverTime ?? m.localTime ?? 0;
    return {
      'fromStaff': fromStaff,
      'text': text,
      'time': _formatTimeFromTs(ts),
      'timestamp': ts,
      'msgId': m.msgId,
    };
  }

  static String _formatTimeFromTs(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static final List<Map<String, dynamic>> _mockMessages = [
    {'fromStaff': true, 'text': 'Xin chào! Tôi đã nhận xe của bạn và đang trên đường đến trạm đăng kiểm.', 'time': '09:15'},
    {'fromStaff': false, 'text': 'Cảm ơn anh. Cho em hỏi mất bao lâu ạ?', 'time': '09:16'},
    {'fromStaff': true, 'text': 'Dự kiến khoảng 2 tiếng nữa là xong nhé bạn.', 'time': '09:17'},
  ];

  @override
  void dispose() {
    AgoraChatService.instance.removeMessagesListener();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_agoraError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Chat Agora: $_agoraError',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      return _buildMessage(
                        m['text'] as String,
                        m['time'] as String,
                        m['fromStaff'] as bool,
                      );
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B5BF5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nguyễn Văn B',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Trực tuyến',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, String time, bool fromStaff) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: fromStaff ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!fromStaff) const Spacer(),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Column(
              crossAxisAlignment: fromStaff ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: fromStaff ? Colors.grey.shade200 : const Color(0xFF3B5BF5),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(fromStaff ? 4 : 16),
                      bottomRight: Radius.circular(fromStaff ? 16 : 4),
                    ),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      color: fromStaff ? const Color(0xFF111827) : Colors.white,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          if (fromStaff) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.image_outlined, color: Colors.grey.shade600, size: 24),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF3B5BF5),
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              onTap: () => _sendMessage(),
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final t = _messageController.text.trim();
    if (t.isEmpty) return;
    _messageController.clear();
    final now = DateTime.now();
    final timeStr = _formatTime(now);
    if (_agoraReady) {
      setState(() => _messages.add({
            'fromStaff': false,
            'text': t,
            'time': timeStr,
            'timestamp': now.millisecondsSinceEpoch,
            'msgId': null,
          }));
      await AgoraChatService.instance.sendText(widget.staffChatUserId, t);
    } else {
      setState(() => _messages.add({'fromStaff': false, 'text': t, 'time': timeStr}));
    }
  }

  String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    const dashWidth = 4.0;
    const gap = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, size.height / 2),
          Offset(x + dashWidth.clamp(0.0, size.width - x), size.height / 2), paint);
      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
