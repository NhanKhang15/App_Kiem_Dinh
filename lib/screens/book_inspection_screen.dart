import 'package:flutter/material.dart';
import 'package:vehicle_registration_app/models/station_model.dart';
import 'package:vehicle_registration_app/models/vehicle_model.dart';
import 'package:vehicle_registration_app/services/auth_service.dart';
import 'package:vehicle_registration_app/services/station_service.dart';
import 'package:vehicle_registration_app/services/vehicle_service.dart';
import 'package:vehicle_registration_app/screens/add_vehicle_screen.dart';
import 'package:vehicle_registration_app/widgets/app_header_with_back.dart';

final List<String> kTimeSlots = ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'];

class BookInspectionScreen extends StatefulWidget {
  const BookInspectionScreen({super.key, this.preSelectedVehicle});

  final VehicleModel? preSelectedVehicle;

  @override
  State<BookInspectionScreen> createState() => _BookInspectionScreenState();
}

class _BookInspectionScreenState extends State<BookInspectionScreen> {
  final VehicleService _vehicleService = VehicleService();
  final AuthService _authService = AuthService();
  final StationService _stationService = StationService();
  int _step = 1;
  List<VehicleModel> _vehicles = [];
  bool _vehiclesLoading = true;
  VehicleModel? _selectedVehicle;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isModified = false;
  List<StationModel> _stations = [];
  bool _stationsLoading = true;
  StationModel? _selectedStation;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  String? _selectedTime = '09:00';

  @override
  void initState() {
    super.initState();
    _loadMe();
    _loadVehicles();
    _loadStations();
    if (widget.preSelectedVehicle != null) _selectedVehicle = widget.preSelectedVehicle;
  }

