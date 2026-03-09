import 'package:equatable/equatable.dart';

abstract class RegisterEvent extends Equatable {
  const RegisterEvent();

  @override
  List<Object?> get props => [];
}

/// Gửi đăng ký (phone + otp_code + password, optional fullName, email).
class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted({
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

  @override
  List<Object?> get props => [phone, otpCode, password, fullName, email];
}
