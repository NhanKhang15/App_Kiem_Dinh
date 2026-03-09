import 'package:equatable/equatable.dart';

/// Model dữ liệu user trả về từ API đăng nhập.
class UserModel extends Equatable {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.isSuperuser = false,
    this.isStaff = false,
  });

  final int id;
  final String username;
  final String email;
  final bool isSuperuser;
  final bool isStaff;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return UserModel(
      id: id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      isSuperuser: json['is_superuser'] as bool? ?? false,
      isStaff: json['is_staff'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'is_superuser': isSuperuser,
        'is_staff': isStaff,
      };

  /// Admin: vừa superuser vừa staff (theo spec).
  bool get isAdmin => isSuperuser && isStaff;

  /// Chỉ là staff (không phải superuser).
  bool get isStaffOnly => isStaff && !isSuperuser;

  @override
  List<Object?> get props => [id, username, email, isSuperuser, isStaff];
}
