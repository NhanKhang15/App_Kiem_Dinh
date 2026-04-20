import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

class PaymentService {
  PaymentService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  static const Set<String> allowedMethods = {'QR', 'VNPAY', 'CASH'};
  static const int minAmount = 10000;

  Future<void> _ensureToken() async {
    final session = await AuthStorage.getSavedSession();
    if (session != null && session.token.isNotEmpty) {
      _api.setAuthToken(session.token);
    }
  }

  /// Tạo payment link PayOS.
  ///
  /// Hỗ trợ 2 luồng theo spec mới:
  /// - Thanh toán đơn nhận xe: truyền [orderId].
  /// - Thanh toán chi phí phát sinh khi trả xe: truyền [additionalCostId].
  ///
  /// Có thể truyền [amount] để override số tiền (phải là số nguyên ≥ 10.000).
  /// Nếu không truyền, backend sẽ tự tính.
  Future<Map<String, dynamic>> createPayment({
    int? orderId,
    int? additionalCostId,
    int? amount,
    required String method,
  }) async {
    if (orderId == null && additionalCostId == null) {
      throw ArgumentError('Cần truyền order_id hoặc additional_cost_id.');
    }
    if (!allowedMethods.contains(method)) {
      throw ArgumentError('Phương thức thanh toán không hợp lệ: $method.');
    }
    if (amount != null && amount < minAmount) {
      throw ArgumentError('Số tiền tối thiểu là $minAmount VND.');
    }

    await _ensureToken();

    final body = <String, dynamic>{'method': method};
    if (orderId != null) body['order_id'] = orderId;
    if (additionalCostId != null) body['additional_cost_id'] = additionalCostId;
    if (amount != null) body['amount'] = amount;

    try {
      final response = await _api.dio.post('create-payment/', data: body);
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      throw Exception(_mapCreatePaymentError(e));
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định: $e');
    }
  }

  String _mapCreatePaymentError(DioException e) {
    final status = e.response?.statusCode;
    final serverMsg = _extractServerMessage(e.response?.data);
    switch (status) {
      case 400:
        return serverMsg ?? 'Dữ liệu thanh toán không hợp lệ (số tiền / order_id / method).';
      case 404:
        return serverMsg ?? 'Không tìm thấy đơn hàng hoặc chi phí phát sinh.';
      case 500:
        return serverMsg ?? 'Backend thiếu cấu hình RETURN_URL hoặc CANCEL_URL.';
      case 502:
        return serverMsg ?? 'Không tạo được payment link từ PayOS.';
      default:
        return 'Lỗi kết nối khi tạo thanh toán: ${e.message}';
    }
  }

  /// Kiểm tra trạng thái thanh toán theo `order_code`.
  ///
  /// Trả về map chứa `status` (`PENDING` / `SUCCESS` / `FAILED`),
  /// `amount`, `message`.
  Future<Map<String, dynamic>> checkPaymentStatus(int orderCode) async {
    await _ensureToken();

    try {
      final response = await _api.dio.get('check-payment-status/$orderCode/');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy giao dịch.');
      }
      throw Exception('Lỗi khi kiểm tra thanh toán: ${e.message}');
    } catch (e) {
      throw Exception('Đã xảy ra lỗi không xác định khi kiểm tra thanh toán: $e');
    }
  }

  /// Tra cứu order nội bộ từ `order_code` của PayOS.
  Future<Map<String, dynamic>> getPaymentOrder(int orderCode) async {
    await _ensureToken();

    try {
      final response = await _api.dio.get('payment-order/$orderCode/');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy giao dịch.');
      }
      throw Exception('Lỗi khi tra cứu order: ${e.message}');
    }
  }

  /// Lấy chi tiết bản ghi payment qua `PaymentViewSet`.
  Future<Map<String, dynamic>> getPaymentDetail(int paymentId) async {
    await _ensureToken();

    try {
      final response = await _api.dio.get('payments/$paymentId/');
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception('Không tìm thấy payment.');
      }
      throw Exception('Lỗi khi lấy chi tiết payment: ${e.message}');
    }
  }

  String? _extractServerMessage(dynamic data) {
    if (data is Map) {
      for (final key in const ['error', 'message', 'detail']) {
        final v = data[key];
        if (v is String && v.trim().isNotEmpty) return v;
      }
    }
    return null;
  }
}
