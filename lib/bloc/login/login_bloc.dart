import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/models/login_request.dart';
import 'package:vehicle_registration_app/models/login_response.dart';
import 'package:vehicle_registration_app/services/auth_service.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';
import 'package:vehicle_registration_app/bloc/login/login_event.dart';
import 'package:vehicle_registration_app/bloc/login/login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const LoginState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  final AuthService _authService;

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    final phone = event.phone.trim();
    final password = event.password;

    if (phone.isEmpty || password.isEmpty) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        message: 'Vui lòng nhập số điện thoại và mật khẩu',
      ));
      return;
    }

    emit(state.copyWith(status: LoginStatus.loading, message: null));

    try {
      final request = LoginRequest(phone: phone, password: password);
      final response = await _authService.login(request);

      if (response.success && response.token != null) {
        await AuthStorage.saveLogin(response);
        ApiClient.instance.setAuthToken(response.token!);
        emit(state.copyWith(
          status: LoginStatus.success,
          message: response.message,
          loginResponse: response,
        ));
      } else {
        emit(state.copyWith(
          status: LoginStatus.failure,
          message: response.message ?? 'Đăng nhập thất bại',
        ));
      }
    } on DioException catch (e) {
      String message = 'Đăng nhập thất bại';
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        message = data['message'] as String? ??
            data['detail'] as String? ??
            (e.response?.statusMessage ?? message);
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Kết nối timeout. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Không thể kết nối server. Kiểm tra mạng.';
      }
      emit(state.copyWith(status: LoginStatus.failure, message: message));
    } catch (e, _) {
      emit(state.copyWith(
        status: LoginStatus.failure,
        message: e.toString().contains('SocketException')
            ? 'Không thể kết nối server.'
            : 'Có lỗi xảy ra. Vui lòng thử lại.',
      ));
    }
  }
}
