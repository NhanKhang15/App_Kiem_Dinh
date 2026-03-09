import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/models/request_otp_request.dart';
import 'package:vehicle_registration_app/models/request_otp_response.dart';
import 'package:vehicle_registration_app/services/auth_service.dart';
import 'package:vehicle_registration_app/bloc/request_otp/request_otp_event.dart';
import 'package:vehicle_registration_app/bloc/request_otp/request_otp_state.dart';

class RequestOtpBloc extends Bloc<RequestOtpEvent, RequestOtpState> {
  RequestOtpBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const RequestOtpState()) {
    on<RequestOtpSubmitted>(_onRequestOtpSubmitted);
  }

  final AuthService _authService;

  Future<void> _onRequestOtpSubmitted(
    RequestOtpSubmitted event,
    Emitter<RequestOtpState> emit,
  ) async {
    final phone = event.phone.trim();
    if (phone.isEmpty) {
      emit(state.copyWith(
        status: RequestOtpStatus.failure,
        message: 'Vui lòng nhập số điện thoại',
      ));
      return;
    }

    emit(state.copyWith(status: RequestOtpStatus.loading, message: null));

    try {
      final request = RequestOtpRequest(phone: phone, purpose: event.purpose);
      final response = await _authService.requestOtp(request);

      if (response.success) {
        emit(state.copyWith(
          status: RequestOtpStatus.success,
          message: response.message,
          response: response,
          phone: phone,
        ));
      } else {
        emit(state.copyWith(
          status: RequestOtpStatus.failure,
          message: response.message ?? 'Gửi OTP thất bại',
        ));
      }
    } on DioException catch (e) {
      String message = 'Gửi mã OTP thất bại';
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        message = data['message'] as String? ??
            data['phone']?.toString() ??
            data['detail']?.toString() ??
            (e.response?.statusMessage ?? message);
        if (data['phone'] is List && (data['phone'] as List).isNotEmpty) {
          message = (data['phone'] as List).first.toString();
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Kết nối timeout. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Không thể kết nối server. Kiểm tra mạng.';
      }
      emit(state.copyWith(status: RequestOtpStatus.failure, message: message));
    } catch (e, _) {
      emit(state.copyWith(
        status: RequestOtpStatus.failure,
        message: e.toString().contains('SocketException')
            ? 'Không thể kết nối server.'
            : 'Có lỗi xảy ra. Vui lòng thử lại.',
      ));
    }
  }
}
