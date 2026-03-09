import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:vehicle_registration_app/models/auth_me_response.dart';
import 'package:vehicle_registration_app/models/login_request.dart';
import 'package:vehicle_registration_app/models/login_response.dart';
import 'package:vehicle_registration_app/models/register_request.dart';
import 'package:vehicle_registration_app/models/register_response.dart';
import 'package:vehicle_registration_app/models/request_otp_request.dart';
import 'package:vehicle_registration_app/models/request_otp_response.dart';
import 'package:vehicle_registration_app/models/verify_otp_request.dart';
import 'package:vehicle_registration_app/models/verify_otp_response.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

/// Service gọi API đăng nhập, OTP, đăng ký, và lấy thông tin user hiện tại.
class AuthService {
  AuthService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  /// Đảm bảo token đã gắn vào ApiClient (từ phiên đăng nhập).
  Future<void> _ensureToken() async {
    final session = await AuthStorage.getSavedSession();
    if (session != null && session.token.isNotEmpty) {
      _api.setAuthToken(session.token);
    }
  }

  /// GET /api/auth/me/ — Lấy thông tin user hiện tại (Customer hoặc Staff).
  /// Permission: IsAuthenticated. Trả về [AuthMeResponse] với [userType], [user], [profile].
  Future<AuthMeResponse> getMe() async {
    await _ensureToken();
    final response = await _api.dio.get<Map<String, dynamic>>('auth/me/');
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    return AuthMeResponse.fromJson(data);
  }

  /// POST /api/login/ — Đăng nhập (Admin: username + password).
  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      'login/',
      data: request.toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    final loginResponse = LoginResponse.fromJson(data);
    if (loginResponse.token != null && loginResponse.token!.isNotEmpty) {
      _api.setAuthToken(loginResponse.token!);
    }
    return loginResponse;
  }

  /// POST /api/auth/request-otp/ — Yêu cầu OTP (login | register | reset_password).
  Future<RequestOtpResponse> requestOtp(RequestOtpRequest request) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      'auth/request-otp/',
      data: request.toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    return RequestOtpResponse.fromJson(data);
  }

  /// POST /api/auth/verify-otp/ — Verify OTP (không tiêu thụ), kiểm tra OTP hợp lệ trước khi đăng ký/đăng nhập.
  Future<VerifyOtpResponse> verifyOtp(VerifyOtpRequest request) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      'auth/verify-otp/',
      data: request.toJson(),
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    return VerifyOtpResponse.fromJson(data);
  }

  /// POST /api/register/ — Đăng ký Customer (phone + otp_code + password, optional full_name, email).
  Future<RegisterResponse> register(RegisterRequest request) async {
    final body = request.toJson();
    debugPrint('[AuthService] POST register/ request body: $body');
    final response = await _api.dio.post<Map<String, dynamic>>(
      'register/',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    final registerResponse = RegisterResponse.fromJson(data);
    if (registerResponse.token != null && registerResponse.token!.isNotEmpty) {
      _api.setAuthToken(registerResponse.token!);
    }
    return registerResponse;
  }

  void logout() {
    _api.clearAuthToken();
  }
}
