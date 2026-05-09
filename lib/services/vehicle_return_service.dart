import 'package:dio/dio.dart';
import 'package:vehicle_registration_app/models/additional_cost_model.dart';
import 'package:vehicle_registration_app/services/api_client.dart';
import 'package:vehicle_registration_app/services/auth_storage.dart';

/// Service cho quy trình trả xe (APIs 6.1 – 6.10).
///
/// Các API đã có sẵn ở service khác:
/// - Upload ảnh → VehicleReceiptService.uploadMedia()
/// - Tạo payment PayOS → PaymentService.createPayment()
/// - Check payment status → PaymentService.checkPaymentStatus()
class VehicleReturnService {
  VehicleReturnService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient.instance;

  final ApiClient _api;

  Future<void> _ensureToken() async {
    final session = await AuthStorage.getSavedSession();
    if (session != null && session.token.isNotEmpty) {
      _api.setAuthToken(session.token);
    }
  }

  // ============================================================
  // API 6.1: Khởi tạo biên bản trả xe
  // POST /api/orders/{order_id}/vehicle-return-initialize/
  // ============================================================

  /// Khởi tạo VehicleReturnLog cho một đơn hàng.
  /// Trả về response map nếu thành công (200/201), null nếu đã tồn tại (400).
  Future<Map<String, dynamic>?> initializeReturn({
    required String orderId,
  }) async {
    await _ensureToken();

    final path = 'orders/$orderId/vehicle-return-initialize/';

    try {
      print('=== DEBUG: initializeReturn ===');
      print('orderId: "$orderId"');
      print('full URL: ${_api.dio.options.baseUrl}$path');
      print('================================');

      final response = await _api.dio.post(path);

      print('=== DEBUG: initializeReturn RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('==========================================');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true};
    } on DioException catch (e) {
      // TODO: Cần kiểm tra lại logic backend trả về mã 400 khi nào là "Biên bản đã tồn tại"
      // Hiện tại tạm thời bắt mọi lỗi 400 để app không bị crash luồng (giống như initializeReceipt).
      if (e.response?.statusCode == 400) {
        print('=== DEBUG: initializeReturn 400 (đã tồn tại hoặc lỗi payload, tạm bỏ qua) ===');
        print('Response data: ${e.response?.data}');
        return null;
      }
      print('=== DEBUG: LỖI initializeReturn ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // API 6.2: Xác nhận bước ảnh xe khi trả
  // POST /api/orders/{order_id}/vehicle-return-vehicle-inspection/
  // ============================================================

  /// Xác nhận đã upload xong ảnh xe khi trả.
  /// API chỉ xác nhận bước nghiệp vụ, ảnh lấy từ media_files.
  Future<Map<String, dynamic>> confirmVehicleInspection({
    required String orderId,
  }) async {
    await _ensureToken();

    final path = 'orders/$orderId/vehicle-return-vehicle-inspection/';

    try {
      print('=== DEBUG: confirmVehicleInspection ===');
      print('orderId: "$orderId"');
      print('========================================');

      final response = await _api.dio.post(path);

      print('=== DEBUG: confirmVehicleInspection RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('=================================================');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true};
    } catch (e) {
      print('=== DEBUG: LỖI confirmVehicleInspection ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // API 6.3: Kiểm tra tình trạng xe khi trả (8 checkbox)
  // POST /api/orders/{order_id}/vehicle-return-condition-check/
  // ============================================================

  /// Gửi checklist 8 items kiểm tra tình trạng xe khi trả.
  ///
  /// [checklist] map gồm các key:
  /// - exterior_ok, tires_ok, lights_ok, mirrors_ok
  /// - windows_ok, interior_ok, documents_complete_ok, stamp_attached_ok
  Future<Map<String, dynamic>> submitConditionCheck({
    required String orderId,
    required Map<String, bool> checklist,
  }) async {
    await _ensureToken();

    final path = 'orders/$orderId/vehicle-return-condition-check/';

    try {
      print('=== DEBUG: submitConditionCheck ===');
      print('orderId: "$orderId"');
      print('checklist: $checklist');
      print('====================================');

      final response = await _api.dio.post(path, data: checklist);

      print('=== DEBUG: submitConditionCheck RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('=============================================');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true};
    } catch (e) {
      print('=== DEBUG: LỖI submitConditionCheck ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // API 6.4: Thêm chi phí phát sinh
  // POST /api/orders/{order_id}/vehicle-return-additional-costs/
  // ============================================================

  /// Tạo một chi phí phát sinh cho đơn hàng.
  Future<AdditionalCost> addAdditionalCost({
    required String orderId,
    required String costType,
    required String costName,
    required double amount,
    String? description,
    String? photoUrl,
    String? notes,
  }) async {
    await _ensureToken();

    final path = 'orders/$orderId/vehicle-return-additional-costs/';
    final body = <String, dynamic>{
      'cost_type': costType,
      'cost_name': costName,
      'amount': amount,
    };
    if (description != null) body['description'] = description;
    if (photoUrl != null) body['photo_url'] = photoUrl;
    if (notes != null) body['notes'] = notes;

    try {
      print('=== DEBUG: addAdditionalCost ===');
      print('orderId: "$orderId"');
      print('body: $body');
      print('=================================');

      final response = await _postAdditionalCostWithInitializeRetry(
        path: path,
        orderId: orderId,
        body: body,
      );

      print('=== DEBUG: addAdditionalCost RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('==========================================');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Response có thể wrap trong 'cost' key
        final costData = data['cost'] as Map<String, dynamic>? ?? data;
        return AdditionalCost.fromJson(costData);
      }
      throw Exception('Unexpected response format from addAdditionalCost');
    } catch (e) {
      print('=== DEBUG: LỖI addAdditionalCost ===');
      print(e.toString());
      rethrow;
    }
  }

  Future<Response<dynamic>> _postAdditionalCostWithInitializeRetry({
    required String path,
    required String orderId,
    required Map<String, dynamic> body,
  }) async {
    try {
      return await _api.dio.post(path, data: body);
    } on DioException catch (e) {
      final responseText = e.response?.data?.toString().toLowerCase() ?? '';
      final missingReturnLog = responseText.contains('chưa có biên bản') ||
          responseText.contains('chua co bien ban') ||
          responseText.contains('initialize');

      if (!missingReturnLog) rethrow;

      await initializeReturn(orderId: orderId);
      return _api.dio.post(path, data: body);
    }
  }

  // ============================================================
  // API 6.7: Xác nhận thanh toán tiền mặt
  // POST /api/vehicle-return-additional-costs/{cost_id}/confirm-cash-payment/
  // ============================================================

  /// Xác nhận đã thu tiền mặt cho một chi phí phát sinh.
  Future<Map<String, dynamic>> confirmCashPayment({
    required int costId,
    String? paymentNote,
  }) async {
    await _ensureToken();

    final path =
        'vehicle-return-additional-costs/$costId/confirm-cash-payment/';
    final body = <String, dynamic>{};
    if (paymentNote != null) body['payment_note'] = paymentNote;

    try {
      print('=== DEBUG: confirmCashPayment ===');
      print('costId: $costId');
      print('=================================');

      final response = await _api.dio.post(path, data: body);

      print('=== DEBUG: confirmCashPayment RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('==========================================');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true};
    } catch (e) {
      print('=== DEBUG: LỖI confirmCashPayment ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // API 6.8: Kiểm tra trạng thái thanh toán chi phí
  // GET /api/vehicle-return-additional-costs/{cost_id}/payment-status/
  // ============================================================

  /// Lấy trạng thái thanh toán của một chi phí phát sinh.
  Future<Map<String, dynamic>> getPaymentStatus({
    required int costId,
  }) async {
    await _ensureToken();

    final path = 'vehicle-return-additional-costs/$costId/payment-status/';

    try {
      final response = await _api.dio.get(path);

      print('=== DEBUG: getPaymentStatus RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('==========================================');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('=== DEBUG: LỖI getPaymentStatus ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // API 6.10: Hoàn tất biên bản trả xe
  // POST /api/orders/{order_id}/vehicle-return-finalize/
  // ============================================================

  /// Hoàn tất biên bản trả xe với đầy đủ giấy tờ kiểm định.
  ///
  /// 8 fields BẮT BUỘC:
  /// - vehicle_registration_url, stamp_url, stamp_number, stamp_expiry_date
  /// - inspection_certificate_url, certificate_number, certificate_expiry_date
  /// - customer_signature
  Future<Map<String, dynamic>> finalizeReturn({
    required String orderId,
    // Nhóm A: Giấy đăng ký xe
    required String vehicleRegistrationUrl,
    String? registrationNumber,
    // Nhóm B: Tem đăng kiểm
    required String stampUrl,
    required String stampNumber,
    required String stampExpiryDate,
    // Nhóm C: Giấy tờ khác
    String? otherDocumentsUrls,
    // Nhóm D: Biên lai
    String? receiptUrl,
    String? receiptNumber,
    // Nhóm E: Giấy chứng nhận kiểm định
    required String inspectionCertificateUrl,
    required String certificateNumber,
    required String certificateExpiryDate,
    // Nhóm F: Ghi chú & Chữ ký
    String? additionalNotes,
    required String customerSignature,
  }) async {
    await _ensureToken();

    final path = 'orders/$orderId/vehicle-return-finalize/';
    final body = <String, dynamic>{
      // Nhóm A
      'vehicle_registration_url': vehicleRegistrationUrl,
      // Nhóm B
      'stamp_url': stampUrl,
      'stamp_number': stampNumber,
      'stamp_expiry_date': stampExpiryDate,
      // Nhóm E
      'inspection_certificate_url': inspectionCertificateUrl,
      'certificate_number': certificateNumber,
      'certificate_expiry_date': certificateExpiryDate,
      // Nhóm F
      'customer_signature': customerSignature,
    };

    // Optional fields
    if (registrationNumber != null) {
      body['registration_number'] = registrationNumber;
    }
    if (otherDocumentsUrls != null) {
      body['other_documents_urls'] = otherDocumentsUrls;
    }
    if (receiptUrl != null) body['receipt_url'] = receiptUrl;
    if (receiptNumber != null) body['receipt_number'] = receiptNumber;
    if (additionalNotes != null) body['additional_notes'] = additionalNotes;

    try {
      print('=== DEBUG: finalizeReturn ===');
      print('orderId: "$orderId"');
      print('body keys: ${body.keys.toList()}');
      print('==============================');

      final response = await _api.dio.post(path, data: body);

      print('=== DEBUG: finalizeReturn RESPONSE ===');
      print('Status: ${response.statusCode}');
      print('Data: ${response.data}');
      print('=======================================');

      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true};
    } catch (e) {
      print('=== DEBUG: LỖI finalizeReturn ===');
      print(e.toString());
      rethrow;
    }
  }

  // ============================================================
  // Helper: Tạo checklist map từ 8 boolean values
  // ============================================================

  /// Tạo checklist map cho API 6.3.
  /// Thứ tự: exterior, tires, lights, mirrors, windows, interior,
  ///         documents_complete, stamp_attached
  static Map<String, bool> buildChecklist(List<bool> values) {
    const keys = [
      'exterior_ok',
      'tires_ok',
      'lights_ok',
      'mirrors_ok',
      'windows_ok',
      'interior_ok',
      'documents_complete_ok',
      'stamp_attached_ok',
    ];
    final map = <String, bool>{};
    for (var i = 0; i < keys.length && i < values.length; i++) {
      map[keys[i]] = values[i];
    }
    return map;
  }

  /// Danh sách label tiếng Việt cho 8 checklist items (trả xe).
  static const List<String> checklistLabels = [
    'Ngoại thất không trầy xước',
    'Lốp xe đầy đủ, không rò',
    'Hệ thống đèn hoạt động tốt',
    'Gương chiếu hậu nguyên vẹn',
    'Kính chắn gió không vỡ/nứt',
    'Nội thất sạch sẽ',
    'Giấy tờ xe đầy đủ',
    'Tem đăng kiểm đã dán',
  ];
}
