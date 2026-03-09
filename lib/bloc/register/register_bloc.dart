import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/models/register_request.dart';
import 'package:vehicle_registration_app/models/register_response.dart';
import 'package:vehicle_registration_app/services/auth_service.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';
import 'package:vehicle_registration_app/bloc/register/register_event.dart';
import 'package:vehicle_registration_app/bloc/register/register_state.dart';
import 'package:flutter/foundation.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  RegisterBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const RegisterState()) {
    on<RegisterSubmitted>(_onRegisterSubmitted);
  }

  final AuthService _authService;

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    final phone = event.phone.trim();
    final otpCode = event.otpCode.replaceAll(' ', '');
    final password = event.password;

    if (phone.isEmpty) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        message: 'Vui lòng nhập số điện thoại',
      ));
      return;
    }
    if (otpCode.length != 6) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        message: 'Mã OTP không hợp lệ',
      ));
      return;
    }
    if (password.length < 6) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        message: 'Mật khẩu phải có ít nhất 6 ký tự',
      ));
      return;
    }

    emit(state.copyWith(status: RegisterStatus.loading, message: null));

    try {
      final request = RegisterRequest(
        phone: phone,
        otpCode: otpCode,
        password: password,
        fullName: event.fullName,
        email: event.email,
      );
      final response = await _authService.register(request);

      if (response.success) {
        await AuthStorage.saveRegister(response);
        emit(state.copyWith(
          status: RegisterStatus.success,
          message: response.message,
          response: response,
        ));
      } else {
        emit(state.copyWith(
          status: RegisterStatus.failure,
          message: response.message ?? 'Đăng ký thất bại',
        ));
      }
    } on DioException catch (e) {
      // Log chi tiết để debug Bad Request
      final statusCode = e.response?.statusCode;
      final resData = e.response?.data;
      final uri = e.requestOptions.uri;
      final requestBody = e.requestOptions.data;
      debugPrint('[RegisterBloc] ❌ DioException: statusCode=$statusCode uri=$uri');
      debugPrint('[RegisterBloc] request body: $requestBody');
      debugPrint('[RegisterBloc] response data: $resData');
      if (resData != null) {
        debugPrint('[RegisterBloc] response data (runtimeType): ${resData.runtimeType}');
      }

      String message = 'Đăng ký thất bại';
      if (resData is Map<String, dynamic>) {
        final data = resData;
        // Lỗi validation theo từng field (Django: {"phone": ["..."], "password": ["..."]})
        final parts = <String>[];
        for (final key in ['phone', 'password', 'full_name', 'email']) {
          if (data[key] is List && (data[key] as List).isNotEmpty) {
            parts.add((data[key] as List).first.toString());
          }
        }
        if (parts.isNotEmpty) {
          message = parts.join(' ');
        } else {
          message = data['message'] as String? ??
              data['detail']?.toString() ??
              (e.response?.statusMessage ?? message);
        }
      } else if (resData is String && resData.isNotEmpty) {
        message = resData;
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Kết nối timeout. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Không thể kết nối server. Kiểm tra mạng.';
      }
      emit(state.copyWith(status: RegisterStatus.failure, message: message));
    } catch (e, _) {
      emit(state.copyWith(
        status: RegisterStatus.failure,
        message: e.toString().contains('SocketException')
            ? 'Không thể kết nối server.'
            : 'Có lỗi xảy ra. Vui lòng thử lại.',
      ));
    }
  }
}
