import 'package:equatable/equatable.dart';

abstract class RequestOtpEvent extends Equatable {
  const RequestOtpEvent();

  @override
  List<Object?> get props => [];
}

/// Gửi yêu cầu OTP (purpose: login | register | reset_password).
class RequestOtpSubmitted extends RequestOtpEvent {
  const RequestOtpSubmitted({
    required this.phone,
    required this.purpose,
  });

  final String phone;
  final String purpose;

  @override
  List<Object?> get props => [phone, purpose];
}
