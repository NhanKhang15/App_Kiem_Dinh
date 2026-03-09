import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vehicle_registration_app/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:vehicle_registration_app/bloc/verify_otp/verify_otp_event.dart';
import 'package:vehicle_registration_app/bloc/verify_otp/verify_otp_state.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.purpose = 'register',
  });

  /// Số điện thoại đã nhập ở màn Đăng ký (mã OTP đã gửi đến số này).
  final String phoneNumber;
  /// register | login
  final String purpose;

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  late bool isLoginTab;

  @override
  void initState() {
    super.initState();
    isLoginTab = widget.phoneNumber.isNotEmpty;
  }

  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  static const int _otpLength = 6;

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  String get _displayPhone => widget.phoneNumber.isEmpty ? '012345678' : widget.phoneNumber;

  /// [blocContext] phải là context nằm dưới BlocProvider<VerifyOtpBloc> (vd. từ Builder bên trong BlocConsumer).
  void _onConfirm(BuildContext blocContext) {
    final otp = _otpController.text.replaceAll(' ', '');
    if (otp.length != _otpLength) {
      ScaffoldMessenger.of(blocContext).showSnackBar(
        SnackBar(
          content: Text('Vui lòng nhập đủ $_otpLength số OTP'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    blocContext.read<VerifyOtpBloc>().add(
          VerifyOtpSubmitted(
            phone: widget.phoneNumber,
            otpCode: otp,
            purpose: widget.purpose,
          ),
        );
  }

  void _onResendOtp() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VerifyOtpBloc(),
      child: BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
        listener: (context, state) {
          if (state.isSuccess) {
            final otp = _otpController.text.replaceAll(' ', '');
            Navigator.pushReplacementNamed(context, '/registerPassword', arguments: {
              'phone': widget.phoneNumber,
              'otp_code': otp,
            });
          }
          if (state.isFailure && state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message!),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) => Scaffold(
      body: Builder(
        builder: (blocContext) => Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFE3F2FD)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // 1. Logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_shipping, color: Color(0xFF1D4ED8), size: 40),
              ),
              const SizedBox(height: 24),
              // 2. Tên ứng dụng & Slogan
              const Text(
                'Đăng Kiểm 360',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dịch vụ đăng kiểm chuyên nghiệp',
                style: TextStyle(fontSize: 14, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              // 3. Tab Switcher (Đăng nhập / Đăng ký)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabItem('Đăng nhập', !isLoginTab),
                    _buildTabItem('Đăng ký', isLoginTab),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 4. Card Xác thực OTP
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Xác thực OTP',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mã OTP đã được gửi đến',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _displayPhone,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Nhập mã OTP',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Ô nhập OTP (có thể nhập 6 số)
                    _buildOtpInput(),
                    const SizedBox(height: 24),
                    // Nút Xác nhận (gọi verify OTP trước khi chuyển màn)
                    ElevatedButton(
                      onPressed: state.isLoading ? null : () => _onConfirm(blocContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        state.isLoading ? 'Đang xác thực...' : 'Xác nhận',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Gửi lại mã
                    TextButton(
                      onPressed: _onResendOtp,
                      child: const Text(
                        'Gửi lại mã OTP',
                        style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 5. Điều khoản
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.5),
                    children: [
                      TextSpan(text: 'Bằng việc tiếp tục, bạn đồng ý với '),
                      TextSpan(text: 'Điều khoản', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                      TextSpan(text: ' và '),
                      TextSpan(text: 'Chính sách bảo mật', style: TextStyle(color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 6. Divider "Hoặc truy cập với vai trò"
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: Colors.white,
                    child: const Text(
                      'Hoặc truy cập với vai trò',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE5E7EB))),
                ],
              ),
              const SizedBox(height: 24),
              // 7. Role Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildRoleButton(
                      'Nhân viên',
                      const Color(0xFF059669),
                      '🤵',
                      () => Navigator.pushReplacementNamed(context, '/staffHome'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildRoleButton(
                      'Quản trị',
                      const Color(0xFF7C3AED),
                      '👩‍💻',
                      () => Navigator.pushReplacementNamed(context, '/bookingDashBoard'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      ),
    ),
  ),
  );
  }

  Widget _buildOtpInput() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: TextField(
          controller: _otpController,
          focusNode: _otpFocusNode,
          keyboardType: TextInputType.number,
          maxLength: _otpLength,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            letterSpacing: 8,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: List.filled(_otpLength, '0').join('  '),
            hintStyle: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
            counterText: '',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }

  Widget _buildTabItem(String title, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (title == 'Đăng nhập') {
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            setState(() => isLoginTab = true);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isActive ? const Color(0xFF1D4ED8) : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(String title, Color color, String emoji, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        shadowColor: color.withOpacity(0.4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}
