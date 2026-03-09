import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';
import 'package:vehicle_registration_app/services/vehicle_service.dart';
import 'package:vehicle_registration_app/widgets/app_header_with_back.dart';

/// Loại xe cho dropdown (id trùng với API vehicle_type).
final List<Map<String, dynamic>> kVehicleTypes = [
  {'id': 1, 'name': 'Xe máy'},
  {'id': 3, 'name': 'Ô tô dưới 9 chỗ'},
  {'id': 4, 'name': 'Xe 7-9 chỗ'},
  {'id': 5, 'name': 'Xe bán tải'},
];

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final VehicleService _vehicleService = VehicleService();
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();

  int? _selectedVehicleTypeId = 3;
  bool _submitting = false;
  final _vehicleTypeKey = GlobalKey();
  String? _errorMessage;

  @override
  void dispose() {
    _licenseController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final session = await AuthStorage.getSavedSession();
    final customerId = session?.userId;
    if (customerId == null) {
      setState(() => _errorMessage = 'Vui lòng đăng nhập lại.');
      return;
    }

    setState(() => _submitting = true);
    final brandText = _brandController.text.trim();
    final parts = brandText.isNotEmpty ? brandText.split(RegExp(r'\s+')) : <String>[];
    final brand = parts.isNotEmpty ? parts.first : null;
    final model = parts.length > 1 ? parts.sublist(1).join(' ') : (parts.length == 1 ? null : null);
    try {
      await _vehicleService.createVehicle(
        customerId: customerId,
        vehicleTypeId: _selectedVehicleTypeId!,
        licensePlate: _licenseController.text.trim(),
        brand: brand,
        model: model,
        color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thêm xe thành công.'), backgroundColor: Color(0xFF16A34A)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      String msg = 'Thêm xe thất bại. Thử lại sau.';
      if (e is DioException && e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map) {
          final list = data['license_plate'];
          if (list is List && list.isNotEmpty) msg = list.first.toString();
          else if (data['detail'] != null) msg = data['detail'].toString();
        }
      }
      setState(() {
        _errorMessage = msg;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeaderWithBack(
              title: 'Thêm xe mới',
              subtitle: 'Nhập thông tin xe của bạn',
            ),
            // Form card
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Biển số xe *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _licenseController,
                          decoration: _inputDecoration('VD: 29A-12345'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập biển số xe.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Loại xe *'),
                        const SizedBox(height: 6),
                        _buildVehicleTypeDropdown(),
                        const SizedBox(height: 16),
                        _buildLabel('Hãng xe *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _brandController,
                          decoration: _inputDecoration('VD: Toyota Vios'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập hãng xe.';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildLabel('Màu xe *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _colorController,
                          decoration: _inputDecoration('VD: Trắng'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập màu xe.';
                            return null;
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1D4ED8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Thêm xe',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  /// Loại xe: bấm vào ô → menu xổ xuống **ngay bên dưới ô** (overlay, không đẩy Hãng xe xuống).
  Widget _buildVehicleTypeDropdown() {
    final selectedList = kVehicleTypes
        .cast<Map<String, dynamic>>()
        .where((e) => e['id'] == _selectedVehicleTypeId)
        .toList();
    final selectedName =
        selectedList.isEmpty ? null : selectedList.first['name'] as String?;

    return FormField<int?>(
      initialValue: _selectedVehicleTypeId,
      validator: (v) => v == null ? 'Vui lòng chọn loại xe.' : null,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: _vehicleTypeKey,
              onTap: () async {
                final box = _vehicleTypeKey.currentContext?.findRenderObject();
                if (box is! RenderBox) return;
                final pos = box.localToGlobal(Offset.zero);
                final size = box.size;
                final overlay = Overlay.of(context);
                final overlayBox = overlay.context.findRenderObject() as RenderBox?;
                final overlaySize = overlayBox?.size ?? Size.infinite;
                final selectedId = await showMenu<int>(
                  context: context,
                  position: RelativeRect.fromRect(
                    Rect.fromLTWH(pos.dx, pos.dy, size.width, size.height),
                    Rect.fromLTWH(0, 0, overlaySize.width, overlaySize.height),
                  ),
                  items: kVehicleTypes.map((e) {
                    final id = e['id'] as int;
                    final name = e['name'] as String;
                    return PopupMenuItem<int>(
                      value: id,
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF111827),
                        ),
                      ),
                    );
                  }).toList(),
                );
                if (selectedId != null) {
                  setState(() => _selectedVehicleTypeId = selectedId);
                  state.didChange(selectedId);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedName ?? 'Chọn loại xe',
                        style: TextStyle(
                          fontSize: 14,
                          color: selectedName != null
                              ? const Color(0xFF111827)
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError) ...[
              const SizedBox(height: 6),
              Text(
                state.errorText!,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBottomNav() {
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
              _navItem(Icons.home_rounded, 'Trang chủ', () => Navigator.of(context).popUntil((r) => r.isFirst)),
              _navItem(Icons.calendar_today_rounded, 'Đặt lịch', () {}),
              _navItem(Icons.map_outlined, 'Bản đồ', () {}),
              _navItem(Icons.person_outline_rounded, 'Cá nhân', () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback onTap) {
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
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
