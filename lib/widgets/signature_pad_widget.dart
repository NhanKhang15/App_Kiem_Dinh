import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

/// Widget chữ ký khách hàng dùng chung cho Receipt và Return screens.
///
/// Bao gồm: canvas vẽ chữ ký, nút xóa, nút xác nhận,
/// trạng thái "chưa ký" / "đã ký".
class SignaturePadWidget extends StatefulWidget {
  const SignaturePadWidget({
    super.key,
    this.title = 'Chữ ký khách hàng',
    this.hint = 'Yêu cầu khách hàng ký xác nhận',
    this.onSignatureChanged,
  });

  final String title;
  final String hint;

  /// Callback khi trạng thái chữ ký thay đổi (có ký / xóa).
  final ValueChanged<bool>? onSignatureChanged;

  @override
  State<SignaturePadWidget> createState() => SignaturePadWidgetState();
}

class SignaturePadWidgetState extends State<SignaturePadWidget> {
  final SignatureController _signatureCtrl = SignatureController(
    penStrokeWidth: 2.5,
    penColor: const Color(0xFFEA580C),
    exportBackgroundColor: Colors.white,
  );

  bool _hasSigned = false;
  bool _showSignaturePad = false;

  /// Kiểm tra người dùng đã ký chưa.
  bool get hasSigned => _hasSigned;

  /// Export chữ ký thành PNG bytes.
  Future<Uint8List?> toPngBytes() => _signatureCtrl.toPngBytes();

  @override
  void initState() {
    super.initState();
    _signatureCtrl.onDrawEnd = () {
      if (!mounted) return;
      final signed = _signatureCtrl.isNotEmpty;
      setState(() => _hasSigned = signed);
      widget.onSignatureChanged?.call(signed);
    };
  }

  @override
  void dispose() {
    _signatureCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit_outlined, color: Color(0xFFEA580C), size: 20),
                const SizedBox(width: 8),
                Text(widget.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 10),
            // Hint
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(widget.hint,
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Signature area
            GestureDetector(
              onTap: () => setState(() => _showSignaturePad = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: double.infinity,
                padding: EdgeInsets.all(_showSignaturePad ? 12 : 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _hasSigned ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
                  ),
                ),
                child: _showSignaturePad ? _buildSignaturePad() : _buildPlaceholder(),
              ),
            ),
            const SizedBox(height: 12),
            // Confirm button
            GestureDetector(
              onTap: _hasSigned
                  ? () {
                      FocusScope.of(context).unfocus();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Chữ ký đã được xác nhận'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  : () => setState(() => _showSignaturePad = true),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _hasSigned ? 'Đã xác nhận chữ ký' : 'Xác nhận chữ ký',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignaturePad() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 180,
            color: Colors.white,
            child: Signature(
              controller: _signatureCtrl,
              backgroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                _hasSigned
                    ? 'Khách hàng đã ký, có thể xóa để ký lại'
                    : 'Mời khách hàng ký vào khung bên trên',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () {
                _signatureCtrl.clear();
                setState(() => _hasSigned = false);
                widget.onSignatureChanged?.call(false);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFFCA5A5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Xóa'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFE5E7EB),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.draw_rounded, color: Color(0xFFEA580C), size: 28),
        ),
        const SizedBox(height: 12),
        const Text('Chưa có chữ ký',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
        const SizedBox(height: 4),
        const Text('Nhấn vào ô chữ ký để mở vùng ký',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
      ],
    );
  }
}
