import 'package:equatable/equatable.dart';
import 'package:vehicle_registration_app/models/user_model.dart';

/// Response từ API POST /api/login/
class LoginResponse extends Equatable {
  const LoginResponse({
    required this.success,
    this.message,
    this.token,
    this.userType,
    this.userData,
  });

  final bool success;
  final String? message;
  final String? token;
  final String? userType;
  final UserModel? userData;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      token: json['token'] as String?,
      userType: json['user_type'] as String?,
      userData: json['user_data'] != null
          ? UserModel.fromJson(json['user_data'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [success, message, token, userType, userData];
}
