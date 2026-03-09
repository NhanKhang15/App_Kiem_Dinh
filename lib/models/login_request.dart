import 'package:equatable/equatable.dart';

/// Body gửi lên API đăng nhập (Admin/Staff: phone + password).
class LoginRequest extends Equatable {
  const LoginRequest({
    required this.phone,
    required this.password,
  });

  /// Số điện thoại đăng nhập (phone).
  final String phone;
  final String password;

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'password': password,
      };

  @override
  List<Object?> get props => [phone, password];
}
