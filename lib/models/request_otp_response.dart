import 'package:equatable/equatable.dart';

/// Response từ POST /api/auth/request-otp/
class RequestOtpResponse extends Equatable {
  const RequestOtpResponse({
    required this.success,
    this.message,
    this.otpCode,
    this.expiresAt,
  });

  final bool success;
  final String? message;
  /// Chỉ có trong môi trường dev (response trả về debug_otp); production không trả về.
  final String? otpCode;
  final String? expiresAt;

  factory RequestOtpResponse.fromJson(Map<String, dynamic> json) {
    return RequestOtpResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      otpCode: json['debug_otp'] as String? ?? json['otp_code'] as String?,
      expiresAt: json['expires_at'] as String?,
    );
  }

  @override
  List<Object?> get props => [success, message, otpCode, expiresAt];
}
