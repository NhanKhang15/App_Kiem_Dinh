import 'package:equatable/equatable.dart';
import 'package:vehicle_registration_app/models/login_response.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  const LoginState({
    this.status = LoginStatus.initial,
    this.message,
    this.loginResponse,
  });

  final LoginStatus status;
  final String? message;
  final LoginResponse? loginResponse;

  bool get isInitial => status == LoginStatus.initial;
  bool get isLoading => status == LoginStatus.loading;
  bool get isSuccess => status == LoginStatus.success;
  bool get isFailure => status == LoginStatus.failure;

  LoginState copyWith({
    LoginStatus? status,
    String? message,
    LoginResponse? loginResponse,
  }) {
    return LoginState(
      status: status ?? this.status,
      message: message ?? this.message,
      loginResponse: loginResponse ?? this.loginResponse,
    );
  }

  @override
  List<Object?> get props => [status, message, loginResponse];
}
