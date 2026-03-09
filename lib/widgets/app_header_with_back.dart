import 'package:flutter/material.dart';

/// Header giống OrderDetailScreen: nền trắng, bo góc dưới, trang trí vòng tròn, nút Quay lại + tiêu đề + subtitle.
class AppHeaderWithBack extends StatelessWidget {
  const AppHeaderWithBack({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  /// Nếu null thì mặc định Navigator.pop; nếu set thì gọi callback (vd. bước trước trong wizard).
  final VoidCallback? onBack;
  /// Widget hiển thị dưới subtitle (vd. thanh progress bước).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
                    onTap: () => onBack != null ? onBack!() : Navigator.of(context).pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          letterSpacing: -0.3,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                      if (bottom != null) ...[
                        const SizedBox(height: 10),
                        bottom!,
                      ],
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
