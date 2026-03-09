import 'package:equatable/equatable.dart';

/// Body gửi lên POST /api/auth/verify-otp/
class VerifyOtpRequest extends Equatable {
  const VerifyOtpRequest({
    required this.phone,
    required this.otpCode,
    required this.purpose,
  });

  final String phone;
  final String otpCode;
  /// register | login
  final String purpose;

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'otp_code': otpCode,
        'purpose': purpose,
      };

  @override
  List<Object?> get props => [phone, otpCode, purpose];
}
