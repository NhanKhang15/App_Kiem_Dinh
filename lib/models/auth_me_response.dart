import 'package:equatable/equatable.dart';

/// User object trong response GET /api/auth/me/
class AuthMeUser extends Equatable {
  const AuthMeUser({
    required this.id,
    required this.username,
    this.email,
    this.isStaff = false,
    this.isSuperuser = false,
  });

  final int id;
  final String username;
  final String? email;
  final bool isStaff;
  final bool isSuperuser;

  factory AuthMeUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return AuthMeUser(
      id: id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0,
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      isStaff: json['is_staff'] as bool? ?? false,
      isSuperuser: json['is_superuser'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, username, email, isStaff, isSuperuser];
}

/// Role object trong profile Staff (GET /api/auth/me/)
class AuthMeStaffRole extends Equatable {
  const AuthMeStaffRole({
    required this.id,
    required this.name,
    required this.code,
  });

  final int id;
  final String name;
  final String code;

  factory AuthMeStaffRole.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return AuthMeStaffRole(
      id: id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name, code];
}

/// Profile trong GET /api/auth/me/ — dùng chung cho Customer và Staff.
/// Customer: full_name, phone, address, city, ...; Staff: full_name, phone, employee_code, role, position, ...
class AuthMeProfile extends Equatable {
  const AuthMeProfile({
    this.id,
    this.fullName,
    this.phone,
    this.avatarUrl,
    // Customer
    this.dateOfBirth,
    this.gender,
    this.address,
    this.city,
    this.district,
    this.ward,
    this.phoneVerified,
    this.emailVerified,
    this.totalOrders,
    this.completedOrders,
    this.totalSpent,
    this.loyaltyPoints,
    this.membershipTier,
    this.createdAt,
    // Staff
    this.employeeCode,
    this.role,
    this.position,
    this.ratingAverage,
    this.tasksTotal,
    this.tasksCompleted,
    this.status,
  });

  final int? id;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? city;
  final String? district;
  final String? ward;
  final bool? phoneVerified;
  final bool? emailVerified;
  final int? totalOrders;
  final int? completedOrders;
  final String? totalSpent;
  final int? loyaltyPoints;
  final String? membershipTier;
  final String? createdAt;
  final String? employeeCode;
  final AuthMeStaffRole? role;
  final String? position;
  final String? ratingAverage;
  final int? tasksTotal;
  final int? tasksCompleted;
  final String? status;

  factory AuthMeProfile.fromJson(Map<String, dynamic> json) {
    final roleJson = json['role'];
    return AuthMeProfile(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? ''),
      fullName: json['full_name']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString(),
      gender: json['gender']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      district: json['district']?.toString(),
      ward: json['ward']?.toString(),
      phoneVerified: json['phone_verified'] as bool?,
      emailVerified: json['email_verified'] as bool?,
      totalOrders: json['total_orders'] is int ? json['total_orders'] as int : int.tryParse(json['total_orders']?.toString() ?? ''),
      completedOrders: json['completed_orders'] is int ? json['completed_orders'] as int : int.tryParse(json['completed_orders']?.toString() ?? ''),
      totalSpent: json['total_spent']?.toString(),
      loyaltyPoints: json['loyalty_points'] is int ? json['loyalty_points'] as int : int.tryParse(json['loyalty_points']?.toString() ?? ''),
      membershipTier: json['membership_tier']?.toString(),
      createdAt: json['created_at']?.toString(),
      employeeCode: json['employee_code']?.toString(),
      role: roleJson is Map<String, dynamic> ? AuthMeStaffRole.fromJson(roleJson) : null,
      position: json['position']?.toString(),
      ratingAverage: json['rating_average']?.toString(),
      tasksTotal: json['tasks_total'] is int ? json['tasks_total'] as int : int.tryParse(json['tasks_total']?.toString() ?? ''),
      tasksCompleted: json['tasks_completed'] is int ? json['tasks_completed'] as int : int.tryParse(json['tasks_completed']?.toString() ?? ''),
      status: json['status']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id, fullName, phone, avatarUrl,
        dateOfBirth, gender, address, city, district, ward,
        phoneVerified, emailVerified, totalOrders, completedOrders, totalSpent, loyaltyPoints, membershipTier, createdAt,
        employeeCode, role, position, ratingAverage, tasksTotal, tasksCompleted, status,
      ];
}

/// Response GET /api/auth/me/ — hỗ trợ Customer và Staff (user_type khác nhau, profile structure khác).
class AuthMeResponse extends Equatable {
  const AuthMeResponse({
    required this.userType,
    required this.user,
    this.profile,
  });

  final String userType;
  final AuthMeUser user;
  final AuthMeProfile? profile;

  bool get isCustomer => userType.toLowerCase() == 'customer';
  bool get isStaff => userType.toLowerCase() == 'staff';

  factory AuthMeResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    final profileJson = json['profile'];
    return AuthMeResponse(
      userType: json['user_type']?.toString() ?? 'customer',
      user: userJson is Map<String, dynamic> ? AuthMeUser.fromJson(userJson) : const AuthMeUser(id: 0, username: ''),
      profile: profileJson is Map<String, dynamic> ? AuthMeProfile.fromJson(profileJson) : null,
    );
  }

  @override
  List<Object?> get props => [userType, user, profile];
}
