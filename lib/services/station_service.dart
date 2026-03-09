import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/models/stations_list_response.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

/// Service gọi API danh sách trạm đăng kiểm (Read-only).
class StationService {
  StationService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  Future<void> _ensureToken() async {
    final session = await AuthStorage.getSavedSession();
    if (session != null && session.token.isNotEmpty) {
      _api.setAuthToken(session.token);
    }
  }

  /// GET /api/stations/ — Danh sách trạm. [search] tìm theo station_name, station_code, address; [status] active | inactive (mặc định active).
  Future<StationsListResponse> getStations({
    String? search,
    String? status,
  }) async {
    await _ensureToken();
    final queryParams = <String, dynamic>{};
    if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();
    if (status != null && status.trim().isNotEmpty) queryParams['status'] = status.trim();
    final response = await _api.dio.get<Map<String, dynamic>>(
      'stations/',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        type: DioExceptionType.badResponse,
        response: response,
      );
    }
    return StationsListResponse.fromJson(data);
  }
}
