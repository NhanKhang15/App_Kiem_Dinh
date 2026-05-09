import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/models/image_requirement.dart';
import 'package:vehicle_registration_app/models/uploaded_media.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

/// Service gửi biên bản nhận xe lên server.
class VehicleReceiptService {
  VehicleReceiptService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  /// Đảm bảo token đã gắn vào ApiClient.
  Future<void> _ensureToken() async {
    final session = await AuthStorage.getSavedSession();
    if (session != null && session.token.isNotEmpty) {
      _api.setAuthToken(session.token);
    }
  }

  // ============================================================
  // API 5.1: Khởi tạo biên bản nhận xe
  // POST /api/orders/{order_id}/vehicle_receipt_initialize/
  // ============================================================

  /// Khởi tạo biên bản nhận xe (VehicleReceiptLog) cho một đơn hàng.
  ///
  /// **Phải gọi trước** API complete-vehicle-received (5.2).
  /// Nếu biên bản đã tồn tại (HTTP 400), trả về null mà không throw —
  /// điều này cho phép gọi lại an toàn khi user quay lại màn hình.
  ///
  /// Returns response map nếu thành công (201), null nếu đã tồn tại.
  Future<Map<String, dynamic>?> initializeReceipt({
    required String orderId,
  }) async {
    await _ensureToken();

    final path = 'orders/$orderId/vehicle_receipt_initialize/';

    try {
      print('=== DEBUG: initializeReceipt ===');
      print('orderId: "$orderId"');
      print('full URL: ${_api.dio.options.baseUrl}$path');
      print('================================');

      final response = await _api.dio.post(path);

      print('=== DEBUG: initializeReceipt RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('==========================================');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true};
    } on DioException catch (e) {
      // 400 = "Biên bản đã tồn tại" → không phải lỗi, chỉ là đã init rồi
      if (e.response?.statusCode == 400) {
        print('=== DEBUG: initializeReceipt 400 (đã tồn tại, bỏ qua) ===');
        return null;
      }
      print('=== DEBUG: LỖI initializeReceipt ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // API 1: Lấy danh sách cấu hình ảnh bắt buộc
  // GET /api/v1/image-requirements/?stage=RECEIVE
  // ============================================================

  /// Lấy danh sách ảnh bắt buộc theo giai đoạn (RECEIVE/RETURN).
  /// Frontend render UI động theo [sortOrder].
  Future<List<ImageRequirement>> getImageRequirements({
    required String stage,
    int? vehicleTypeId,
  }) async {
    await _ensureToken();

    final queryParams = <String, dynamic>{
      'stage': stage,
    };
    if (vehicleTypeId != null) {
      queryParams['vehicle_type_id'] = vehicleTypeId;
    }

    try {
      final response = await _api.dio.get(
        'v1/image-requirements/',
        queryParameters: queryParams,
      );

      print('=== DEBUG: GET image-requirements ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('=====================================');

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        final list = (data['data'] as List)
            .map((e) => ImageRequirement.fromJson(e as Map<String, dynamic>))
            .toList();
        // Sắp xếp theo sort_order
        list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return list;
      }
      return [];
    } catch (e) {
      print('=== DEBUG: LỖI getImageRequirements ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // API 2: Upload từng ảnh (Chụp xong → upload ngay)
  // POST /api/v1/media/upload/
  // ============================================================

  /// Upload một ảnh lên server.
  ///
  /// [file] - File ảnh (jpg, png, webp, max 10MB)
  /// [orderId] - ID đơn hàng
  /// [requirementId] - ID requirement từ API 1
  ///
  /// stage/category/position được server tự động lấy từ requirement_id.
  Future<UploadedMedia> uploadMedia({
    required File file,
    required String orderId,
    required int requirementId,
  }) async {
    await _ensureToken();

    final fileName = file.path.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
      'order_id': orderId,
      'requirement_id': requirementId,
    });

    try {
      print('--- DEBUG: UPLOAD ẢNH ---');
      print('Order ID: $orderId');
      print('Requirement ID: $requirementId');
      print('File: $fileName (${await file.length()} bytes)');
      print('-------------------------');

      final response = await _api.dio.post(
        'v1/media/upload/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      print('=== DEBUG: UPLOAD RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('==============================');

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return UploadedMedia.fromJson(data['data'] as Map<String, dynamic>);
      }
      // Fallback nếu response trực tiếp là data
      if (data is Map<String, dynamic>) {
        return UploadedMedia.fromJson(data);
      }
      throw Exception('Unexpected response format from upload API');
    } catch (e) {
      print('=== DEBUG: LỖI uploadMedia ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // API 3: Kiểm tra ảnh đã upload
  // GET /api/v1/media/?order_id=123&stage=RECEIVE
  // ============================================================

  /// Kiểm tra ảnh nào đã upload thành công cho một đơn hàng.
  /// Dùng để hiển thị trạng thái ✓ trên UI.
  Future<List<UploadedMedia>> getUploadedMedia({
    required String orderId,
    String? stage,
  }) async {
    await _ensureToken();

    final queryParams = <String, dynamic>{
      'order_id': orderId,
    };
    if (stage != null) {
      queryParams['stage'] = stage;
    }

    try {
      final response = await _api.dio.get(
        'v1/media/',
        queryParameters: queryParams,
      );

      print('=== DEBUG: GET uploaded media ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('================================');

      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] is List) {
        return (data['data'] as List)
            .map((e) => UploadedMedia.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('=== DEBUG: LỖI getUploadedMedia ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // Existing API: Hoàn thành nhận xe
  // POST /api/orders/{orderId}/complete-vehicle-received/
  // ============================================================

  /// POST /api/orders/{orderId}/complete-vehicle-received/
  ///
  /// Gửi toàn bộ thông tin biên bản nhận xe bao gồm chữ ký dưới dạng file PNG.
  /// Sử dụng multipart/form-data vì API yêu cầu upload file.
  Future<Map<String, dynamic>> submitVehicleReceipt({
    required String orderId,
    required String customerName,
    required String customerPhone,
    required String customerAddress,
    required String customerDateOfBirth,
    required String customerIdNumber,
    required String customerIdIssuedDate,
    required String customerIdIssuedPlace,
    required String additionalNotes,
    required bool paymentConfirmed,
    required Uint8List signatureBytes,
  }) async {
    await _ensureToken();

    final formData = FormData.fromMap({
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'customer_date_of_birth': customerDateOfBirth,
      'customer_id_number': customerIdNumber,
      'customer_id_issued_date': customerIdIssuedDate,
      'customer_id_issued_place': customerIdIssuedPlace,
      'additional_notes': additionalNotes,
      'payment_confirmed': paymentConfirmed.toString(),
      'auto_generate_contract': 'true',
      'customer_signature': MultipartFile.fromBytes(
        signatureBytes,
        filename: 'customer_signature.png',
        contentType: DioMediaType('image', 'png'),
      ),
    });

    final path = 'orders/$orderId/complete-vehicle-received/';
    print('=== DEBUG: submitVehicleReceipt ===');
    print('orderId: "$orderId" (length=${orderId.length})');
    print('baseUrl: ${_api.dio.options.baseUrl}');
    print('full URL: ${_api.dio.options.baseUrl}$path');
    print('Authorization: ${_api.dio.options.headers['Authorization']}');
    print('===================================');

    try {
      final response = await _api.dio.post(
        path,
        data: formData,
      );

      // In ra kết quả API trả về
      print('=== DEBUG: API RESPONSE TRẢ VỀ ===');
      print('Status Code: ${response.statusCode}');
      print('Data: ${response.data}');
      print('==================================');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'status': 'success'};
    } catch (e) {
      print('=== DEBUG: LỖI KHI GỌI API ===');
      print(e.toString());
      rethrow;
    }
  }
}
