import 'package:equatable/equatable.dart';
import 'package:vehicle_registration_app/models/register_response.dart';

enum RegisterStatus { initial, loading, success, failure }

class RegisterState extends Equatable {
  const RegisterState({
    this.status = RegisterStatus.initial,
    this.message,
    this.response,
  });

  final RegisterStatus status;
  final String? message;
  final RegisterResponse? response;

  bool get isInitial => status == RegisterStatus.initial;
  bool get isLoading => status == RegisterStatus.loading;
  bool get isSuccess => status == RegisterStatus.success;
  bool get isFailure => status == RegisterStatus.failure;

  RegisterState copyWith({
    RegisterStatus? status,
    String? message,
    RegisterResponse? response,
  }) {
    return RegisterState(
      status: status ?? this.status,
      message: message ?? this.message,
      response: response ?? this.response,
    );
  }

  @override
  List<Object?> get props => [status, message, response];
}
