import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/models/order_model.dart';
import 'package:vehicle_registration_app/models/orders_list_response.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

/// Service dành cho Staff để quản lý đơn hàng (Tasks).
class StaffService {
  StaffService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  /// Đảm bảo token đã gắn vào ApiClient.
  Future<void> _ensureToken() async {
    final session = await AuthStorage.getSavedSession();
    if (session != null && session.token.isNotEmpty) {
      _api.setAuthToken(session.token);
    }
  }

  /// GET /api/orders/my_tasks/ — Lấy danh sách nhiệm vụ của nhân viên hiện tại.
  Future<OrdersListResponse> getRecentOrders() async {
    await _ensureToken();
    try {
      // Cập nhật endpoint mới theo yêu cầu
      final response = await _api.dio.get<Map<String, dynamic>>('orders/my_tasks/');
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.badResponse,
          response: response,
        );
      }
      return OrdersListResponse.fromJson(data);
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// GET /api/orders/{order_id}/ — Lấy thông tin chi tiết một đơn hàng.
  /// (Lưu ý: Endpoint này có thể cần điều chỉnh nếu Backend thay đổi cách lấy chi tiết task)
  Future<OrderModel> getOrderDetail(String orderId) async {
    await _ensureToken();
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('orders/$orderId/');
      final data = response.data;
      if (data == null) {
        throw DioException(
          requestOptions: response.requestOptions,
          type: DioExceptionType.badResponse,
          response: response,
        );
      }
      return OrderModel.fromJson(data);
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// POST /api/orders/{order_id}/update-driver-location/ — Cập nhật tọa độ GPS của tài xế.
  Future<void> updateDriverLocation(
    String orderId, {
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    await _ensureToken();
    try {
      // Làm tròn tọa độ để tránh lỗi Backend (max 10 digits latitude, 11 digits longitude)
      final roundedLat = double.parse(latitude.toStringAsFixed(7));
      final roundedLng = double.parse(longitude.toStringAsFixed(7));

      await _api.dio.post(
        'orders/$orderId/update-driver-location/',
        data: {
          'latitude': roundedLat,
          'longitude': roundedLng,
          'accuracy': accuracy,
        },
      );
    } on DioException catch (e) {
      rethrow;
    }
  }

  /// GET /api/orders/{order_id}/driver-location/ — Lấy tọa độ GPS mới nhất của tài xế.
  Future<Map<String, dynamic>?> getDriverLocation(String orderId) async {
    await _ensureToken();
    try {
      final response = await _api.dio.get<Map<String, dynamic>>('orders/$orderId/driver-location/');
      return response.data;
    } on DioException catch (e) {
      // Nếu chưa có vị trí, API có thể trả về 404 hoặc null, tùy Backend xử lý.
      return null;
    }
  }
}
