import 'package:flutter/material.dart';

class VehicleReturnScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String plate;
  final String vehicleType;
  final String brand;
  final String color;

  const VehicleReturnScreen({
    super.key,
    this.orderId = 'DK002',
    this.customerName = 'Nguyễn Thị Hương',
    this.plate = '29B-678.90',
    this.vehicleType = 'Ô tô con',
    this.brand = 'Honda City',
    this.color = 'Đỏ',
  });

  @override
  State<VehicleReturnScreen> createState() => _VehicleReturnScreenState();
}

class _VehicleReturnScreenState extends State<VehicleReturnScreen> {
  final _noteCtrl = TextEditingController();
  final List<bool> _photoTaken = List.filled(6, false);
  final List<bool> _checkItems = List.filled(8, false);
  bool _hasSigned = false;

  final List<_ExtraFee> _extraFees = [];
  final _feeNameCtrl = TextEditingController();
  final _feeAmountCtrl = TextEditingController();

  final _photoLabels = [
    ('Phía trước', '🚗'),
    ('Phía sau', '🚙'),
    ('Bên trái', '🚘'),
    ('Bên phải', '🚖'),
    ('Nội thất', '💺'),
    ('Bảng điều khiển', '🎛️'),
  ];

  final _checkLabels = [
    'Ngoại thất không trầy xước',
    'Lốp xe đầy đủ, không rò',
    'Hệ thống đèn hoạt động tốt',
    'Gương chiếu hậu nguyên vẹn',
    'Kính chắn gió không vỡ/nứt',
    'Nội thất sạch sẽ',
    'Giấy tờ xe đầy đủ',
    'Tem đăng kiểm đã dán',
  ];

  int get _photoCount => _photoTaken.where((v) => v).length;
  int get _checkCount => _checkItems.where((v) => v).length;

  @override
  void dispose() {
    _noteCtrl.dispose();
    _feeNameCtrl.dispose();
    _feeAmountCtrl.dispose();
    super.dispose();
  }

