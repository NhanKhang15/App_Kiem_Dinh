import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

/// Bắt đầu đăng nhập bằng username + password (Admin).
class LoginSubmitted extends LoginEvent {
  const LoginSubmitted({required this.phone, required this.password});

  /// Số điện thoại đăng nhập.
  final String phone;
  final String password;

  @override
  List<Object?> get props => [phone, password];
}
