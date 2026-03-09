import 'package:equatable/equatable.dart';

/// Body gửi lên POST /api/register/
class RegisterRequest extends Equatable {
  const RegisterRequest({
    required this.phone,
    required this.otpCode,
    required this.password,
    this.fullName,
    this.email,
  });

  final String phone;
  final String otpCode;
  final String password;
  final String? fullName;
  final String? email;

  /// Gửi phone, otp_code, password. full_name và email để trống (chuỗi rỗng) khi chưa có.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phone': phone.trim(),
      'otp_code': otpCode,
      'password': password,
      'full_name': (fullName != null && fullName!.trim().isNotEmpty) ? fullName!.trim() : '',
      'email': (email != null && email!.trim().isNotEmpty) ? email!.trim() : '',
    };
  }

  @override
  List<Object?> get props => [phone, otpCode, password, fullName, email];
}
