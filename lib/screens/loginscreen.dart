import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vehicle_registration_app/bloc/login/login_bloc.dart';
import 'package:vehicle_registration_app/bloc/login/login_event.dart';
import 'package:vehicle_registration_app/bloc/login/login_state.dart';
import 'package:vehicle_registration_app/bloc/request_otp/request_otp_bloc.dart';
import 'package:vehicle_registration_app/bloc/request_otp/request_otp_event.dart';
import 'package:vehicle_registration_app/bloc/request_otp/request_otp_state.dart';
import 'package:vehicle_registration_app/models/login_response.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _obscurePassword = true;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _registerPhoneController.dispose();
    super.dispose();
  }

  /// Điều hướng theo user_type từ API: customer → Home, staff → StaffHome, admin → BookingDashboard.
  void _navigateByRole(BuildContext context, LoginResponse response) {
    final userType = (response.userType ?? '').toLowerCase();
    if (userType == 'admin') {
      Navigator.pushReplacementNamed(context, '/bookingDashBoard');
      return;
    }
    if (userType == 'staff') {
      Navigator.pushReplacementNamed(context, '/staffHome');
      return;
    }
    // customer hoặc mặc định
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => LoginBloc()),
        BlocProvider(create: (_) => RequestOtpBloc()),
      ],
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        resizeToAvoidBottomInset: true,
        body: BlocListener<RequestOtpBloc, RequestOtpState>(
          listener: (context, state) {
            if (state.isSuccess && state.phone != null) {
              Navigator.pushNamed(context, '/otp', arguments: {
                'phone': state.phone!,
                'purpose': 'register',
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
          child: BlocConsumer<LoginBloc, LoginState>(
            listener: (context, state) {
              if (state.isSuccess && state.loginResponse != null) {
                _navigateByRole(context, state.loginResponse!);
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
            builder: (context, state) => SafeArea(
            child: Column(
              children: [
                // ── Fixed header + tab bar ─────────────────────────────
                Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('🚛', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Đăng Kiểm 360',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dịch vụ đăng kiểm chuyên nghiệp',
                    style:
                    TextStyle(fontSize: 14, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(height: 24),

                  // Tab switcher
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8EDF5),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: const Color(0xFF1A1A2E),
                      unselectedLabelColor: const Color(0xFF6B7280),
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15),
                      unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15),
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Đăng nhập'),
                        Tab(text: 'Đăng ký'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

                // ── Scrollable TabBarView ──────────────────────────────
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildScrollable(_buildLoginTab()),
                      _buildScrollable(_buildRegisterTab()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  /// Wraps content in SingleChildScrollView to prevent overflow
  Widget _buildScrollable(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      physics: const ClampingScrollPhysics(),
      child: child,
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  LOGIN TAB
  // ──────────────────────────────────────────────────────────────
  Widget _buildLoginTab() {
    return BlocBuilder<LoginBloc, LoginState>(
      builder: (context, state) {
        final isLoading = state.isLoading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Chọn phương thức đăng nhập',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151)),
              ),
            ),
            const SizedBox(height: 14),
            _buildSocialButton(
              icon: _googleIcon(),
              label: 'Google',
              bgColor: Colors.white,
              textColor: const Color(0xFF374151),
              borderColor: const Color(0xFFD1D5DB),
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _buildSocialButton(
              icon: const Icon(Icons.facebook, color: Colors.white, size: 22),
              label: 'Facebook',
              bgColor: const Color(0xFF1877F2),
              textColor: Colors.white,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _buildSocialButton(
              icon: const Icon(Icons.apple, color: Colors.white, size: 24),
              label: 'Apple',
              bgColor: const Color(0xFF1A1A1A),
              textColor: Colors.white,
              onTap: () {},
            ),
            _buildDividerLabel('Hoặc SĐT + Mật khẩu'),
            const Text('Số điện thoại',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _phoneController,
              hint: 'Nhập số điện thoại',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            const Text('Mật khẩu',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _passwordController,
              hint: 'Nhập mật khẩu',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey.shade400,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 20),
            _buildPrimaryButton(
              label: isLoading ? 'Đang đăng nhập...' : 'Đăng nhập',
              onTap: isLoading
                  ? () {}
                  : () {
                      context.read<LoginBloc>().add(
                            LoginSubmitted(
                              phone: _phoneController.text.trim(),
                              password: _passwordController.text,
                            ),
                          );
                    },
            ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: () {},
            child: const Text(
              'Quên mật khẩu?',
              style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _buildTermsText(),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFDDE3EF)),
        _buildPartnerRow(),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Hoặc truy cập với vai trò',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ),
            const SizedBox(height: 12),
            _buildRoleButtons(),
          ],
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  REGISTER TAB
  // ──────────────────────────────────────────────────────────────
  Widget _buildRegisterTab() {
    return BlocBuilder<RequestOtpBloc, RequestOtpState>(
      builder: (context, otpState) {
        final otpLoading = otpState.isLoading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Tạo tài khoản mới',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151)),
              ),
            ),
            const SizedBox(height: 14),
            _buildSocialButton(
              icon: _googleIcon(),
              label: 'Google',
              bgColor: Colors.white,
              textColor: const Color(0xFF374151),
              borderColor: const Color(0xFFD1D5DB),
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _buildSocialButton(
              icon: const Icon(Icons.facebook, color: Colors.white, size: 22),
              label: 'Facebook',
              bgColor: const Color(0xFF1877F2),
              textColor: Colors.white,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _buildSocialButton(
              icon: const Icon(Icons.apple, color: Colors.white, size: 24),
              label: 'Apple',
              bgColor: const Color(0xFF1A1A1A),
              textColor: Colors.white,
              onTap: () {},
            ),
            _buildDividerLabel('Hoặc SĐT + OTP'),
            const Text('Số điện thoại',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151))),
            const SizedBox(height: 6),
            _buildTextField(
              controller: _registerPhoneController,
              hint: 'Nhập số điện thoại',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _buildPrimaryButton(
              label: otpLoading ? 'Đang gửi mã OTP...' : 'Gửi mã OTP',
              onTap: otpLoading
                  ? () {}
                  : () {
                      context.read<RequestOtpBloc>().add(
                            RequestOtpSubmitted(
                              phone: _registerPhoneController.text.trim(),
                              purpose: 'register',
                            ),
                          );
                    },
            ),
        const SizedBox(height: 14),
        _buildTermsText(),
        const SizedBox(height: 20),
        const Divider(color: Color(0xFFDDE3EF)),
        _buildPartnerRow(),
        const SizedBox(height: 4),
        const Center(
          child: Text(
            'Hoặc truy cập với vai trò',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
        ),
            const SizedBox(height: 12),
            _buildRoleButtons(),
          ],
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  SHARED WIDGETS
  // ──────────────────────────────────────────────────────────────

  Widget _buildDividerLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFD1D5DB))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label,
                style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
          const Expanded(child: Divider(color: Color(0xFFD1D5DB))),
        ],
      ),
    );
  }

  Widget _buildPartnerRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {},
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.play_arrow, size: 14, color: Color(0xFF6B7280)),
            SizedBox(width: 4),
            Text('Bạn có mã đối tác?',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          children: [
            TextSpan(text: 'Bằng việc tiếp tục, bạn đồng ý với '),
            TextSpan(
              text: 'Điều khoản',
              style: TextStyle(
                  color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
            ),
            TextSpan(text: ' và '),
            TextSpan(
              text: 'Chính sách bảo mật',
              style: TextStyle(
                  color: Color(0xFF2563EB), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildRoleButton(
            label: '🧑‍💼  Nhân viên',
            fromColor: const Color(0xFF16A34A),
            toColor: const Color(0xFF15803D),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/staffHome');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildRoleButton(
            label: '👨‍💻  Quản trị',
            fromColor: const Color(0xFF7C3AED),
            toColor: const Color(0xFF6D28D9),
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _googleIcon() {
    return SvgPicture.asset(
      'assets/icons/google_g_logo.svg',
      width: 24,
      height: 24,
      fit: BoxFit.contain,
    );
  }

  Widget _buildSocialButton({
    required Widget icon,
    required String label,
    required Color bgColor,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap:() {
        Navigator.pushReplacementNamed(context, '/home');
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null ? Border.all(color: borderColor, width: 1) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
          Icon(prefixIcon, color: Colors.grey.shade400, size: 20),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
            const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildRoleButton({
    required String label,
    required Color fromColor,
    required Color toColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [fromColor, toColor]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: fromColor.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}