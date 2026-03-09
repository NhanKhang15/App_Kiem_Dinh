import 'package:flutter/material.dart';

/// Helper để điều hướng toàn cục (vd. khi 401 đẩy về login).
/// [navigatorKey] cần được gán trong [main.dart] trước [runApp].
class NavigationHelper {
  NavigationHelper._();

  static GlobalKey<NavigatorState>? navigatorKey;

  /// Đẩy về màn login và xóa hết stack (sau khi đã clear token/session).
  static void goToLogin() {
    navigatorKey?.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  }
}
