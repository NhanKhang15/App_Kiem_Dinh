import 'package:flutter/material.dart';

class VehicleReceiptScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String plate;
  final String vehicleType;
  final String brand;
  final String totalCost;

  const VehicleReceiptScreen({
    super.key,
    this.orderId = 'DK002',
    this.customerName = 'Nguyễn Thị Hương',
    this.plate = '29B-678.90',
    this.vehicleType = 'Ô tô con',
    this.brand = 'Honda City',
    this.totalCost = '340.000đ',
  });

  @override
  State<VehicleReceiptScreen> createState() => _VehicleReceiptScreenState();
}

class _VehicleReceiptScreenState extends State<VehicleReceiptScreen> {
  final _nameCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  final List<bool> _photoTaken = List.filled(6, false);
  final List<bool> _checkItems = List.filled(8, false);
  bool _hasSigned = false;
  int _paymentMethod = 0;

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
    'Lốp xe còn tốt',
    'Đèn chiếu sáng hoạt động',
    'Gương chiếu hậu đầy đủ',
    'Kính chắn gió nguyên vẹn',
    'Nội thất sạch sẽ',
    'Động cơ hoạt động bình thường',
    'Xác nhận mức nhiên liệu',
  ];

  int get _photoCount => _photoTaken.where((v) => v).length;
  int get _checkCount => _checkItems.where((v) => v).length;

  bool get _infoFilled =>
      _nameCtrl.text.isNotEmpty &&
          _idCtrl.text.isNotEmpty &&
          _phoneCtrl.text.isNotEmpty &&
          _addressCtrl.text.isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _idCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildSection1(),
                  const SizedBox(height: 16),
                  _buildSection2(),
                  const SizedBox(height: 16),
                  _buildSection3(),
                  const SizedBox(height: 16),
                  _buildSection4(),
                  const SizedBox(height: 16),
                  _buildSection5(),
                  const SizedBox(height: 16),
                  _buildSection6(),
                  const SizedBox(height: 16),
                  _buildCompletionStatus(),
                  const SizedBox(height: 16),
                  _buildSubmitButton(context),
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
        boxShadow: [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
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
                  const Text(
                    'Biên bản NHẬN xe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.plate} • ${widget.customerName}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow('Khách hàng:', widget.customerName),
          const SizedBox(height: 8),
          _summaryRow('Loại xe:', widget.vehicleType),
          const SizedBox(height: 8),
          _summaryRow('Hãng xe:', widget.brand),
          const SizedBox(height: 8),
          _summaryRow('Tổng chi phí:', widget.totalCost, valueBig: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool valueBig = false}) {
    return Row(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: valueBig ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _inputField(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1, bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
            if (required)
              const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSection1() {
    return _buildSectionCard(
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF16A34A),
      title: '1. Thông tin khách hàng',
      hint: 'Thông tin này sẽ tự động điền vào biên bản ủy quyền',
      hintBg: const Color(0xFFEFF6FF),
      hintText: const Color(0xFF1D4ED8),
      hintIcon: Icons.lightbulb_outline_rounded,
      hintIconColor: const Color(0xFF3B82F6),
      child: Column(
        children: [
          _inputField('Họ và tên', _nameCtrl, hint: 'Nhập họ và tên đầy đủ'),
          _inputField('CMND/CCCD', _idCtrl, hint: 'Nhập số CMND/CCCD'),
          _inputField('Số điện thoại', _phoneCtrl, hint: 'Nhập số điện thoại'),
          _inputField('Địa chỉ', _addressCtrl, hint: 'Nhập địa chỉ đầy đủ', maxLines: 2),
        ],
      ),
    );
  }

  Widget _buildSection2() {
    return _buildSectionCard(
      icon: Icons.camera_alt_outlined,
      iconColor: const Color(0xFF2563EB),
      title: '2. Chụp 6 ảnh thực tế của xe ($_photoCount/6)',
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
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (taken)
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28)
                  else
                    const Icon(Icons.camera_alt_outlined, color: Color(0xFF9CA3AF), size: 24),
                  const SizedBox(height: 6),
                  Text(
                    _photoLabels[i].$2,
                    style: const TextStyle(fontSize: 22),
                  ),
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

  Widget _buildSection3() {
    return _buildSectionCard(
      icon: Icons.check_rounded,
      iconColor: const Color(0xFF7C3AED),
      title: '3. Checklist kiểm tra ($_checkCount/8)',
      hint: 'Mỗi hạng mục đã check phải có ảnh kèm theo',
      hintBg: const Color(0xFFF5F3FF),
      hintText: const Color(0xFF5B21B6),
      hintIcon: Icons.lightbulb_outline_rounded,
      hintIconColor: const Color(0xFF7C3AED),
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

  Widget _buildSection4() {
    return _buildSectionCard(
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF6B7280),
      title: '4. Ghi chú chung (tùy chọn)',
      child: TextField(
        controller: _noteCtrl,
        maxLines: 4,
        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        decoration: InputDecoration(
          hintText: 'Nhập ghi chú thêm về tình trạng xe...',
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
            borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
      ),
    );
  }

  Widget _buildSection5() {
    return _buildSectionCard(
      icon: Icons.edit_outlined,
      iconColor: const Color(0xFFEA580C),
      title: '5. Chữ ký khách hàng',
      hint: 'Yêu cầu khách hàng ký vào biên bản ủy quyền',
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
                style: BorderStyle.solid,
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
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Xác nhận chữ ký',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection6() {
    final methods = [
      ('VietQR', 'Quét mã thanh toán', '🔳'),
      ('Tiền mặt', 'Thu tiền trực tiếp', '💵'),
    ];

    return _buildSectionCard(
      icon: Icons.credit_card_outlined,
      iconColor: const Color(0xFF2563EB),
      title: '6. Phương thức thanh toán',
      hint: 'Chọn phương thức thanh toán phù hợp',
      hintBg: const Color(0xFFEFF6FF),
      hintText: const Color(0xFF1D4ED8),
      hintIcon: Icons.lightbulb_outline_rounded,
      hintIconColor: const Color(0xFF3B82F6),
      child: Row(
        children: List.generate(2, (i) {
          final selected = _paymentMethod == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _paymentMethod = i),
              child: Container(
                margin: EdgeInsets.only(right: i == 0 ? 10 : 0),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(methods[i].$3, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 6),
                    Text(
                      methods[i].$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: selected ? const Color(0xFF1D4ED8) : const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      methods[i].$2,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompletionStatus() {
    final items = [
      ('1. Thông tin khách hàng', null, _infoFilled),
      ('2. Ảnh xe (6 ảnh)', '${_photoCount}/6', _photoCount == 6),
      ('3. Checklist + Ảnh', '${_checkCount}/8', _checkCount == 8),
      ('5. Chữ ký khách hàng', null, _hasSigned),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
        boxShadow: const [BoxShadow(color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.task_alt_rounded, color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Text(
                  'Tình trạng hoàn thành',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(item.$1,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
                    const Spacer(),
                    if (item.$2 != null)
                      Text(item.$2!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.$3 ? const Color(0xFF16A34A) : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                        color: item.$3 ? const Color(0xFF16A34A) : Colors.transparent,
                      ),
                      child: item.$3
                          ? const Icon(Icons.check_rounded, color: Colors.white, size: 12)
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    final allDone = _infoFilled && _photoCount == 6 && _checkCount == 8 && _hasSigned;
    return GestureDetector(
      onTap: allDone ? () {} : null,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: allDone
                ? [const Color(0xFF2563EB), const Color(0xFF1D4ED8)]
                : [const Color(0xFFD1D5DB), const Color(0xFFD1D5DB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: allDone
              ? [BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_rounded,
                color: allDone ? Colors.white : const Color(0xFF9CA3AF), size: 20),
            const SizedBox(width: 10),
            Text(
              'Gửi yêu cầu thanh toán QR',
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