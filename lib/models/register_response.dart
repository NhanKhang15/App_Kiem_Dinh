import 'package:equatable/equatable.dart';

/// Response từ POST /api/register/ (201 Created)
class RegisterResponse extends Equatable {
  const RegisterResponse({
    required this.success,
    this.message,
    this.token,
    this.userData,
  });

  final bool success;
  final String? message;
  final String? token;
  final Map<String, dynamic>? userData;

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      token: json['token'] as String?,
      userData: json['user_data'] as Map<String, dynamic>?,
    );
  }

  @override
  List<Object?> get props => [success, message, token, userData];
}
