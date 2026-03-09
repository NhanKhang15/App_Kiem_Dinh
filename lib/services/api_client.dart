import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/constants/constant.dart';
import 'package:vehicle_registration_app/navigation_helper.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

/// Client HTTP dùng Dio, base URL từ [kBaseUrl]. Dùng singleton để token lưu một chỗ và restore khi mở app.
/// Khi API trả 401 (token hết hạn), tự động clear phiên và đẩy về màn login.
class ApiClient {
  ApiClient._({BaseOptions? baseOptions}) {
    _dio = Dio(
      baseOptions ??
          BaseOptions(
            baseUrl: kBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
    );
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await AuthStorage.clear();
          if (NavigationHelper.navigatorKey?.currentContext != null) {
            NavigationHelper.goToLogin();
          }
        }
        handler.next(error);
      },
    ));
  }

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  /// Backend Django REST thường dùng "Token xxx"; JWT dùng "Bearer xxx". Đổi thành true nếu API trả 401 với Bearer.
  static const bool _useTokenPrefix = true;

  /// Gắn token vào header cho các request cần xác thực.
  void setAuthToken(String token) {
    final prefix = _useTokenPrefix ? 'Token' : 'Bearer';
    _dio.options.headers['Authorization'] = '$prefix $token';
  }

  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
