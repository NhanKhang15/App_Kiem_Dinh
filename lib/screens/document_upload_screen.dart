import 'package:flutter/material.dart';

class DocumentUploadScreen extends StatefulWidget {
  final String plate;
  final String customerName;

  const DocumentUploadScreen({
    super.key,
    this.plate = '29B-678.90',
    this.customerName = 'Nguyễn Thị Hương',
  });

  @override
  State<DocumentUploadScreen> createState() => _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends State<DocumentUploadScreen> {
  final _noteCtrl = TextEditingController();

  final List<_DocItem> _docs = [
    _DocItem(title: 'Giấy đăng ký xe', emoji: '📋', required: true),
    _DocItem(title: 'Bảo hiểm xe', emoji: '🛡️', required: true),
    _DocItem(title: 'Biên lai phí đăng kiểm', emoji: '🗒️', required: true),
    _DocItem(title: 'Giấy chứng nhận đăng kiểm', emoji: '📄', required: true),
    _DocItem(title: 'Tem đăng kiểm', emoji: '🏷️', required: true),
    _DocItem(title: 'Tài liệu khác', emoji: '📁', required: false),
  ];

  int get _uploadedRequired =>
      _docs.where((d) => d.required && d.uploaded).length;
  int get _totalRequired => _docs.where((d) => d.required).length;
  int get _totalPhotos => _docs.fold(0, (s, d) => s + d.photoCount);
  double get _progress => _totalRequired == 0 ? 0 : _uploadedRequired / _totalRequired;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                children: [
                  _buildProgressCard(),
                  const SizedBox(height: 12),
                  _buildTipsCard(),
                  const SizedBox(height: 16),
                  ..._docs.map((doc) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildDocCard(doc),
                  )),
                  _buildNoteCard(),
                  const SizedBox(height: 16),
                  _buildSubmitButton(),
                  const SizedBox(height: 8),
                  if (_uploadedRequired < _totalRequired)
                    Text(
                      'Vui lòng upload đầy đủ $_totalRequired tài liệu bắt buộc',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3))],
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
                child: CustomPaint(painter: _CirclePainter()),
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
                        Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF374151)),
                        SizedBox(width: 6),
                        Text('Quay lại',
                            style: TextStyle(fontSize: 14, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Upload chứng từ',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  const SizedBox(height: 3),
                  Text('${widget.plate} • ${widget.customerName}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final pct = (_progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Tiến độ upload',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8))),
              const Spacer(),
              Text('$pct%',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFDBEAFE),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('$_uploadedRequired/$_totalRequired tài liệu bắt buộc',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              const Spacer(),
              Text('$_totalPhotos ảnh',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Lưu ý khi chụp ảnh',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
                SizedBox(height: 6),
                _TipRow('Chụp rõ nét, đầy đủ thông tin'),
                _TipRow('Đảm bảo đủ ánh sáng'),
                _TipRow('Không bị mờ, nhòe'),
                _TipRow('Có thể upload nhiều ảnh cho mỗi loại'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(_DocItem doc) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(doc.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(doc.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                if (doc.required) ...[
                  const SizedBox(width: 4),
                  const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => doc.addPhoto()),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Chụp ảnh',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => doc.addPhoto()),
                    child: Container(
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.photo_library_outlined, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text('Thư viện',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            doc.photoCount == 0
                ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.description_outlined, color: Color(0xFF9CA3AF), size: 22),
                  ),
                  const SizedBox(height: 8),
                  const Text('Chưa có ảnh',
                      style: TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  const Text('Nhấn nút bên trên để upload',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                ],
              ),
            )
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(doc.photoCount, (i) => Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image_outlined, color: Color(0xFF2563EB), size: 28),
                        Text('Ảnh ${i + 1}',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 2, right: 2,
                    child: GestureDetector(
                      onTap: () => setState(() => doc.removePhoto()),
                      child: Container(
                        width: 18, height: 18,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.description_outlined, color: Color(0xFF6B7280), size: 18),
                SizedBox(width: 8),
                Text('Ghi chú',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
              decoration: InputDecoration(
                hintText: 'Thông tin bổ sung về các chứng từ...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
                filled: true,
                fillColor: const Color(0xFFFAFAFA),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final allDone = _uploadedRequired >= _totalRequired;
    return GestureDetector(
      onTap: allDone ? () {} : null,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: allDone ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
          boxShadow: allDone
              ? [BoxShadow(color: const Color(0xFF2563EB).withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5))]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_rounded,
                color: allDone ? Colors.white : const Color(0xFF9CA3AF), size: 20),
            const SizedBox(width: 8),
            Text(
              'Hoàn tất upload ($_totalPhotos ảnh)',
              style: TextStyle(
                color: allDone ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final tabs = [
      (Icons.home_rounded, 'Trang chủ'),
      (Icons.receipt_long_outlined, 'Đơn hàng'),
      (Icons.person_outline_rounded, 'Cá nhân'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(3, (i) {
              final selected = i == 1;
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 32 : 0,
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(color: const Color(0xFF16A34A), borderRadius: BorderRadius.circular(2)),
                    ),
                    Icon(tabs[i].$1, size: 24, color: selected ? const Color(0xFF16A34A) : Colors.grey.shade400),
                    const SizedBox(height: 3),
                    Text(tabs[i].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected ? const Color(0xFF16A34A) : Colors.grey.shade400,
                        )),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DocItem {
  final String title;
  final String emoji;
  final bool required;
  int photoCount = 0;

  _DocItem({required this.title, required this.emoji, required this.required});

  bool get uploaded => photoCount > 0;
  void addPhoto() => photoCount++;
  void removePhoto() { if (photoCount > 0) photoCount--; }
}

class _TipRow extends StatelessWidget {
  final String text;
  const _TipRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFFB45309), fontSize: 12)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)))),
        ],
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width - 32, size.height * 0.35), 48, paint);
    canvas.drawCircle(Offset(size.width - 90, size.height * 0.25), 28, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}