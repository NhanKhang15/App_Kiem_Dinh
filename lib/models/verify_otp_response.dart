import 'package:equatable/equatable.dart';

/// Response từ POST /api/auth/verify-otp/
class VerifyOtpResponse extends Equatable {
  const VerifyOtpResponse({
    required this.success,
    this.valid = false,
    this.message,
    this.errorCode,
  });

  final bool success;
  final bool valid;
  final String? message;
  final String? errorCode;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      success: json['success'] as bool? ?? false,
      valid: json['valid'] as bool? ?? false,
      message: json['message'] as String?,
      errorCode: json['error_code'] as String?,
    );
  }

  @override
  List<Object?> get props => [success, valid, message, errorCode];
}
