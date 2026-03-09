import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vehicle_registration_app/bloc/register/register_bloc.dart';
import 'package:vehicle_registration_app/bloc/register/register_event.dart';
import 'package:vehicle_registration_app/bloc/register/register_state.dart';

class RegisterPasswordScreen extends StatefulWidget {
  const RegisterPasswordScreen({
    super.key,
    required this.phoneNumber,
    required this.otpCode,
  });

  /// Số điện thoại đã verify OTP ở bước trước.
  final String phoneNumber;
  /// Mã OTP đã verify (gửi kèm khi đăng ký).
  final String otpCode;

  @override
  State<RegisterPasswordScreen> createState() => _RegisterPasswordScreenState();
}

class _RegisterPasswordScreenState extends State<RegisterPasswordScreen> {
  bool _isObscure1 = true;
  bool _isObscure2 = true;
  bool isRegisterTab = true;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onConfirm(BuildContext context) {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mật khẩu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (confirm.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng xác nhận mật khẩu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mật khẩu xác nhận không khớp'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    context.read<RegisterBloc>().add(
          RegisterSubmitted(
            phone: widget.phoneNumber,
            otpCode: widget.otpCode,
            password: password,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RegisterBloc(),
      child: BlocConsumer<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message ?? 'Đăng ký thành công'),
                backgroundColor: Colors.green.shade700,
              ),
            );
            Navigator.pushReplacementNamed(context, '/home');
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
      body: Container(
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
              // 3. Tab Switcher
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildTabItem('Đăng nhập', !isRegisterTab),
                    _buildTabItem('Đăng ký', isRegisterTab),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 4. Card Tạo tài khoản
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
                      'Tạo tài khoản mới',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    _buildPasswordField(
                      'Mật khẩu',
                      'Nhập mật khẩu',
                      _isObscure1,
                      _passwordController,
                      () => setState(() => _isObscure1 = !_isObscure1),
                    ),
                    const SizedBox(height: 20),
                    _buildPasswordField(
                      'Xác nhận mật khẩu',
                      'Xác nhận mật khẩu',
                      _isObscure2,
                      _confirmPasswordController,
                      () => setState(() => _isObscure2 = !_isObscure2),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state.isLoading ? null : () => _onConfirm(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        state.isLoading ? 'Đang xử lý...' : 'Xác nhận',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/otp', arguments: {
                          'phone': widget.phoneNumber,
                          'purpose': 'register',
                        });
                      },
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
              // 6. Divider Vai trò
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
    );
  }

  Widget _buildTabItem(String title, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (title == 'Đăng nhập') {
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            setState(() => isRegisterTab = true);
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

  Widget _buildPasswordField(
    String label,
    String hint,
    bool isObscure,
    TextEditingController controller,
    VoidCallback onToggle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: onToggle,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
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
