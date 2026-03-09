import 'package:equatable/equatable.dart';

/// Body gửi lên POST /api/auth/request-otp/
class RequestOtpRequest extends Equatable {
  const RequestOtpRequest({
    required this.phone,
    required this.purpose,
  });

  final String phone;
  /// login | register | reset_password
  final String purpose;

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'purpose': purpose,
      };

  @override
  List<Object?> get props => [phone, purpose];
}