  Future<void> _loadStations() async {
    setState(() => _stationsLoading = true);
    try {
      final res = await _stationService.getStations(status: 'active');
      if (!mounted) return;
      setState(() {
        _stations = res.results;
        _stationsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _stationsLoading = false);
    }
  }

  /// Nạp thông tin user từ GET /api/auth/me/ và điền Họ tên, SĐT (Customer/Staff đều có profile.full_name, profile.phone).
  Future<void> _loadMe() async {
    try {
      final me = await _authService.getMe();
      if (!mounted) return;
      final profile = me.profile;
      final name = profile?.fullName?.trim();
      final phone = profile?.phone?.trim() ?? me.user.username;
      if (name != null && name.isNotEmpty) _nameController.text = name;
      if (phone != null && phone.isNotEmpty) _phoneController.text = phone;
    } catch (_) {
      // Bỏ qua: giữ ô trống hoặc user tự nhập (401 sẽ bị interceptor đẩy về login).
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() => _vehiclesLoading = true);
    try {
      final res = await _vehicleService.getVehicles();
      if (!mounted) return;
      setState(() {
        _vehicles = res.results;
        _vehiclesLoading = false;
        if (_selectedVehicle == null && _vehicles.isNotEmpty) _selectedVehicle = _vehicles.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _vehiclesLoading = false);
    }
  }

  String get _stepTitle {
    switch (_step) {
      case 1: return 'Bước 1/3: Thông tin xe & liên hệ';
      case 2: return 'Bước 2/3: Chọn trạm';
      case 3: return 'Bước 3/3: Chọn thời gian';
      default: return '';
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
            AppHeaderWithBack(
              title: 'Đặt lịch đăng kiểm',
              subtitle: _stepTitle,
              onBack: () {
                if (_step > 1) setState(() => _step--);
                else Navigator.of(context).pop();
              },
              bottom: Row(
                children: List.generate(3, (i) {
                  final active = (i + 1) <= _step;
                  return Container(
                    margin: EdgeInsets.only(left: i == 0 ? 0 : 6),
                    width: 28,
                    height: 4,
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF3B5BF5) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: _step == 1 ? _buildStep1() : _step == 2 ? _buildStep2() : _buildStep3(),
              ),
            ),
            _buildBottomButton(),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          icon: Icons.directions_car_outlined,
          iconColor: const Color(0xFF3B5BF5),
          title: 'Chọn xe đăng kiểm',
          child: _vehiclesLoading
              ? const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Color(0xFF3B5BF5))))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._vehicles.map((v) => _vehicleRadio(v)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddVehicleScreen()));
                        if (added == true && mounted) _loadVehicles();
                      },
                      child: const Center(
                        child: Text('+ Thêm xe mới', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3B5BF5))),
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          icon: Icons.person_outline_rounded,
          iconColor: const Color(0xFF16A34A),
          title: 'Thông tin liên hệ',
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: _inputDeco('Họ và tên'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: _inputDeco('Số điện thoại'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          title: 'Tình trạng xe',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isModified,
                      onChanged: (v) => setState(() => _isModified = v ?? false),
                      activeColor: const Color(0xFF3B5BF5),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Xe có độ/cải tạo',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 34),
                child: Text(
                  'Xe đã qua cải tạo, độ pô, nâng cấp động cơ hoặc thay đổi kết cấu',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _vehicleRadio(VehicleModel v) {
    final selected = _selectedVehicle?.id == v.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicle = v),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFF3B5BF5) : Colors.grey.shade300!, width: selected ? 2 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? const Color(0xFF3B5BF5) : Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.licensePlate, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                  Text(v.vehicleTypeName, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.send_rounded, color: Colors.blue.shade700, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trạm gần bạn nhất', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    Text('Các trạm được sắp xếp theo khoảng cách từ vị trí hiện tại', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_stationsLoading)
          const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator(color: Color(0xFF3B5BF5))))
        else if (_stations.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Không có trạm nào.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          )
        else
          ..._stations.map((s) => _stationCard(s)),
      ],
    );
  }

  Widget _stationCard(StationModel s) {
    final selected = _selectedStation?.id == s.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedStation = s),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(s.stationName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                ),
                if (selected) const Icon(Icons.check_circle, color: Color(0xFF3B5BF5), size: 24),
              ],
            ),
            if (s.stationCode.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(s.stationCode, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
            if (s.address != null && s.address!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(child: Text(s.address!, style: TextStyle(fontSize: 13, color: Colors.grey.shade700))),
                ],
              ),
            ],
            if (s.hoursDisplay != null && s.hoursDisplay!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(s.hoursDisplay!, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    final dateStr = '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          icon: Icons.calendar_today_rounded,
          iconColor: const Color(0xFF7C3AED),
          title: 'Chọn ngày',
          child: GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Text(dateStr, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
                  const Spacer(),
                  Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _sectionCard(
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF3B5BF5),
          title: 'Chọn giờ',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kTimeSlots.map((t) {
              final selected = _selectedTime == t;
              return GestureDetector(
                onTap: () => setState(() => _selectedTime = t),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF3B5BF5) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? Colors.white : const Color(0xFF111827))),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3B5BF5), Color(0xFF6366F1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Tóm tắt đặt lịch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              _summaryRow('Xe:', _selectedVehicle?.licensePlate ?? '—'),
              _summaryRow('Liên hệ:', _nameController.text.trim().isEmpty ? '—' : _nameController.text.trim()),
              _summaryRow('Trạm:', _selectedStation?.stationName ?? '—'),
              _summaryRow('Thời gian:', '$_selectedTime - ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.9))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _sectionCard({IconData? icon, Color? iconColor, required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? const Color(0xFF3B5BF5), size: 20),
                const SizedBox(width: 8),
              ],
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF3F4F6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  void _onContinue() {
    if (_step == 2 && _selectedStation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn trạm'), backgroundColor: Color(0xFFDC2626)),
      );
      return;
    }
    if (_step < 3) setState(() => _step++);
    else _confirmBooking();
  }

  Widget _buildBottomButton() {
    final isLastStep = _step == 3;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B5BF5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(isLastStep ? 'Xác nhận đặt lịch' : 'Tiếp tục', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đặt lịch thành công. Chức năng gửi API đang phát triển.'), backgroundColor: Color(0xFF16A34A)),
    );
    Navigator.of(context).pop(true);
  }

  Widget _buildBottomNav() {
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
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}
