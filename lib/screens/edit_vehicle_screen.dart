import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/screens/add_vehicle_screen.dart';
import 'package:vehicle_registration_app/services/vehicle_service.dart';
import 'package:vehicle_registration_app/widgets/app_header_with_back.dart';

class EditVehicleScreen extends StatefulWidget {
  const EditVehicleScreen({super.key, required this.vehicleId});

  final int vehicleId;

  @override
  State<EditVehicleScreen> createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final VehicleService _vehicleService = VehicleService();
  final _formKey = GlobalKey<FormState>();
  final _licenseController = TextEditingController();
  final _brandController = TextEditingController();
  final _colorController = TextEditingController();

  int? _selectedVehicleTypeId;
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  final _vehicleTypeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadVehicle();
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicle() async {
    setState(() => _loading = true);
    try {
      final data = await _vehicleService.getVehicle(widget.vehicleId);
      if (!mounted) return;
      _licenseController.text = data['license_plate']?.toString() ?? '';
      _brandController.text = _brandModelFromResponse(data);
      _colorController.text = data['color']?.toString() ?? '';
      final vt = data['vehicle_type'];
      if (vt is int) {
        _selectedVehicleTypeId = vt;
      } else if (vt is Map) {
        final id = vt['id'];
        if (id is int) _selectedVehicleTypeId = id;
      }
      if (_selectedVehicleTypeId == null) _selectedVehicleTypeId = 3;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = 'Không tải được thông tin xe.';
      });
    }
  }

  String _brandModelFromResponse(Map<String, dynamic> data) {
    final brand = data['brand']?.toString() ?? '';
    final model = data['model']?.toString() ?? '';
    if (brand.isEmpty && model.isEmpty) return '';
    if (model.isEmpty) return brand;
    return '$brand $model'.trim();
  }

  Future<void> _submit() async {
    _errorMessage = null;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    final brandText = _brandController.text.trim();
    final parts = brandText.isNotEmpty ? brandText.split(RegExp(r'\s+')) : <String>[];
    final brand = parts.isNotEmpty ? parts.first : null;
    final model = parts.length > 1 ? parts.sublist(1).join(' ') : (parts.length == 1 ? null : null);
    final body = <String, dynamic>{};
    if (_selectedVehicleTypeId != null) body['vehicle_type'] = _selectedVehicleTypeId!;
    if (brand != null) body['brand'] = brand;
    if (model != null) body['model'] = model;
    body['color'] = _colorController.text.trim();

    try {
      await _vehicleService.updateVehicle(widget.vehicleId, body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật xe thành công.'), backgroundColor: Color(0xFF16A34A)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      String msg = 'Cập nhật thất bại. Thử lại sau.';
      if (e is DioException && e.response?.statusCode == 400) {
        final data = e.response?.data;
        if (data is Map && data['detail'] != null) msg = data['detail'].toString();
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
              title: 'Chỉnh sửa xe',
              subtitle: 'Nhập thông tin xe của bạn',
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF3B5BF5)),
                    )
                  : SingleChildScrollView(
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
                                readOnly: true,
                                decoration: _inputDecoration('VD: 29A-12345').copyWith(
                                  fillColor: Colors.grey.shade200,
                                ),
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
                                          'Cập nhật',
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
              _navItem(Icons.home_rounded, 'Trang chủ',
                  () => Navigator.of(context).popUntil((r) => r.isFirst)),
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
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }
}
