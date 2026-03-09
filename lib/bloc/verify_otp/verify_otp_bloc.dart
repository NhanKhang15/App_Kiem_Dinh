import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/models/verify_otp_request.dart';
import 'package:vehicle_registration_app/models/verify_otp_response.dart';
import 'package:vehicle_registration_app/services/auth_service.dart';
import 'package:vehicle_registration_app/bloc/verify_otp/verify_otp_event.dart';
import 'package:vehicle_registration_app/bloc/verify_otp/verify_otp_state.dart';

class VerifyOtpBloc extends Bloc<VerifyOtpEvent, VerifyOtpState> {
  VerifyOtpBloc({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(const VerifyOtpState()) {
    on<VerifyOtpSubmitted>(_onVerifyOtpSubmitted);
  }

  final AuthService _authService;

  Future<void> _onVerifyOtpSubmitted(
    VerifyOtpSubmitted event,
    Emitter<VerifyOtpState> emit,
  ) async {
    final phone = event.phone.trim();
    final otpCode = event.otpCode.replaceAll(' ', '');

    if (phone.isEmpty) {
      emit(state.copyWith(
        status: VerifyOtpStatus.failure,
        message: 'Vui lòng nhập số điện thoại',
      ));
      return;
    }
    if (otpCode.length != 6) {
      emit(state.copyWith(
        status: VerifyOtpStatus.failure,
        message: 'Mã OTP phải đủ 6 số',
      ));
      return;
    }

    emit(state.copyWith(status: VerifyOtpStatus.loading, message: null));

    try {
      final request = VerifyOtpRequest(
        phone: phone,
        otpCode: otpCode,
        purpose: event.purpose,
      );
      final response = await _authService.verifyOtp(request);

      if (response.success && response.valid) {
        emit(state.copyWith(
          status: VerifyOtpStatus.success,
          message: response.message,
          response: response,
        ));
      } else {
        emit(state.copyWith(
          status: VerifyOtpStatus.failure,
          message: response.message ?? 'Mã OTP không hợp lệ',
          response: response,
        ));
      }
    } on DioException catch (e) {
      // 400 Bad Request — OTP sai, server trả body { success, valid, message, error_code }
      final resData = e.response?.data;
      if (e.response?.statusCode == 400 && resData is Map<String, dynamic>) {
        final parsed = VerifyOtpResponse.fromJson(resData);
        emit(state.copyWith(
          status: VerifyOtpStatus.failure,
          message: parsed.message ?? 'Mã OTP không chính xác',
          response: parsed,
        ));
        return;
      }
      String message = 'Xác thực OTP thất bại';
      if (resData is Map<String, dynamic>) {
        message = resData['message'] as String? ??
            resData['detail']?.toString() ??
            message;
      } else if (resData is String && resData.isNotEmpty) {
        message = resData;
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'Kết nối timeout. Vui lòng thử lại.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Không thể kết nối server. Kiểm tra mạng.';
      }
      emit(state.copyWith(status: VerifyOtpStatus.failure, message: message));
    } catch (e, _) {
      emit(state.copyWith(
        status: VerifyOtpStatus.failure,
        message: e.toString().contains('SocketException')
            ? 'Không thể kết nối server.'
            : 'Có lỗi xảy ra. Vui lòng thử lại.',
      ));
    }
  }
}
