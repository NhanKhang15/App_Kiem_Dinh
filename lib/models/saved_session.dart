import 'package:equatable/equatable.dart';

/// Phiên đăng nhập đã lưu (SharedPreferences) — dùng để restore khi mở lại app.
class SavedSession extends Equatable {
  const SavedSession({
    required this.token,
    required this.userType,
    this.userId,
    this.username,
    this.email,
    this.isSuperuser = false,
    this.isStaff = false,
  });

  final String token;
  final String userType;
  final int? userId;
  final String? username;
  final String? email;
  final bool isSuperuser;
  final bool isStaff;

  /// Route theo user_type từ API: admin → bookingDashBoard, staff → staffHome, customer → home.
  String get route {
    final type = userType.toLowerCase();
    if (type == 'admin') return '/bookingDashBoard';
    if (type == 'staff') return '/staffHome';
    return '/home';
  }

  @override
  List<Object?> get props => [token, userType, userId, username, email, isSuperuser, isStaff];
}
