import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/models/vehicles_list_response.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

/// Service gọi API danh sách xe (bắt buộc dùng token lưu lúc đăng nhập).
class VehicleService {
  VehicleService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  /// Đảm bảo token đã gắn vào ApiClient (từ phiên đăng nhập đã lưu).
  Future<void> _ensureToken() async {
    final session = await AuthStorage.getSavedSession();
    if (session != null && session.token.isNotEmpty) {
      _api.setAuthToken(session.token);
    }
  }

  /// GET /api/vehicles/ — Danh sách xe của customer đăng nhập (cần Authorization: Bearer token).
  Future<VehiclesListResponse> getVehicles() async {
    await _ensureToken();
    final response = await _api.dio.get<Map<String, dynamic>>('vehicles/');
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    return VehiclesListResponse.fromJson(data);
  }

  /// POST /api/vehicles/ — Tạo xe mới. Customer ID lấy từ session (userId).
  Future<Map<String, dynamic>> createVehicle({
    required int customerId,
    required int vehicleTypeId,
    required String licensePlate,
    String? brand,
    String? model,
    String? color,
    int? manufactureYear,
    String? chassisNumber,
    String? engineNumber,
  }) async {
    await _ensureToken();
    final body = <String, dynamic>{
      'customer': customerId,
      'vehicle_type': vehicleTypeId,
      'license_plate': licensePlate.trim(),
    };
    if (brand != null && brand.isNotEmpty) body['brand'] = brand;
    if (model != null && model.isNotEmpty) body['model'] = model;
    if (color != null && color.isNotEmpty) body['color'] = color;
    if (manufactureYear != null) body['manufacture_year'] = manufactureYear;
    if (chassisNumber != null && chassisNumber.isNotEmpty) body['chassis_number'] = chassisNumber;
    if (engineNumber != null && engineNumber.isNotEmpty) body['engine_number'] = engineNumber;

    final response = await _api.dio.post<Map<String, dynamic>>('vehicles/', data: body);
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    return Map<String, dynamic>.from(data);
  }

  /// GET /api/vehicles/{id}/ — Chi tiết vehicle (để pre-fill form chỉnh sửa).
  Future<Map<String, dynamic>> getVehicle(int id) async {
    await _ensureToken();
    final response = await _api.dio.get<Map<String, dynamic>>('vehicles/$id/');
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    return Map<String, dynamic>.from(data);
  }

  /// PATCH /api/vehicles/{id}/ — Cập nhật một hoặc nhiều trường.
  Future<Map<String, dynamic>> updateVehicle(int id, Map<String, dynamic> body) async {
    await _ensureToken();
    final response = await _api.dio.patch<Map<String, dynamic>>('vehicles/$id/', data: body);
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    return Map<String, dynamic>.from(data);
  }

  /// DELETE /api/vehicles/{id}/ — Xóa vehicle (soft delete). Response 204 No Content.
  Future<void> deleteVehicle(int id) async {
    await _ensureToken();
    await _api.dio.delete<void>('vehicles/$id/');
  }
}