  void _showAddFeeDialog() {
    _feeNameCtrl.clear();
    _feeAmountCtrl.clear();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Thêm chi phí phát sinh',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _feeNameCtrl,
              decoration: _inputDeco('Tên chi phí', 'VD: Rửa xe, vá lốp...'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _feeAmountCtrl,
              keyboardType: TextInputType.number,
              decoration: _inputDeco('Số tiền', 'VD: 50000'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (_feeNameCtrl.text.isNotEmpty && _feeAmountCtrl.text.isNotEmpty) {
                setState(() {
                  _extraFees.add(_ExtraFee(
                    name: _feeNameCtrl.text,
                    amount: _feeAmountCtrl.text,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Thêm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String label, String hint) => InputDecoration(
    labelText: label,
    hintText: hint,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  );

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildSection1Photos(),
                  const SizedBox(height: 16),
                  _buildSection2Checklist(),
                  const SizedBox(height: 16),
                  _buildSection3ExtraFees(),
                  const SizedBox(height: 16),
                  _buildSection4Note(),
                  const SizedBox(height: 16),
                  _buildSection5Signature(),
                  const SizedBox(height: 16),
                  _buildSaveButton(context),
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
                  const Text('Biên bản TRẢ xe',
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

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Khách hàng:', widget.customerName),
          const SizedBox(height: 8),
          _summaryRow('Loại xe:', widget.vehicleType),
          const SizedBox(height: 8),
          _summaryRow('Hãng xe:', widget.brand),
          const SizedBox(height: 8),
          _summaryRow('Màu sắc:', widget.color),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    String? hint,
    Color? hintBg,
    Color? hintText,
    IconData? hintIcon,
    Color? hintIconColor,
  }) {
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
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hintBg ?? const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(hintIcon ?? Icons.lightbulb_outline_rounded,
                        color: hintIconColor ?? const Color(0xFFF59E0B), size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(hint,
                          style: TextStyle(fontSize: 12, color: hintText ?? const Color(0xFFB45309))),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSection1Photos() {
    return _buildSectionCard(
      icon: Icons.camera_alt_outlined,
      iconColor: const Color(0xFF2563EB),
      title: '1. Chụp 6 ảnh thực tế của xe ($_photoCount/6)',
      hint: 'Bắt buộc chụp đầy đủ 6 ảnh để lưu biên bản',
      hintBg: const Color(0xFFFFF7ED),
      hintText: const Color(0xFFB45309),
      hintIcon: Icons.warning_amber_rounded,
      hintIconColor: const Color(0xFFF59E0B),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: List.generate(6, (i) {
          final taken = _photoTaken[i];
          return GestureDetector(
            onTap: () => setState(() => _photoTaken[i] = !_photoTaken[i]),
            child: Container(
              decoration: BoxDecoration(
                color: taken ? const Color(0xFFEFFEF2) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: taken ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
                  width: taken ? 1.5 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  taken
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28)
                      : const Icon(Icons.camera_alt_outlined, color: Color(0xFF9CA3AF), size: 24),
                  const SizedBox(height: 6),
                  Text(_photoLabels[i].$2, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    _photoLabels[i].$1,
                    style: TextStyle(
                      fontSize: 11,
                      color: taken ? const Color(0xFF15803D) : const Color(0xFF6B7280),
                      fontWeight: taken ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSection2Checklist() {
    return _buildSectionCard(
      icon: Icons.check_rounded,
      iconColor: const Color(0xFF16A34A),
      title: '2. Checklist kiểm tra ($_checkCount/8)',
      hint: 'Mỗi hạng mục đã check phải có ảnh kèm theo',
      hintBg: const Color(0xFFEFFEF2),
      hintText: const Color(0xFF15803D),
      hintIcon: Icons.lightbulb_outline_rounded,
      hintIconColor: const Color(0xFF16A34A),
      child: Column(
        children: List.generate(_checkLabels.length, (i) {
          final checked = _checkItems[i];
          return GestureDetector(
            onTap: () => setState(() => _checkItems[i] = !_checkItems[i]),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: checked ? const Color(0xFFEFFEF2) : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: checked ? const Color(0xFFBBF7D0) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: checked ? const Color(0xFF16A34A) : Colors.white,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(
                        color: checked ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: checked
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _checkLabels[i],
                    style: TextStyle(
                      fontSize: 13,
                      color: checked ? const Color(0xFF15803D) : const Color(0xFF374151),
                      fontWeight: checked ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSection3ExtraFees() {
    return _buildSectionCard(
      icon: Icons.attach_money_rounded,
      iconColor: const Color(0xFFEA580C),
      title: '3. Chi phí phát sinh (tùy chọn)',
      child: Column(
        children: [
          ..._extraFees.map((fee) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_outlined, color: Color(0xFFEA580C), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(fee.name,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                ),
                Text(
                  '${fee.amount}đ',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _extraFees.remove(fee)),
                  child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          )),
          GestureDetector(
            onTap: _showAddFeeDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_rounded, color: Color(0xFF6B7280), size: 18),
                  SizedBox(width: 6),
                  Text('Thêm chi phí phát sinh',
                      style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection4Note() {
    return _buildSectionCard(
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF6B7280),
      title: '4. Ghi chú chung (tùy chọn)',
      child: TextField(
        controller: _noteCtrl,
        maxLines: 4,
        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        decoration: InputDecoration(
          hintText: 'Nhập ghi chú thêm về việc trả xe...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
      ),
    );
  }

  Widget _buildSection5Signature() {
    return _buildSectionCard(
      icon: Icons.edit_outlined,
      iconColor: const Color(0xFFEA580C),
      title: '5. Chữ ký khách hàng',
      hint: 'Yêu cầu khách hàng ký xác nhận đã nhận xe',
      hintBg: const Color(0xFFFFF7ED),
      hintText: const Color(0xFFB45309),
      hintIcon: Icons.warning_amber_rounded,
      hintIconColor: const Color(0xFFF59E0B),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasSigned ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
              ),
            ),
            child: Column(
              children: [
                _hasSigned
                    ? const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48)
                    : const Text('✍️', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  _hasSigned ? 'Đã có chữ ký' : 'Chưa có chữ ký',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _hasSigned ? const Color(0xFF15803D) : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _hasSigned ? 'Khách hàng đã xác nhận' : 'Nhấn nút bên dưới để xác nhận',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _hasSigned = !_hasSigned),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text('Xác nhận chữ ký',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.description_outlined, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              'Lưu biên bản trả xe & Hoàn thành',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
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
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -2)),
        ],
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
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Icon(tabs[i].$1, size: 24,
                        color: selected ? const Color(0xFF16A34A) : Colors.grey.shade400),
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

class _ExtraFee {
  final String name;
  final String amount;
  _ExtraFee({required this.name, required this.amount});
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
    canvas.drawCircle(Offset(24, size.height * 0.8), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}