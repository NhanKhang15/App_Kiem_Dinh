import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_registration_app/models/login_response.dart';
import 'package:vehicle_registration_app/models/register_response.dart';
import 'package:vehicle_registration_app/models/saved_session.dart';
import 'package:vehicle_registration_app/services/api_client.dart';

/// Lưu/đọc phiên đăng nhập (token + thông tin user) bằng SharedPreferences.
class AuthStorage {
  AuthStorage._();

  static const _keyToken = 'auth_token';
  static const _keyUserType = 'auth_user_type';
  static const _keyUserId = 'auth_user_id';
  static const _keyUsername = 'auth_username';
  static const _keyEmail = 'auth_email';
  static const _keyIsSuperuser = 'auth_is_superuser';
  static const _keyIsStaff = 'auth_is_staff';

  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _prefsAsync async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Gọi khi app khởi động (main). Bỏ qua lỗi nếu plugin chưa sẵn sàng (vd. hot restart sau khi thêm plugin).
  static Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (_) {
      _prefs = null;
    }
  }

  /// Lưu phiên từ response đăng nhập (customer / staff / admin).
  static Future<void> saveLogin(LoginResponse response) async {
    if (response.token == null || response.token!.isEmpty) return;
    try {
      final prefs = await _prefsAsync;
      await prefs.setString(_keyToken, response.token!);
      await prefs.setString(_keyUserType, response.userType ?? 'customer');
      final u = response.userData;
      if (u != null) {
        await prefs.setInt(_keyUserId, u.id);
        await prefs.setString(_keyUsername, u.username);
        await prefs.setString(_keyEmail, u.email);
        await prefs.setBool(_keyIsSuperuser, u.isSuperuser);
        await prefs.setBool(_keyIsStaff, u.isStaff);
      } else {
        await prefs.remove(_keyUserId);
        await prefs.remove(_keyUsername);
        await prefs.remove(_keyEmail);
        final type = (response.userType ?? '').toLowerCase();
        await prefs.setBool(_keyIsSuperuser, type == 'admin');
        await prefs.setBool(_keyIsStaff, type == 'staff' || type == 'admin');
      }
    } catch (_) {}
  }

  /// Lưu phiên từ response đăng ký (Customer).
  static Future<void> saveRegister(RegisterResponse response) async {
    if (response.token == null || response.token!.isEmpty) return;
    try {
      final prefs = await _prefsAsync;
    await prefs.setString(_keyToken, response.token!);
    await prefs.setString(_keyUserType, 'customer');
    final u = response.userData;
    if (u != null) {
      final id = u['id'];
      if (id is int) await prefs.setInt(_keyUserId, id);
      final username = u['username'];
      if (username is String) await prefs.setString(_keyUsername, username);
      if (u['customer_profile'] is Map) {
        final profile = u['customer_profile'] as Map<String, dynamic>;
        final email = profile['email'];
        if (email is String) await prefs.setString(_keyEmail, email);
      }
    }
    await prefs.setBool(_keyIsSuperuser, false);
    await prefs.setBool(_keyIsStaff, false);
    } catch (_) {}
  }

  /// Đọc phiên đã lưu. Trả về null nếu chưa đăng nhập, đã logout, hoặc plugin lỗi.
  static Future<SavedSession?> getSavedSession() async {
    try {
      final prefs = _prefs ?? await SharedPreferences.getInstance();
      _prefs ??= prefs;
      final token = prefs.getString(_keyToken);
      if (token == null || token.isEmpty) return null;
      return SavedSession(
        token: token,
        userType: prefs.getString(_keyUserType) ?? 'customer',
        userId: prefs.getInt(_keyUserId),
        username: prefs.getString(_keyUsername),
        email: prefs.getString(_keyEmail),
        isSuperuser: prefs.getBool(_keyIsSuperuser) ?? false,
        isStaff: prefs.getBool(_keyIsStaff) ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  /// Xóa phiên và token trong ApiClient (gọi khi logout).
  static Future<void> clear() async {
    ApiClient.instance.clearAuthToken();
    try {
      final prefs = await _prefsAsync;
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUserType);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUsername);
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyIsSuperuser);
      await prefs.remove(_keyIsStaff);
    } catch (_) {}
  }

  /// Logout: xóa phiên và chuyển về màn Login. Gọi từ bất kỳ màn nào (Home, Staff, Admin).
  static Future<void> logout(BuildContext context) async {
    await clear();
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }
}
