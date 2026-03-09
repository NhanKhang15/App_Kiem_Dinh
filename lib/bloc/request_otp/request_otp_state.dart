import 'package:equatable/equatable.dart';
import 'package:vehicle_registration_app/models/request_otp_response.dart';

enum RequestOtpStatus { initial, loading, success, failure }

class RequestOtpState extends Equatable {
  const RequestOtpState({
    this.status = RequestOtpStatus.initial,
    this.message,
    this.response,
    this.phone,
  });

  final RequestOtpStatus status;
  final String? message;
  final RequestOtpResponse? response;
  /// Số điện thoại khi gửi OTP thành công (để điều hướng sang màn OTP).
  final String? phone;

  bool get isInitial => status == RequestOtpStatus.initial;
  bool get isLoading => status == RequestOtpStatus.loading;
  bool get isSuccess => status == RequestOtpStatus.success;
  bool get isFailure => status == RequestOtpStatus.failure;

  RequestOtpState copyWith({
    RequestOtpStatus? status,
    String? message,
    RequestOtpResponse? response,
    String? phone,
  }) {
    return RequestOtpState(
      status: status ?? this.status,
      message: message ?? this.message,
      response: response ?? this.response,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [status, message, response, phone];
}
