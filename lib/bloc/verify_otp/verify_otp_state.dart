import 'package:equatable/equatable.dart';
import 'package:vehicle_registration_app/models/verify_otp_response.dart';

enum VerifyOtpStatus { initial, loading, success, failure }

class VerifyOtpState extends Equatable {
  const VerifyOtpState({
    this.status = VerifyOtpStatus.initial,
    this.message,
    this.response,
  });

  final VerifyOtpStatus status;
  final String? message;
  final VerifyOtpResponse? response;

  bool get isInitial => status == VerifyOtpStatus.initial;
  bool get isLoading => status == VerifyOtpStatus.loading;
  bool get isSuccess => status == VerifyOtpStatus.success;
  bool get isFailure => status == VerifyOtpStatus.failure;
  bool get isValid => response?.valid ?? false;

  VerifyOtpState copyWith({
    VerifyOtpStatus? status,
    String? message,
    VerifyOtpResponse? response,
  }) {
    return VerifyOtpState(
      status: status ?? this.status,
      message: message ?? this.message,
      response: response ?? this.response,
    );
  }

  @override
  List<Object?> get props => [status, message, response];
}
