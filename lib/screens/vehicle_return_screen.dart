import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vehicle_registration_app/models/additional_cost_model.dart';
import 'package:vehicle_registration_app/models/image_requirement.dart';
import 'package:vehicle_registration_app/models/uploaded_media.dart';
import 'package:vehicle_registration_app/services/payment_service.dart';
import 'package:vehicle_registration_app/services/vehicle_receipt_service.dart';
import 'package:vehicle_registration_app/services/vehicle_return_service.dart';
import 'package:vehicle_registration_app/widgets/image_picker_sheet.dart';
import 'package:vehicle_registration_app/widgets/payment_polling_helper.dart';
import 'package:vehicle_registration_app/widgets/signature_pad_widget.dart';

class VehicleReturnScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String plate;
  final String vehicleType;
  final String brand;
  final String color;
  final String? orderStatusType;

  const VehicleReturnScreen({
    super.key,
    required this.orderId,
    required this.customerName,
    required this.plate,
    required this.vehicleType,
    required this.brand,
    required this.color,
    this.orderStatusType,
  });

  @override
  State<VehicleReturnScreen> createState() => _VehicleReturnScreenState();
}

class _VehicleReturnScreenState extends State<VehicleReturnScreen> {
  final _noteCtrl = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;

  // === Services ===
  late final VehicleReceiptService _receiptService;
  late final VehicleReturnService _returnService;
  late final PaymentService _paymentService;
  late final PaymentPollingHelper _pollingHelper;

  // === Signature ===
  final GlobalKey<SignaturePadWidgetState> _signaturePadKey =
      GlobalKey<SignaturePadWidgetState>();
  bool _hasSigned = false;

  // === Chi phí phát sinh (API 6.4) ===
  final List<AdditionalCost> _additionalCosts = [];
  final _feeNameCtrl = TextEditingController();
  final _feeAmountCtrl = TextEditingController();
  final _feeDescCtrl = TextEditingController();
  final _feePhotoUrlCtrl = TextEditingController();
  final _feeNotesCtrl = TextEditingController();
  String _selectedCostType = 'repair';
  String _additionalPaymentMethod = 'QR';
  bool _isProcessingAdditionalPayment = false;

  // === Checklist (API 6.3) — 8 items ===
  final List<bool> _checklistValues = List.filled(8, false);
  bool _checklistSubmitted = false;

  // === Giấy tờ kiểm định (API 6.10 Finalize) ===
  final _registrationNumberCtrl = TextEditingController();
  final _stampNumberCtrl = TextEditingController();
  final _stampExpiryCtrl = TextEditingController();
  final _certNumberCtrl = TextEditingController();
  final _certExpiryCtrl = TextEditingController();
  final _receiptNumberCtrl = TextEditingController();
  String? _vehicleRegistrationUrl;
  String? _stampUrl;
  String? _inspectionCertificateUrl;
  String? _receiptUrl;
  List<String> _otherDocumentUrls = [];

  // === Return flow state ===
  String _returnStatus =
      'not_started'; // initialized, vehicle_inspected, condition_checked, completed
  bool _vehicleInspectionConfirmed = false;

  // === State cho API upload ảnh ===
  List<ImageRequirement> _requirements = [];
  Map<int, UploadedMedia> _uploadedMap = {};
  Map<int, bool> _uploadingMap = {};
  Map<int, String> _localFileMap = {};
  bool _isLoadingRequirements = true;
  String? _requirementsError;

  List<ImageRequirement> get _vehicleRequirements =>
      _requirements.where((r) => r.category == 'VEHICLE').toList();

  List<ImageRequirement> get _checklistRequirements =>
      _requirements.where((r) => r.category == 'CHECKLIST').toList();

  List<ImageRequirement> get _documentRequirements => _requirements
      .where((r) => r.category == 'DOCUMENT' || r.category == 'RECEIPT')
      .toList();

  int get _photoCount =>
      _vehicleRequirements.where((r) => _uploadedMap.containsKey(r.id)).length;

  int get _checkCount => _checklistRequirements
      .where((r) => _uploadedMap.containsKey(r.id))
      .length;

  bool get _allRequiredUploaded => _requirements
      .where((r) => r.isRequired)
      .every((r) => _uploadedMap.containsKey(r.id));

  /// Kiểm tra tất cả chi phí phát sinh đã thanh toán chưa
  bool get _allAdditionalCostsPaid =>
      _additionalCosts.isNotEmpty && _additionalCosts.every((c) => c.isPaid);

  /// Tổng chi phí phát sinh
  double get _totalAdditionalCost {
    double total = 0;
    for (final cost in _additionalCosts) {
      total += double.tryParse(cost.amount) ?? 0;
    }
    return total;
  }

  /// Format tiền VNĐ
  String _formatCurrency(double amount) {
    if (amount == amount.truncateToDouble()) {
      return '${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
    }
    return '${amount.toStringAsFixed(0)}đ';
  }

  bool get _shouldInitializeReturn {
    final status = widget.orderStatusType?.toLowerCase();
    return status != 'completed' &&
        status != 'vehicle_returned' &&
        status != 'done' &&
        status != 'cancelled';
  }

