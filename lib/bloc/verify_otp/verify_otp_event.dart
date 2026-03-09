import 'package:equatable/equatable.dart';

abstract class VerifyOtpEvent extends Equatable {
  const VerifyOtpEvent();

  @override
  List<Object?> get props => [];
}

/// Gửi verify OTP (phone + otp_code + purpose).
class VerifyOtpSubmitted extends VerifyOtpEvent {
  const VerifyOtpSubmitted({
    required this.phone,
    required this.otpCode,
    required this.purpose,
  });

  final String phone;
  final String otpCode;
  final String purpose;

  @override
  List<Object?> get props => [phone, otpCode, purpose];
}