  ImageRequirement? _findDocumentRequirement({
    required List<String> positions,
    required List<String> nameKeywords,
    String? category,
  }) {
    bool matches(ImageRequirement requirement) {
      final position = requirement.position.toUpperCase();
      final name = requirement.name.toLowerCase();
      final categoryMatches =
          category == null || requirement.category == category;
      final positionMatches = positions.any((p) => position == p.toUpperCase());
      final nameMatches =
          nameKeywords.any((keyword) => name.contains(keyword.toLowerCase()));
      return categoryMatches && (positionMatches || nameMatches);
    }

    for (final requirement in _documentRequirements) {
      if (matches(requirement)) return requirement;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _receiptService = VehicleReceiptService();
    _returnService = VehicleReturnService();
    _paymentService = PaymentService();
    _pollingHelper = PaymentPollingHelper(paymentService: _paymentService);
    _initializeReturnAndLoad();
  }

  /// Gọi API 6.1 (initialize) + load requirements + uploaded media song song.
  Future<void> _initializeReturnAndLoad() async {
    setState(() {
      _isLoadingRequirements = true;
      _requirementsError = null;
    });

    try {
      final results = await Future.wait([
        _receiptService.getImageRequirements(stage: 'RETURN'),
        _receiptService.getUploadedMedia(
          orderId: widget.orderId,
          stage: 'RETURN',
        ),
        if (_shouldInitializeReturn)
          _returnService.initializeReturn(orderId: widget.orderId),
      ]);

      if (!mounted) return;

      final requirements = results[0] as List<ImageRequirement>;
      final uploadedList = results[1] as List<UploadedMedia>;

      final uploadedMap = <int, UploadedMedia>{};
      for (final media in uploadedList) {
        uploadedMap[media.requirementId] = media;
      }

      setState(() {
        _requirements = requirements;
        _uploadedMap = uploadedMap;
        _isLoadingRequirements = false;
        _returnStatus = 'initialized';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRequirements = false;
        _requirementsError = 'Không thể tải yêu cầu: $e';
      });
    }
  }

  Future<void> _pickAndUploadImage(ImageRequirement requirement) async {
    final source = await ImagePickerSheet.show(
      context,
      title: requirement.name,
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (picked == null || !mounted) return;

    setState(() {
      _localFileMap[requirement.id] = picked.path;
      _uploadingMap[requirement.id] = true;
    });

    try {
      final uploadedMedia = await _receiptService.uploadMedia(
        file: File(picked.path),
        orderId: widget.orderId,
        requirementId: requirement.id,
      );

      if (!mounted) return;

      setState(() {
        _uploadedMap[requirement.id] = uploadedMedia;
        _uploadingMap[requirement.id] = false;
      });

      // Kiểm tra nếu là ảnh xe (không phải checklist) và đã upload đủ 6 ảnh (hoặc đủ yêu cầu) thì gọi confirm (API 6.2)
      if (requirement.category == 'VEHICLE' && !_vehicleInspectionConfirmed) {
        final allVehiclePhotosUploaded = _vehicleRequirements
            .where((r) => r.isRequired)
            .every((r) => _uploadedMap.containsKey(r.id));
        if (allVehiclePhotosUploaded) {
          _confirmVehicleInspection();
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingMap[requirement.id] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi upload: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddFeeDialog() {
    _feeNameCtrl.clear();
    _feeAmountCtrl.clear();
    _feeDescCtrl.clear();
    _feePhotoUrlCtrl.clear();
    _feeNotesCtrl.clear();
    _selectedCostType = 'repair';
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Thêm chi phí phát sinh',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedCostType,
                  decoration: _inputDeco('Loại chi phí', ''),
                  items: const [
                    DropdownMenuItem(value: 'repair', child: Text('Sửa chữa')),
                    DropdownMenuItem(value: 'cleaning', child: Text('Vệ sinh')),
                    DropdownMenuItem(value: 'fuel', child: Text('Nhiên liệu')),
                    DropdownMenuItem(value: 'parking', child: Text('Đỗ xe')),
                    DropdownMenuItem(value: 'other', child: Text('Khác')),
                  ],
                  onChanged: (v) =>
                      setDialogState(() => _selectedCostType = v ?? 'repair'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feeNameCtrl,
                  decoration: _inputDeco('Tên chi phí', 'VD: Sửa đèn pha'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feeAmountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Số tiền (VNĐ)', 'VD: 150000'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feeDescCtrl,
                  decoration: _inputDeco('Mô tả (tùy chọn)', ''),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feePhotoUrlCtrl,
                  decoration: _inputDeco('URL anh (tuy chon)', ''),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feeNotesCtrl,
                  decoration: _inputDeco('Ghi chu (tuy chon)', ''),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('Hủy', style: TextStyle(color: Color(0xFF6B7280))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _addCostViaApi(ctx),
              child: const Text('Thêm', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  /// Gọi API 6.4 để tạo chi phí phát sinh.
  Future<void> _addCostViaApi(BuildContext dialogCtx) async {
    if (_feeNameCtrl.text.isEmpty || _feeAmountCtrl.text.isEmpty) return;
    final amount = double.tryParse(_feeAmountCtrl.text);
    if (amount == null || amount <= 0) return;
    Navigator.pop(dialogCtx);
    try {
      final cost = await _returnService.addAdditionalCost(
        orderId: widget.orderId,
        costType: _selectedCostType,
        costName: _feeNameCtrl.text,
        amount: amount,
        description: _feeDescCtrl.text.isEmpty ? null : _feeDescCtrl.text,
        photoUrl: _feePhotoUrlCtrl.text.isEmpty ? null : _feePhotoUrlCtrl.text,
        notes: _feeNotesCtrl.text.isEmpty ? null : _feeNotesCtrl.text,
      );
      if (!mounted) return;
      setState(() => _additionalCosts.add(cost));
      _showMessage('Đã thêm chi phí: ${cost.costName}');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Lỗi thêm chi phí: $e', isError: true);
    }
  }

  /// Gọi API 6.2 — xác nhận ảnh xe khi trả.
  Future<void> _confirmVehicleInspection() async {
    try {
      await _returnService.confirmVehicleInspection(orderId: widget.orderId);
      if (!mounted) return;
      setState(() {
        _vehicleInspectionConfirmed = true;
        _returnStatus = 'vehicle_inspected';
      });
      _showMessage('Đã xác nhận ảnh xe khi trả');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Lỗi xác nhận ảnh xe: $e', isError: true);
    }
  }

  /// Gọi API 6.3 — gửi checklist.
  Future<void> _submitChecklist() async {
    for (var i = 0; i < _checklistValues.length; i++) {
      if (!_checklistValues[i]) continue;
      final requirement = _checklistRequirementAt(i);
      if (requirement == null || !_uploadedMap.containsKey(requirement.id)) {
        _showMessage('Mỗi hạng mục đã check phải có ảnh kèm theo',
            isError: true);
        return;
      }
    }

    try {
      final checklist = VehicleReturnService.buildChecklist(_checklistValues);
      await _returnService.submitConditionCheck(
        orderId: widget.orderId,
        checklist: checklist,
      );
      if (!mounted) return;
      setState(() {
        _checklistSubmitted = true;
        _returnStatus = 'condition_checked';
      });
      _showMessage('Đã lưu checklist kiểm tra');
    } catch (e) {
      if (!mounted) return;
      _showMessage('Lỗi lưu checklist: $e', isError: true);
    }
  }

  ImageRequirement? _checklistRequirementAt(int index) {
    if (index < 0 || index >= _checklistRequirements.length) return null;
    return _checklistRequirements[index];
  }

  Future<void> _handleChecklistTap(int index) async {
    if (_checklistSubmitted) return;

    final requirement = _checklistRequirementAt(index);
    if (requirement == null) {
      _showMessage('Không tìm thấy cấu hình ảnh checklist', isError: true);
      return;
    }

    if (_uploadedMap.containsKey(requirement.id)) {
      setState(() => _checklistValues[index] = true);
      return;
    }

    await _pickAndUploadChecklistImage(index, requirement);
  }

  Future<void> _pickAndUploadChecklistImage(
    int index,
    ImageRequirement requirement,
  ) async {
    final source = await ImagePickerSheet.show(
      context,
      title: requirement.name,
    );
    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null || !mounted) return;

    setState(() {
      _localFileMap[requirement.id] = picked.path;
      _uploadingMap[requirement.id] = true;
    });

    try {
      final uploadedMedia = await _receiptService.uploadMedia(
        file: File(picked.path),
        orderId: widget.orderId,
        requirementId: requirement.id,
      );

      if (!mounted) return;
      setState(() {
        _uploadedMap[requirement.id] = uploadedMedia;
        _uploadingMap[requirement.id] = false;
        _checklistValues[index] = true;
      });
      _showMessage('Đã tải ảnh checklist');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingMap[requirement.id] = false;
        _checklistValues[index] = false;
      });
      _showMessage('Lỗi tải ảnh checklist: $e', isError: true);
    }
  }

  void _removeChecklistImage(int index, ImageRequirement requirement) {
    if (_checklistSubmitted) return;
    setState(() {
      _uploadedMap.remove(requirement.id);
      _localFileMap.remove(requirement.id);
      _uploadingMap.remove(requirement.id);
      _checklistValues[index] = false;
    });
  }

  /// Refresh trạng thái thanh toán của tất cả chi phí phát sinh (API 6.8).
  ///
  /// Gọi sau khi thanh toán QR/tiền mặt thành công để đồng bộ UI với backend.
  Future<void> _refreshAdditionalCostStatuses() async {
    if (_additionalCosts.isEmpty) return;

    try {
      bool hasChanges = false;
      for (var i = 0; i < _additionalCosts.length; i++) {
        final cost = _additionalCosts[i];
        if (cost.isPaid) continue; // Đã thanh toán, không cần kiểm tra lại

        try {
          final statusData =
              await _returnService.getPaymentStatus(costId: cost.id);
          final newStatus =
              statusData['payment_status']?.toString() ?? cost.paymentStatus;
          if (newStatus != cost.paymentStatus) {
            _additionalCosts[i] = cost.copyWith(
              paymentStatus: newStatus,
              paymentMethod: statusData['payment_method']?.toString(),
              paidAt: statusData['paid_at']?.toString(),
              transactionId: statusData['transaction_id']?.toString(),
              paymentNote: statusData['payment_note']?.toString(),
            );
            hasChanges = true;
          }
        } catch (e) {
          // Log nhưng không rethrow — tiếp tục refresh các cost khác
          print(
              '=== WARN: Không thể refresh payment status cho cost ${cost.id}: $e ===');
        }
      }

      if (hasChanges && mounted) {
        setState(() {});
      }
    } catch (e) {
      print('=== WARN: Lỗi refresh additional cost statuses: $e ===');
    }
  }

  /// Thanh toán QR cho chi phí phát sinh.
  void _updateAdditionalCostPaymentStatus({
    required AdditionalCost cost,
    required String paymentStatus,
    String? paymentMethod,
    String? paidAt,
    String? transactionId,
    String? paymentNote,
  }) {
    final index = _additionalCosts.indexWhere((item) => item.id == cost.id);
    if (index == -1) return;

    _additionalCosts[index] = _additionalCosts[index].copyWith(
      paymentStatus: paymentStatus,
      paymentMethod: paymentMethod,
      paidAt: paidAt,
      transactionId: transactionId,
      paymentNote: paymentNote,
    );
  }

  String _paymentStatusFromPayOS(String? status) {
    switch (status?.toUpperCase()) {
      case 'SUCCESS':
      case 'PAID':
        return 'paid';
      case 'FAILED':
      case 'CANCELLED':
      case 'CANCELED':
        return 'failed';
      default:
        return 'pending';
    }
  }

  /// Kiem tra trang thai PayOS bang /api/check-payment-status/{order_code}/.
  Future<bool> _syncCostPaymentByOrderCode({
    required AdditionalCost cost,
    required int orderCode,
  }) async {
    final statusData = await _paymentService.checkPaymentStatus(orderCode);
    final paymentStatus =
        _paymentStatusFromPayOS(statusData['status']?.toString());

    if (mounted) {
      setState(() {
        _updateAdditionalCostPaymentStatus(
          cost: cost,
          paymentStatus: paymentStatus,
          paymentMethod: 'QR',
          transactionId: statusData['transactionId']?.toString(),
          paymentNote: statusData['message']?.toString(),
        );
      });
    }

    return paymentStatus == 'paid';
  }

  /// Chi hien thong bao da thanh toan sau khi verify qua check-payment-status.
  Future<bool> _verifyAllAdditionalPaymentsByOrderCode() async {
    if (_additionalCosts.isEmpty) return false;

    bool allPaid = true;
    for (final cost in List<AdditionalCost>.from(_additionalCosts)) {
      final orderCode = int.tryParse(cost.orderCode ?? '');
      if (orderCode == null) {
        allPaid = false;
        continue;
      }

      try {
        final isPaid = await _syncCostPaymentByOrderCode(
          cost: cost,
          orderCode: orderCode,
        );
        if (!isPaid) allPaid = false;
      } catch (e) {
        allPaid = false;
        debugPrint(
          '=== WARN: Khong the check payment orderCode $orderCode: $e ===',
        );
      }
    }

    return allPaid;
  }

  void _removeAdditionalCost(AdditionalCost cost) {
    setState(() {
      _additionalCosts.removeWhere((item) => item.id == cost.id);
    });
  }

  Future<void> _payAllAdditionalCostsQR() async {
    if (_isProcessingAdditionalPayment) return;
    setState(() => _isProcessingAdditionalPayment = true);

    try {
      // Thanh toán từng khoản chưa thanh toán
      final unpaidCosts = _additionalCosts.where((c) => !c.isPaid).toList();
      if (unpaidCosts.isEmpty) {
        final verifiedPaid = await _verifyAllAdditionalPaymentsByOrderCode();
        if (!mounted) return;
        _showMessage(
          verifiedPaid
              ? 'Tất cả chi phí đã được thanh toán'
              : 'Không còn chi phí chờ tạo QR. Vui lòng tải lại trạng thái thanh toán.',
          isError: !verifiedPaid,
        );
        setState(() => _isProcessingAdditionalPayment = false);
        return;
      }

      // Tính tổng số tiền của TẤT CẢ chi phí chưa thanh toán để gửi QR đúng tổng tiền.
      final totalUnpaid = unpaidCosts.fold<double>(
        0,
        (sum, c) => sum + (double.tryParse(c.amount) ?? 0),
      );
      final totalAmountInt = totalUnpaid.round();

      // Vẫn gắn additionalCostId của khoản đầu tiên để backend biết bối cảnh trả phí phát sinh,
      // nhưng override amount = tổng tiền tất cả khoản chưa thanh toán.
      final cost = unpaidCosts.first;
      final response = await _paymentService.createPayment(
        additionalCostId: cost.id,
        amount: totalAmountInt,
        method: 'QR',
      );
      if (!mounted) return;

      setState(() => _isProcessingAdditionalPayment = false);

      final qrUrl = response['qrImageUrl'] as String?;
      final orderCodeRaw = response['orderCode'];
      final orderCode =
          orderCodeRaw != null ? int.tryParse(orderCodeRaw.toString()) : null;

      if (qrUrl != null && orderCode != null && orderCode != 0) {
        _showQRDialog(qrUrl, orderCode, cost, unpaidCosts);
      } else {
        _showMessage('Không lấy được mã QR hoặc orderCode từ server.',
            isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingAdditionalPayment = false);
      _showMessage('Lỗi tạo thanh toán: $e', isError: true);
    }
  }

  void _showQRDialog(
    String qrImageUrl,
    int orderCode,
    AdditionalCost cost,
    List<AdditionalCost> coveredCosts,
  ) {
    _pollingHelper.showQRDialogAndPoll(
      context: context,
      qrImageUrl: qrImageUrl,
      orderCode: orderCode,
      onSuccess: () async {
        if (!mounted) return;
        final isPaid = await _syncCostPaymentByOrderCode(
          cost: cost,
          orderCode: orderCode,
        );
        if (!mounted) return;
        if (isPaid) {
          // QR đã cover tổng tất cả khoản chưa thanh toán, đánh dấu paid cho mọi cost còn lại.
          if (coveredCosts.length > 1) {
            setState(() {
              for (final c in coveredCosts) {
                if (c.id == cost.id) continue;
                _updateAdditionalCostPaymentStatus(
                  cost: c,
                  paymentStatus: 'paid',
                  paymentMethod: 'QR',
                );
              }
            });
          }
          _showMessage('Thanh toán thành công!');
          // Đồng bộ lại với backend để chắc chắn trạng thái đúng.
          await _refreshAdditionalCostStatuses();
        } else {
          await _refreshAdditionalCostStatuses();
        }
      },
      onFailed: () {
        if (!mounted) return;
        _showMessage('Thanh toán thất bại hoặc đã hết hạn.', isError: true);
      },
    );
  }

  /// Xác nhận thanh toán tiền mặt cho tất cả chi phí phát sinh.
  Future<void> _confirmAllCashPayments() async {
    if (_isProcessingAdditionalPayment) return;
    setState(() => _isProcessingAdditionalPayment = true);

    try {
      final unpaidCosts = _additionalCosts.where((c) => !c.isPaid).toList();
      for (final cost in unpaidCosts) {
        await _returnService.confirmCashPayment(costId: cost.id);
      }
      if (!mounted) return;
      setState(() => _isProcessingAdditionalPayment = false);
      _showMessage('Đã xác nhận thu tiền mặt cho tất cả chi phí phát sinh');
      // Refresh trạng thái từ server để đồng bộ UI
      await _refreshAdditionalCostStatuses();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingAdditionalPayment = false);
      _showMessage('Lỗi xác nhận tiền mặt: $e', isError: true);
    }
  }

  /// Hoàn tất biên bản trả xe (API 6.10).
  Future<void> _finalizeReturn() async {
    if (_isSubmitting) return;
    // Validate: chi phí phát sinh phải được thanh toán (sử dụng trạng thái thực từ API 6.8)
    if (_additionalCosts.isNotEmpty && !_allAdditionalCostsPaid) {
      _showMessage(
          'Vui lòng thanh toán tất cả chi phí phát sinh trước khi hoàn thành',
          isError: true);
      return;
    }
    // Validate required fields
    if (_vehicleRegistrationUrl == null ||
        _stampUrl == null ||
        _inspectionCertificateUrl == null ||
        _stampNumberCtrl.text.isEmpty ||
        _stampExpiryCtrl.text.isEmpty ||
        _certNumberCtrl.text.isEmpty ||
        _certExpiryCtrl.text.isEmpty) {
      _showMessage('Vui lòng tải lên đầy đủ giấy tờ bắt buộc', isError: true);
      return;
    }
    // Get signature
    final sigState = _signaturePadKey.currentState;
    if (sigState == null || !sigState.hasSigned) {
      _showMessage('Vui lòng ký xác nhận', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final Uint8List? sigBytes = await sigState.toPngBytes();
      if (sigBytes == null || sigBytes.isEmpty) {
        _showMessage('Không thể xuất chữ ký', isError: true);
        setState(() => _isSubmitting = false);
        return;
      }
      final sigBase64 = 'data:image/png;base64,${base64Encode(sigBytes)}';
      String? otherDocsJson;
      if (_otherDocumentUrls.isNotEmpty) {
        otherDocsJson = jsonEncode(_otherDocumentUrls);
      }
      await _returnService.finalizeReturn(
        orderId: widget.orderId,
        vehicleRegistrationUrl: _vehicleRegistrationUrl!,
        registrationNumber: _registrationNumberCtrl.text.isEmpty
            ? null
            : _registrationNumberCtrl.text,
        stampUrl: _stampUrl!,
        stampNumber: _stampNumberCtrl.text,
        stampExpiryDate: _stampExpiryCtrl.text,
        otherDocumentsUrls: otherDocsJson,
        receiptUrl: _receiptUrl,
        receiptNumber:
            _receiptNumberCtrl.text.isEmpty ? null : _receiptNumberCtrl.text,
        inspectionCertificateUrl: _inspectionCertificateUrl!,
        certificateNumber: _certNumberCtrl.text,
        certificateExpiryDate: _certExpiryCtrl.text,
        additionalNotes: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        customerSignature: sigBase64,
      );
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _returnStatus = 'completed';
      });
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('Lỗi hoàn tất: $e', isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.check_circle_rounded,
            color: Color(0xFF16A34A), size: 56),
        title: const Text('Hoàn thành'),
        content: const Text('Biên bản trả xe đã được tạo thành công.'),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor:
          isError ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  InputDecoration _inputDeco(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  @override
  void dispose() {
    _pollingHelper.dispose();
    _noteCtrl.dispose();
    _feeNameCtrl.dispose();
    _feeAmountCtrl.dispose();
    _feeDescCtrl.dispose();
    _feePhotoUrlCtrl.dispose();
    _feeNotesCtrl.dispose();
    _registrationNumberCtrl.dispose();
    _stampNumberCtrl.dispose();
    _stampExpiryCtrl.dispose();
    _certNumberCtrl.dispose();
    _certExpiryCtrl.dispose();
    _receiptNumberCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildSection1Photos(),
                  const SizedBox(height: 16),
                  _buildSection2Checklist(),
                  const SizedBox(height: 16),
                  _buildSection2_5Docs(),
                  const SizedBox(height: 16),
                  _buildSection3ExtraFees(),
                  const SizedBox(height: 16),
                  _buildSection4Note(),
                  const SizedBox(height: 16),
                  SignaturePadWidget(
                    key: _signaturePadKey,
                    title: '5. Chữ ký khách hàng',
                    hint: 'Yêu cầu khách hàng ký xác nhận đã nhận xe',
                    onSignatureChanged: (signed) =>
                        setState(() => _hasSigned = signed),
                  ),
                  if (_additionalCosts.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildSection6AdditionalPayment(),
                  ],
                  const SizedBox(height: 16),
                  _buildSaveButton(context),
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3))
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: CustomPaint(painter: _CirclePainter()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.arrow_back_rounded,
                            size: 18, color: Color(0xFF374151)),
                        SizedBox(width: 6),
                        Text('Quay lại',
                            style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF374151),
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Biên bản TRẢ xe',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827))),
                  const SizedBox(height: 3),
                  Text('${widget.plate} • ${widget.customerName}',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFDB2777)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.35),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _summaryRow('Khách hàng:', widget.customerName),
          const SizedBox(height: 8),
          _summaryRow('Loại xe:', widget.vehicleType),
          const SizedBox(height: 8),
          _summaryRow('Hãng xe:', widget.brand),
          const SizedBox(height: 8),
          _summaryRow('Màu sắc:', widget.color),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFFE9D5FF), fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
    String? hint,
    Color? hintBg,
    Color? hintText,
    IconData? hintIcon,
    Color? hintIconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x07000000), blurRadius: 10, offset: Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827))),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: hintBg ?? const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(hintIcon ?? Icons.lightbulb_outline_rounded,
                        color: hintIconColor ?? const Color(0xFFF59E0B),
                        size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(hint,
                          style: TextStyle(
                              fontSize: 12,
                              color: hintText ?? const Color(0xFFB45309))),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSection1Photos() {
    final vehicleReqs = _vehicleRequirements;

    if (_isLoadingRequirements) {
      return _buildSectionCard(
        icon: Icons.camera_alt_outlined,
        iconColor: const Color(0xFF2563EB),
        title: '1. Chụp ảnh thực tế của xe',
        child: const Center(
            child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator())),
      );
    }

    return _buildSectionCard(
      icon: Icons.camera_alt_outlined,
      iconColor: const Color(0xFF2563EB),
      title: '1. Chụp ảnh thực tế của xe ($_photoCount/${vehicleReqs.length})',
      hint: 'Bắt buộc chụp đầy đủ ảnh để lưu biên bản',
      hintBg: const Color(0xFFFFF7ED),
      hintText: const Color(0xFFB45309),
      hintIcon: Icons.warning_amber_rounded,
      hintIconColor: const Color(0xFFF59E0B),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: vehicleReqs.map((req) {
          final uploaded = _uploadedMap[req.id];
          final isUploading = _uploadingMap[req.id] == true;
          final localPath = _localFileMap[req.id];

          return GestureDetector(
            onTap: isUploading ? null : () => _pickAndUploadImage(req),
            child: Container(
              decoration: BoxDecoration(
                color: uploaded != null
                    ? const Color(0xFFEFFEF2)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: uploaded != null
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD1D5DB),
                  width: uploaded != null ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  _buildRequirementItem(req, uploaded, isUploading, localPath),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRequirementItem(ImageRequirement req, UploadedMedia? uploaded,
      bool isUploading, String? localPath) {
    if (isUploading && localPath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(localPath),
              fit: BoxFit.cover,
              color: Colors.black45,
              colorBlendMode: BlendMode.darken),
          const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      );
    }

    if (uploaded != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          localPath != null
              ? Image.file(File(localPath), fit: BoxFit.cover)
              : Image.network(uploaded.thumbnailUrl, fit: BoxFit.cover),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: const Color(0xCC16A34A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(req.positionEmoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Flexible(
                      child: Text(req.name,
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
          const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.check_circle_rounded,
                  color: Color(0xFF16A34A), size: 22)),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined,
            color: Color(0xFF9CA3AF), size: 24),
        const SizedBox(height: 6),
        Text(req.positionEmoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text(req.name,
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildSection2Checklist() {
    final labels = VehicleReturnService.checklistLabels;
    final checkedCount = _checklistValues.where((v) => v).length;

    return _buildSectionCard(
      icon: Icons.check_rounded,
      iconColor: const Color(0xFF16A34A),
      title: '2. Checklist kiểm tra ($checkedCount/${labels.length})',
      hint: _checklistSubmitted
          ? '✅ Đã lưu checklist'
          : 'Mỗi hạng mục đã check phải có ảnh kèm theo',
      hintBg: _checklistSubmitted
          ? const Color(0xFFEFFEF2)
          : const Color(0xFFEFFEF2),
      hintText: _checklistSubmitted
          ? const Color(0xFF15803D)
          : const Color(0xFF00A85A),
      hintIcon: _checklistSubmitted
          ? Icons.check_circle
          : Icons.lightbulb_outline_rounded,
      hintIconColor: _checklistSubmitted
          ? const Color(0xFF16A34A)
          : const Color(0xFFF59E0B),
      child: Column(
        children: [
          ...List.generate(labels.length, (i) {
            return _buildChecklistItem(labels[i], i);
          }),
          if (!_checklistSubmitted) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _submitChecklist,
              child: Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                    child: Text('Lưu checklist',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14))),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String label, int index) {
    final requirement = _checklistRequirementAt(index);
    final uploaded = requirement == null ? null : _uploadedMap[requirement.id];
    final isUploading =
        requirement != null && _uploadingMap[requirement.id] == true;
    final localPath =
        requirement == null ? null : _localFileMap[requirement.id];
    final isChecked = _checklistValues[index];
    final hasImage = uploaded != null || (isUploading && localPath != null);
    final active = isChecked || hasImage;

    return GestureDetector(
      onTap: isUploading ? null : () => _handleChecklistTap(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEFFEF2) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFF00C853) : const Color(0xFFE5E7EB),
            width: active ? 1.5 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isChecked ? const Color(0xFF8B6F4E) : Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isChecked
                          ? const Color(0xFF8B6F4E)
                          : const Color(0xFF9CA3AF),
                      width: 1.3,
                    ),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: isChecked
                          ? const Color(0xFF166534)
                          : const Color(0xFF111827),
                      fontWeight: isChecked ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isChecked)
                  const Icon(Icons.check_rounded,
                      color: Color(0xFF00C853), size: 22),
              ],
            ),
            if (hasImage) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 2.35,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (localPath != null)
                        Image.file(File(localPath), fit: BoxFit.cover)
                      else
                        Image.network(uploaded!.thumbnailUrl,
                            fit: BoxFit.cover),
                      if (isUploading)
                        Container(
                          color: Colors.black45,
                          child: const Center(
                            child:
                                CircularProgressIndicator(color: Colors.white),
                          ),
                        ),
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00B850),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.check_rounded,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 5),
                              Text(
                                'Đã chụp',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!isUploading && requirement != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: GestureDetector(
                            onTap: () =>
                                _removeChecklistImage(index, requirement),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF3B47),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection2_5Docs() {
    return _buildSectionCard(
      icon: Icons.insert_drive_file_outlined,
      iconColor: const Color(0xFF374151),
      title: '2.5. Giấy tờ kiểm định',
      hint: 'Bắt buộc tải lên các giấy tờ kiểm định',
      hintBg: const Color(0xFFF9FAFB),
      hintText: const Color(0xFF6B7280),
      hintIcon: Icons.warning_amber_rounded,
      hintIconColor: const Color(0xFFF59E0B),
      child: Column(
        children: [
          _buildDocItem(
            title: 'Giấy đăng ký xe',
            subtitle: 'Số:',
            imageUrl: _vehicleRegistrationUrl,
            onPickImage: () => _pickDocImage(
              requirement: _findDocumentRequirement(
                positions: ['VEHICLE_REGISTRATION', 'REGISTRATION'],
                nameKeywords: ['dang ky', 'đăng ký', 'registration'],
              ),
              onUploaded: (url) =>
                  setState(() => _vehicleRegistrationUrl = url),
            ),
          ),
          _buildDocItem(
            title: 'Tem đăng kiểm',
            subtitle: 'Số:\nHạn sử dụng:',
            imageUrl: _stampUrl,
            onPickImage: () => _pickDocImage(
              requirement: _findDocumentRequirement(
                positions: ['INSPECTION_STAMP', 'STAMP'],
                nameKeywords: ['tem', 'stamp'],
              ),
              onUploaded: (url) => setState(() => _stampUrl = url),
            ),
          ),
          _buildDocItem(
            title: 'Các giấy tờ khác',
            subtitle: '(${_otherDocumentUrls.length} file)',
            imageUrl:
                _otherDocumentUrls.isNotEmpty ? _otherDocumentUrls.first : null,
            onPickImage: () => _pickDocImage(
              requirement: _findDocumentRequirement(
                positions: ['OTHER_DOCUMENT', 'OTHER'],
                nameKeywords: ['khac', 'khác', 'other'],
              ),
              onUploaded: (url) => setState(() => _otherDocumentUrls.add(url)),
            ),
          ),
          _buildDocItem(
            title: 'Biên lai',
            subtitle: 'Số:',
            imageUrl: _receiptUrl,
            onPickImage: () => _pickDocImage(
              requirement: _findDocumentRequirement(
                positions: ['RECEIPT'],
                nameKeywords: ['bien lai', 'biên lai', 'receipt'],
                category: 'RECEIPT',
              ),
              onUploaded: (url) => setState(() => _receiptUrl = url),
            ),
          ),
          _buildDocItem(
            title: 'Giấy chứng nhận kiểm định',
            subtitle: 'Số:\nHạn sử dụng:',
            imageUrl: _inspectionCertificateUrl,
            onPickImage: () => _pickDocImage(
              requirement: _findDocumentRequirement(
                positions: ['INSPECTION_CERTIFICATE', 'CERTIFICATE'],
                nameKeywords: ['chung nhan', 'chứng nhận', 'certificate'],
              ),
              onUploaded: (url) =>
                  setState(() => _inspectionCertificateUrl = url),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocItem({
    required String title,
    required String subtitle,
    String? imageUrl,
    required VoidCallback onPickImage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
              image: imageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: imageUrl == null
                ? const Icon(Icons.insert_drive_file_outlined,
                    color: Color(0xFF9CA3AF))
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827))),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          GestureDetector(
            onTap: onPickImage,
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.upload_outlined, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDocImage({
    required ImageRequirement? requirement,
    required ValueChanged<String> onUploaded,
  }) async {
    if (requirement == null) {
      _showMessage('Không tìm thấy cấu hình ảnh giấy tờ để upload',
          isError: true);
      return;
    }

    final source =
        await ImagePickerSheet.show(context, title: 'Chọn ảnh giấy tờ');
    if (source == null) return;
    final picked =
        await _imagePicker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !mounted) return;

    setState(() => _isSubmitting = true);
    try {
      final uploadedMedia = await _receiptService.uploadMedia(
        file: File(picked.path),
        orderId: widget.orderId,
        requirementId: requirement.id,
      );
      if (!mounted) return;
      setState(() {
        _uploadedMap[requirement.id] = uploadedMedia;
        _localFileMap[requirement.id] = picked.path;
        _isSubmitting = false;
      });
      onUploaded(uploadedMedia.url);
      _showMessage('Tải ảnh thành công');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage('Lỗi tải ảnh: $e', isError: true);
    }
  }

  Widget _buildSection3ExtraFees() {
    return _buildSectionCard(
      icon: Icons.attach_money_rounded,
      iconColor: const Color(0xFFEA580C),
      title: '3. Chi phí phát sinh (tùy chọn)',
      child: Column(
        children: [
          ..._additionalCosts.map((cost) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cost.costName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF111827))),
                              const SizedBox(height: 3),
                              Text(cost.displayAmount,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFEA580C))),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeAdditionalCost(cost),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.delete_outline_rounded,
                                color: Color(0xFFDC2626), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
          if (_additionalCosts.isNotEmpty) ...[
            const Divider(height: 18, color: Color(0xFFE5E7EB)),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tổng chi phí phát sinh:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  Text(
                    _formatCurrency(_totalAdditionalCost),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ],
              ),
            ),
          ],
          GestureDetector(
            onTap: _showAddFeeDialog,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFD1D5DB), style: BorderStyle.solid),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_rounded, color: Color(0xFF6B7280), size: 18),
                  SizedBox(width: 6),
                  Text('Thêm chi phí phát sinh',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection4Note() {
    return _buildSectionCard(
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF6B7280),
      title: '4. Ghi chú chung (tùy chọn)',
      child: TextField(
        controller: _noteCtrl,
        maxLines: 4,
        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        decoration: InputDecoration(
          hintText: 'Nhập ghi chú thêm về việc trả xe...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
      ),
    );
  }

  // _buildSection5Signature đã được thay thế bởi SignaturePadWidget
  // (xem build method ở trên)

  Widget _buildSection6AdditionalPayment() {
    final bool hasAdditionalCosts = _additionalCosts.isNotEmpty;
    final bool allPaid = _allAdditionalCostsPaid;

    return _buildSectionCard(
      icon: Icons.account_balance_wallet_outlined,
      iconColor: const Color(0xFFEA580C),
      title: '6. Phương thức thanh toán phát sinh',
      hint: !hasAdditionalCosts
          ? 'Chưa có chi phí phát sinh cần thanh toán'
          : allPaid
              ? '✅ Đã thanh toán tất cả chi phí phát sinh'
              : 'Chọn phương thức thanh toán cho chi phí phát sinh',
      hintBg: allPaid ? const Color(0xFFEFFEF2) : const Color(0xFFFFF7ED),
      hintText: allPaid ? const Color(0xFF15803D) : const Color(0xFFB45309),
      hintIcon: allPaid ? Icons.check_circle : Icons.lightbulb_outline_rounded,
      hintIconColor:
          allPaid ? const Color(0xFF16A34A) : const Color(0xFFF59E0B),
      child: Column(
        children: [
          // Tổng chi phí
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng chi phí phát sinh:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  ),
                ),
                Text(
                  _formatCurrency(_totalAdditionalCost),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ],
            ),
          ),
          if (!hasAdditionalCosts) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.info_outline_rounded,
                      color: Color(0xFF6B7280), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Chưa có chi phí phát sinh',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!allPaid) ...[
            // Chọn phương thức thanh toán
            Row(
              children: [
                // VietQR
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _additionalPaymentMethod = 'QR'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _additionalPaymentMethod == 'QR'
                            ? Colors.white
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _additionalPaymentMethod == 'QR'
                              ? const Color(0xFFEA580C)
                              : const Color(0xFFE5E7EB),
                          width: _additionalPaymentMethod == 'QR' ? 2 : 1,
                        ),
                        boxShadow: _additionalPaymentMethod == 'QR'
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFFEA580C).withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            size: 32,
                            color: _additionalPaymentMethod == 'QR'
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'VietQR',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _additionalPaymentMethod == 'QR'
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Quét mã thanh toán',
                            style: TextStyle(
                              fontSize: 11,
                              color: _additionalPaymentMethod == 'QR'
                                  ? const Color(0xFF374151)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tiền mặt
                Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _additionalPaymentMethod = 'CASH'),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _additionalPaymentMethod == 'CASH'
                            ? Colors.white
                            : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _additionalPaymentMethod == 'CASH'
                              ? const Color(0xFFEA580C)
                              : const Color(0xFFE5E7EB),
                          width: _additionalPaymentMethod == 'CASH' ? 2 : 1,
                        ),
                        boxShadow: _additionalPaymentMethod == 'CASH'
                            ? [
                                BoxShadow(
                                  color:
                                      const Color(0xFFEA580C).withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 32,
                            color: _additionalPaymentMethod == 'CASH'
                                ? const Color(0xFFEA580C)
                                : const Color(0xFF9CA3AF),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tiền mặt',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _additionalPaymentMethod == 'CASH'
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Thu tiền trực tiếp',
                            style: TextStyle(
                              fontSize: 11,
                              color: _additionalPaymentMethod == 'CASH'
                                  ? const Color(0xFF374151)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Nút thanh toán
            GestureDetector(
              onTap: _isProcessingAdditionalPayment
                  ? null
                  : () {
                      if (_additionalPaymentMethod == 'QR') {
                        _payAllAdditionalCostsQR();
                      } else {
                        _confirmAllCashPayments();
                      }
                    },
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFF97316)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEA580C).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isProcessingAdditionalPayment
                    ? const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _additionalPaymentMethod == 'QR'
                                ? Icons.qr_code_2_rounded
                                : Icons.payments_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _additionalPaymentMethod == 'QR'
                                ? 'Gửi yêu cầu thanh toán QR'
                                : 'Xác nhận thu tiền mặt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ] else ...[
            // Trạng thái đã thanh toán
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFFEF2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Đã thanh toán thành công',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return _isSubmitting
        ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            ),
          )
        : GestureDetector(
            onTap: _finalizeReturn,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.description_outlined,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Lưu biên bản trả xe & Hoàn thành',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _navItem(Icons.home_rounded, 'Trang chủ', false),
              _navItem(Icons.receipt_long_outlined, 'Đơn hàng', true),
              _navItem(Icons.person_outline_rounded, 'Cá nhân', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool selected) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: selected ? const Color(0xFF16A34A) : Colors.grey.shade400),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: selected
                      ? const Color(0xFF16A34A)
                      : Colors.grey.shade400)),
        ],
      ),
    );
  }
}

// _ExtraFee class đã được thay thế bởi AdditionalCost model.

class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width - 32, size.height * 0.35), 48, paint);
    canvas.drawCircle(Offset(size.width - 90, size.height * 0.25), 28, paint);
    canvas.drawCircle(Offset(24, size.height * 0.8), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
