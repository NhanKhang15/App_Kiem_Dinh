import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:vehicle_registration_app/models/image_requirement.dart';
import 'package:vehicle_registration_app/models/uploaded_media.dart';
import 'package:vehicle_registration_app/services/payment_service.dart';
import 'package:vehicle_registration_app/services/vehicle_receipt_service.dart';

enum ReceiptProcessStep {
  contractSign,
  payment,
  captureDocs,
}

class VehicleReceiptScreen extends StatefulWidget {
  final String orderId;
  final String customerName;
  final String plate;
  final String vehicleType;
  final String brand;
  final String totalCost;

  const VehicleReceiptScreen({
    super.key,
    this.orderId = 'DK002',
    this.customerName = 'Nguyễn Thị Hương',
    this.plate = '29B-678.90',
    this.vehicleType = 'Ô tô con',
    this.brand = 'Honda City',
    this.totalCost = '340.000đ',
  });

  @override
  State<VehicleReceiptScreen> createState() => _VehicleReceiptScreenState();
}

class _VehicleReceiptScreenState extends State<VehicleReceiptScreen> {
  final _nameCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _idCtrl = TextEditingController();
  final _idIssueDateCtrl = TextEditingController();
  final _idIssuePlaceCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _contractScrollCtrl = ScrollController();
  final SignatureController _signatureCtrl = SignatureController(
    penStrokeWidth: 2.5,
    penColor: Color(0xFFEA580C),
    exportBackgroundColor: Colors.white,
  );

  final ImagePicker _imagePicker = ImagePicker();
  bool _hasSigned = false;
  bool _showSignaturePad = false;
  bool _paymentCompleted = false;
  bool _isSubmitting = false;
  int _paymentMethod = 0;
  ReceiptProcessStep _currentStep = ReceiptProcessStep.contractSign;
  late final VehicleReceiptService _receiptService;
  late final PaymentService _paymentService;
  Timer? _pollingTimer;

  // === State mới cho API upload ảnh ===
  /// Danh sách requirement ảnh từ API 1 (dynamic, thay thế hardcode)
  List<ImageRequirement> _requirements = [];
  /// Map requirement_id -> UploadedMedia (ảnh đã upload thành công)
  Map<int, UploadedMedia> _uploadedMap = {};
  /// Map requirement_id -> bool (đang upload)
  Map<int, bool> _uploadingMap = {};
  /// Map requirement_id -> local file path (ảnh vừa chụp, chưa/đang upload)
  Map<int, String> _localFileMap = {};
  /// Trạng thái loading khi fetch requirements
  bool _isLoadingRequirements = true;
  /// Lỗi khi fetch requirements
  String? _requirementsError;

  /// Lọc requirements theo category VEHICLE
  List<ImageRequirement> get _vehicleRequirements =>
      _requirements.where((r) => r.category == 'VEHICLE').toList();

  /// Lọc requirements theo category DOCUMENT
  List<ImageRequirement> get _documentRequirements =>
      _requirements.where((r) => r.category == 'DOCUMENT').toList();

  /// Số ảnh xe đã upload thành công
  int get _photoCount => _vehicleRequirements
      .where((r) => _uploadedMap.containsKey(r.id))
      .length;

  /// Số giấy tờ đã upload thành công
  int get _documentCount => _documentRequirements
      .where((r) => _uploadedMap.containsKey(r.id))
      .length;

  /// Tất cả ảnh required đã upload chưa
  bool get _allRequiredUploaded => _requirements
      .where((r) => r.isRequired)
      .every((r) => _uploadedMap.containsKey(r.id));

  /// Lọc requirements theo category CHECKLIST
  List<ImageRequirement> get _checklistRequirements =>
      _requirements.where((r) => r.category == 'CHECKLIST').toList();

  /// Số checklist đã upload thành công
  int get _checkCount => _checklistRequirements
      .where((r) => _uploadedMap.containsKey(r.id))
      .length;

  bool get _canGoToPaymentStep => true;
  bool get _canCompleteProcess =>
      _allRequiredUploaded && _checkCount == _checklistRequirements.length;

  bool get _infoFilled =>
      _nameCtrl.text.isNotEmpty &&
      _birthDateCtrl.text.isNotEmpty &&
      _idCtrl.text.isNotEmpty &&
      _idIssueDateCtrl.text.isNotEmpty &&
      _idIssuePlaceCtrl.text.isNotEmpty &&
      _phoneCtrl.text.isNotEmpty &&
      _addressCtrl.text.isNotEmpty;

  String _contractValue(
    TextEditingController controller, [
    String placeholder = '.................................',
  ]) {
    return controller.text.trim().isEmpty
        ? placeholder
        : controller.text.trim();
  }

  String _currentContractDateText() {
    final now = DateTime.now();
    return 'Hôm nay, ngày ${now.day} tháng ${now.month} năm ${now.year}, tại Hồ Chí Minh';
  }

  Widget _contractLine({
    required String label,
    required String value,
    String? suffix,
    bool boldLabel = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF1F2937),
          ),
          children: [
            TextSpan(
              text: label,
              style: TextStyle(
                  fontWeight: boldLabel ? FontWeight.w700 : FontWeight.w500),
            ),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF2563EB),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (suffix != null) TextSpan(text: suffix),
          ],
        ),
      ),
    );
  }

  /// Chuyển đổi ngày từ DD/MM/YYYY sang YYYY-MM-DD cho API.
  String _convertDateFormat(String input) {
    final parts = input.trim().split('/');
    if (parts.length == 3) {
      return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
    }
    return input; // trả nguyên nếu không đúng format
  }

  @override
  void initState() {
    super.initState();
    _receiptService = VehicleReceiptService();
    _paymentService = PaymentService();
    _signatureCtrl.onDrawEnd = () {
      if (!mounted) return;
      setState(() => _hasSigned = _signatureCtrl.isNotEmpty);
    };
    // Fetch danh sách requirements và ảnh đã upload
    _loadRequirementsAndMedia();
  }

  /// Gọi API 1 (image-requirements) và API 3 (uploaded media) song song.
  Future<void> _loadRequirementsAndMedia() async {
    setState(() {
      _isLoadingRequirements = true;
      _requirementsError = null;
    });

    try {
      final results = await Future.wait([
        _receiptService.getImageRequirements(stage: 'RECEIVE'),
        _receiptService.getUploadedMedia(
          orderId: widget.orderId,
          stage: 'RECEIVE',
        ),
      ]);

      if (!mounted) return;

      final requirements = results[0] as List<ImageRequirement>;
      final uploadedList = results[1] as List<UploadedMedia>;

      // Build map requirement_id -> UploadedMedia
      final uploadedMap = <int, UploadedMedia>{};
      for (final media in uploadedList) {
        uploadedMap[media.requirementId] = media;
      }

      setState(() {
        _requirements = requirements;
        _uploadedMap = uploadedMap;
        _isLoadingRequirements = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingRequirements = false;
        _requirementsError = 'Không thể tải danh sách ảnh yêu cầu: $e';
      });
      print('=== DEBUG: LỖI loadRequirementsAndMedia ===');
      print(e.toString());
    }
  }

  /// Chọn và upload ảnh cho một requirement cụ thể.
  /// [requirement] - requirement từ API 1 (chứa id, name, category, position)
  Future<void> _pickAndUploadImage(ImageRequirement requirement) async {
    final alreadyUploaded = _uploadedMap.containsKey(requirement.id);

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                requirement.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFF2563EB)),
                title: const Text('Chụp ảnh'),
                subtitle: const Text('Mở camera để chụp'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF16A34A)),
                title: const Text('Thư viện ảnh'),
                subtitle: const Text('Chọn ảnh từ thiết bị'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              if (alreadyUploaded)
                ListTile(
                  leading: const Icon(Icons.refresh_rounded,
                      color: Color(0xFFF59E0B)),
                  title: const Text('Chụp lại'),
                  subtitle: const Text('Thay thế ảnh đã upload'),
                  onTap: () => Navigator.pop(ctx, ImageSource.camera),
                ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    if (picked == null || !mounted) return;

    // Lưu local path và bắt đầu upload
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

      _showMessage(
        '${requirement.name} - Upload thành công!',
        backgroundColor: const Color(0xFF16A34A),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingMap[requirement.id] = false;
      });

      String errorMsg = 'Lỗi upload ${requirement.name}';
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        final firstError = data.values.firstWhere(
          (v) => v != null,
          orElse: () => null,
        );
        if (firstError is List && firstError.isNotEmpty) {
          errorMsg = firstError.first.toString();
        } else if (firstError is String) {
          errorMsg = firstError;
        }
      }
      _showMessage(errorMsg, backgroundColor: const Color(0xFFDC2626));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingMap[requirement.id] = false;
      });
      _showMessage(
        'Lỗi upload: $e',
        backgroundColor: const Color(0xFFDC2626),
      );
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _nameCtrl.dispose();
    _birthDateCtrl.dispose();
    _idCtrl.dispose();
    _idIssueDateCtrl.dispose();
    _idIssuePlaceCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _noteCtrl.dispose();
    _contractScrollCtrl.dispose();
    _signatureCtrl.dispose();
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
                  _buildProcessStepper(),
                  const SizedBox(height: 18),
                  _buildSummaryCard(),
                  const SizedBox(height: 18),
                  if (_currentStep == ReceiptProcessStep.contractSign) ...[
                    _buildStep1Content(),
                  ] else if (_currentStep == ReceiptProcessStep.payment) ...[
                    _buildStep2Content(),
                  ] else ...[
                    _buildStep3Content(),
                  ],
                ],
              ),
            ),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  void _showMessage(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  bool _validateSection1() {
    if (!_hasSigned) {
      _showMessage('Vui lòng xác nhận chữ ký trước khi tiếp tục.', backgroundColor: const Color(0xFFDC2626));
      return false;
    }
    if (_nameCtrl.text.trim().isEmpty || _birthDateCtrl.text.trim().isEmpty || 
        _idCtrl.text.trim().isEmpty || _idIssueDateCtrl.text.trim().isEmpty || 
        _idIssuePlaceCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty || 
        _addressCtrl.text.trim().isEmpty) {
      _showMessage('Vui lòng điền đầy đủ các thông tin bắt buộc.', backgroundColor: const Color(0xFFDC2626));
      return false;
    }
    final dateRegExp = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!dateRegExp.hasMatch(_birthDateCtrl.text.trim()) || !dateRegExp.hasMatch(_idIssueDateCtrl.text.trim())) {
      _showMessage('Ngày tháng phải đúng định dạng dd/MM/yyyy.', backgroundColor: const Color(0xFFDC2626));
      return false;
    }
    final phoneText = _phoneCtrl.text.trim();
    if (phoneText.length != 10 || !RegExp(r'^\d+$').hasMatch(phoneText)) {
      _showMessage('Số điện thoại phải gồm đúng 10 chữ số.', backgroundColor: const Color(0xFFDC2626));
      return false;
    }
    final idText = _idCtrl.text.trim();
    if (idText.length < 9 || idText.length > 12 || !RegExp(r'^\d+$').hasMatch(idText)) {
      _showMessage('CMND/CCCD phải gồm từ 9 đến 12 chữ số.', backgroundColor: const Color(0xFFDC2626));
      return false;
    }
    return true;
  }

  void _goToPaymentStep() {
    if (!_validateSection1()) return;
    setState(() => _currentStep = ReceiptProcessStep.payment);
  }

  Future<void> _submitPayment() async {
    if (!_validateSection1()) return;

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final numericIdStr = widget.orderId.replaceAll(RegExp(r'[^0-9]'), '');
      final orderIdInt = int.tryParse(numericIdStr) ?? 0;

      final methodStr = _paymentMethod == 0 ? 'QR' : 'CASH';
      final response = await _paymentService.createPayment(
        orderId: orderIdInt,
        method: methodStr,
      );

      if (!mounted) return;

      if (_paymentMethod == 1) {
        // Tiền mặt
        setState(() {
          _paymentCompleted = true;
          _isSubmitting = false;
        });
        _showMessage(
          'Khách hàng đã thanh toán tiền mặt thành công!',
          backgroundColor: const Color(0xFF16A34A),
        );
      } else {
        // QR PayOS
        setState(() => _isSubmitting = false);
        final qrImageUrl = response['qrImageUrl'] as String?;
        final orderCode = response['orderCode'];
        if (qrImageUrl != null && orderCode != null) {
          _showQRDialog(qrImageUrl, int.tryParse(orderCode.toString()) ?? 0);
        } else {
          _showMessage('Không lấy được mã QR hoặc orderCode từ server.', backgroundColor: const Color(0xFFDC2626));
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(e.toString().replaceAll('Exception: ', ''), backgroundColor: const Color(0xFFDC2626));
    }
  }

  void _showQRDialog(String qrImageUrl, int orderCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Quét mã QR thanh toán', textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  qrImageUrl,
                  width: 250,
                  height: 250,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    width: 250,
                    height: 250,
                    child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Vui lòng khách hàng quét mã để thanh toán.', textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const CircularProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Đang chờ hệ thống PayOS...', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _pollingTimer?.cancel();
                Navigator.pop(ctx);
              },
              child: const Text('Huỷ / Đóng'),
            ),
          ],
        );
      },
    );

    // Bắt đầu polling
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final statusRes = await _paymentService.checkPaymentStatus(orderCode);
        if (statusRes['status'] == 'SUCCESS') {
          timer.cancel();
          if (!mounted) return;
          Navigator.pop(context); // Đóng popup
          setState(() {
            _paymentCompleted = true;
          });
          _showMessage('Khách hàng đã thanh toán QR thành công!', backgroundColor: const Color(0xFF16A34A));
        } else if (statusRes['status'] == 'FAILED') {
          timer.cancel();
          if (!mounted) return;
          Navigator.pop(context); // Đóng popup
          _showMessage('Thanh toán thất bại hoặc đã hết hạn.', backgroundColor: const Color(0xFFDC2626));
        }
      } catch (e) {
        print('Polling error: $e');
      }
    });
  }

  void _goToCaptureStep() {
    if (!_paymentCompleted) {
      _showMessage(
        'Vui lòng hoàn tất thanh toán trước khi tiếp tục.',
        backgroundColor: const Color(0xFFDC2626),
      );
      return;
    }
    setState(() => _currentStep = ReceiptProcessStep.captureDocs);
  }

  Future<void> _completeProcess() async {
    if (!_canCompleteProcess) {
      _showMessage(
        'Vui lòng chụp đủ ảnh xe, checklist và giấy tờ trước khi hoàn thành.',
        backgroundColor: const Color(0xFFDC2626),
      );
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      // Export chữ ký thành PNG bytes
      final Uint8List? signatureBytes = await _signatureCtrl.toPngBytes();
      if (signatureBytes == null || signatureBytes.isEmpty) {
        _showMessage(
          'Không thể xuất chữ ký. Vui lòng ký lại.',
          backgroundColor: const Color(0xFFDC2626),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      // Gọi API
      await _receiptService.submitVehicleReceipt(
        orderId: widget.orderId,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerAddress: _addressCtrl.text.trim(),
        customerDateOfBirth: _convertDateFormat(_birthDateCtrl.text.trim()),
        customerIdNumber: _idCtrl.text.trim(),
        customerIdIssuedDate: _convertDateFormat(_idIssueDateCtrl.text.trim()),
        customerIdIssuedPlace: _idIssuePlaceCtrl.text.trim(),
        additionalNotes: _noteCtrl.text.trim(),
        paymentConfirmed: _paymentCompleted,
        signatureBytes: signatureBytes,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      // Hiển thị dialog thành công
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF16A34A),
              size: 56,
            ),
            title: const Text('Hoàn thành quy trình'),
            content: const Text(
              'Biên bản nhận xe đã được lưu thành công lên hệ thống.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(); // Quay về màn trước
                },
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      String errorMsg = 'Lỗi khi gửi biên bản nhận xe.';
      if (e.response?.data is Map) {
        final data = e.response!.data as Map;
        // Lấy message lỗi đầu tiên từ response
        final firstError = data.values.firstWhere(
          (v) => v != null,
          orElse: () => null,
        );
        if (firstError is List && firstError.isNotEmpty) {
          errorMsg = firstError.first.toString();
        } else if (firstError is String) {
          errorMsg = firstError;
        }
      } else if (e.message != null) {
        errorMsg = e.message!;
      }

      _showMessage(errorMsg, backgroundColor: const Color(0xFFDC2626));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showMessage(
        'Đã xảy ra lỗi không xác định: $e',
        backgroundColor: const Color(0xFFDC2626),
      );
    }
  }

  Widget _buildStep1Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection1(),
        const SizedBox(height: 16),
        _buildAuthorizationContractSection(),
        const SizedBox(height: 16),
        _buildSignatureSection(),
        const SizedBox(height: 16),
        _buildPrimaryButton(
          label: 'Tiếp tục thanh toán',
          icon: Icons.arrow_forward_rounded,
          onTap: _goToPaymentStep,
          enabled: _canGoToPaymentStep,
        ),
      ],
    );
  }

  Widget _buildStep2Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection6(),
        const SizedBox(height: 16),
        if (!_paymentCompleted) ...[
          _buildSubmitButton(),
          const SizedBox(height: 16),
        ] else ...[
          _buildPaymentSuccessCard(),
          const SizedBox(height: 16),
          _buildPrimaryButton(
            label: 'Tiếp tục chụp ảnh xe & giấy tờ',
            icon: Icons.camera_alt_rounded,
            onTap: _goToCaptureStep,
          ),
          const SizedBox(height: 16),
        ],
        _buildSecondaryButton(
          label: 'Quay lại',
          onTap: () => setState(() {
            _currentStep = ReceiptProcessStep.contractSign;
          }),
        ),
      ],
    );
  }

  Widget _buildStep3Content() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection2(),
        const SizedBox(height: 16),
        _buildSection3(),
        const SizedBox(height: 16),
        _buildDocumentSection(),
        const SizedBox(height: 16),
        _buildSection4(),
        const SizedBox(height: 16),
        _buildCompletionStatus(),
        const SizedBox(height: 16),
        _isSubmitting
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                    color: Color(0xFF16A34A),
                  ),
                ),
              )
            : _buildPrimaryButton(
                label: 'Hoàn thành quy trình nhận xe',
                icon: Icons.task_alt_rounded,
                onTap: _completeProcess,
                enabled: _canCompleteProcess,
                colors: const [Color(0xFF16A34A), Color(0xFF16A34A)],
              ),
        const SizedBox(height: 16),
        _buildSecondaryButton(
          label: 'Quay lại',
          onTap: () => setState(() {
            _currentStep = ReceiptProcessStep.payment;
          }),
        ),
      ],
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
              color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 3)),
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
                  const Text(
                    'Biên bản NHẬN xe',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${widget.plate} • ${widget.customerName}',
                    style:
                        const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _summaryRow('Khách hàng:', widget.customerName),
          const SizedBox(height: 8),
          _summaryRow('Loại xe:', widget.vehicleType),
          const SizedBox(height: 8),
          _summaryRow('Hãng xe:', widget.brand),
          const SizedBox(height: 8),
          _summaryRow('Tổng chi phí:', widget.totalCost, valueBig: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool valueBig = false}) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: valueBig ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
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

  Widget _inputField(
    String label,
    TextEditingController ctrl, {
    String? hint,
    int maxLines = 1,
    bool required = true,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151))),
            if (required)
              const Text(' *',
                  style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          inputFormatters: inputFormatters,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              borderSide:
                  const BorderSide(color: Color(0xFF16A34A), width: 1.5),
            ),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF3F4F6) : const Color(0xFFFAFAFA),
            suffixIcon: suffixIcon,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSection1() {
    return _buildSectionCard(
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF16A34A),
      title: '1. Thông tin khách hàng',
      hint: 'Thông tin này sẽ tự động điền vào biên bản ủy quyền',
      hintBg: const Color(0xFFEFF6FF),
      hintText: const Color(0xFF1D4ED8),
      hintIcon: Icons.lightbulb_outline_rounded,
      hintIconColor: const Color(0xFF3B82F6),
      child: Column(
        children: [
          _inputField('Họ và tên', _nameCtrl, hint: 'Nhập họ và tên đầy đủ'),
          _inputField(
            'Ngày sinh',
            _birthDateCtrl,
            hint: 'dd/mm/yyyy',
            keyboardType: TextInputType.number,
            inputFormatters: [_DateInputFormatter()],
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF6B7280)),
              onPressed: () => _selectDate(_birthDateCtrl),
            ),
          ),
          _inputField(
            'CMND/CCCD',
            _idCtrl,
            hint: 'Nhập số CMND/CCCD (9-12 số)',
            keyboardType: TextInputType.number,
          ),
          _inputField(
            'Ngày cấp CMND/CCCD',
            _idIssueDateCtrl,
            hint: 'dd/mm/yyyy',
            keyboardType: TextInputType.number,
            inputFormatters: [_DateInputFormatter()],
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF6B7280)),
              onPressed: () => _selectDate(_idIssueDateCtrl),
            ),
          ),
          _inputField('Nơi cấp CMND/CCCD', _idIssuePlaceCtrl,
              hint: 'Nhập nơi cấp'),
          _inputField(
            'Số điện thoại',
            _phoneCtrl,
            hint: 'Nhập số điện thoại (10 số)',
            keyboardType: TextInputType.phone,
          ),
          _inputField('Địa chỉ', _addressCtrl,
              hint: 'Nhập địa chỉ đầy đủ', maxLines: 2),
        ],
      ),
    );
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF16A34A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      setState(() {
        controller.text = formatted;
      });
    }
  }

  Widget _buildAuthorizationContractSection() {
    final name = _contractValue(_nameCtrl);
    final birthDate = _contractValue(_birthDateCtrl, '..............');
    final idNumber = _contractValue(_idCtrl, '................');
    final idIssueDate = _contractValue(_idIssueDateCtrl, '..............');
    final idIssuePlace =
        _contractValue(_idIssuePlaceCtrl, '..................................');
    final phone = _contractValue(_phoneCtrl);
    final address = _contractValue(_addressCtrl);
    final now = DateTime.now();
    final effectiveDate = '${now.day}/${now.month}/${now.year}';

    return _buildSectionCard(
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF16A34A),
      title: '2. Hợp đồng ủy quyền',
      hint: 'Khách hàng vui lòng đọc kỹ hợp đồng trước khi ký',
      hintBg: const Color(0xFFECFDF5),
      hintText: const Color(0xFF16A34A),
      hintIcon: Icons.assignment_outlined,
      hintIconColor: const Color(0xFF16A34A),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Scrollbar(
          controller: _contractScrollCtrl,
          thumbVisibility: true,
          radius: const Radius.circular(999),
          child: SizedBox(
            height: 380,
            child: SingleChildScrollView(
              controller: _contractScrollCtrl,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'CỘNG HOÀ XÃ HỘI CHỦ NGHĨA VIỆT NAM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      'ĐỘC LẬP - TỰ DO - HẠNH PHÚC',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text(
                      'HỢP ĐỒNG UỶ QUYỀN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Center(
                    child: Text(
                      '(V/v: Nhận xe ô tô và thực hiện thủ tục đăng kiểm)',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _currentContractDateText(),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'chúng tôi gồm có:',
                    style: TextStyle(
                        fontSize: 12, height: 1.5, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BÊN ỦY QUYỀN (BÊN A – CHỦ XE)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _contractLine(label: 'Họ và tên: ', value: name),
                  _contractLine(label: 'Ngày sinh: ', value: birthDate),
                  _contractLine(
                    label: 'Số CCCD/CMND/Hộ chiếu: ',
                    value: idNumber,
                    suffix: ' cấp ngày $idIssueDate nơi cấp $idIssuePlace',
                  ),
                  _contractLine(label: 'Địa chỉ thường trú: ', value: address),
                  _contractLine(label: 'Số điện thoại: ', value: phone),
                  const SizedBox(height: 6),
                  const Text(
                    'Là chủ sở hữu hợp pháp của xe ô tô có thông tin sau:',
                    style: TextStyle(
                        fontSize: 12, height: 1.5, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 8),
                  _contractLine(label: 'Nhãn hiệu xe: ', value: widget.brand),
                  _contractLine(label: 'Biển số: ', value: widget.plate),
                  _contractLine(
                    label: 'Số khung: ',
                    value: '.................................................',
                  ),
                  _contractLine(
                    label: 'Số máy: ',
                    value: '.................................................',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'BÊN ĐƯỢC ỦY QUYỀN (BÊN B – ĐƠN VỊ DỊCH VỤ)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TRUNG TÂM HỖ TRỢ DỊCH VỤ ĐĂNG KIỂM VIỆT DKV 50S\n'
                    'Mã số doanh nghiệp: 0316969591 - 00005\n'
                    'Địa chỉ trụ sở: 26B Đường 34 - Phường Thủ Đức – TP.HCM\n'
                    'Đại diện theo pháp luật: Đặng Hồng Nam - Chức vụ: Giám Đốc\n'
                    'Số điện thoại: 0944484444',
                    style: TextStyle(
                        fontSize: 12, height: 1.5, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ĐIỀU 1. NỘI DUNG VÀ PHẠM VI ỦY QUYỀN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 12, height: 1.55, color: Color(0xFF1F2937)),
                      children: [
                        TextSpan(
                          text:
                              'Bên A đồng ý ủy quyền cho Bên B thực hiện các công việc sau:\n'
                              '• Nhận xe ô tô nêu trên tại địa chỉ do Bên A chỉ định.\n'
                              '• Thay mặt Bên A điều khiển xe chỉ nhằm mục đích đưa xe đi đăng kiểm và đưa xe trở lại.\n'
                              '• Thực hiện các thủ tục đăng kiểm xe cơ giới theo quy định pháp luật.\n'
                              '• Nộp các khoản phí, lệ phí đăng kiểm (nếu có) theo thỏa thuận giữa hai bên.\n'
                              '• Nhận lại Giấy chứng nhận kiểm định và tem kiểm định để bàn giao cho Bên A.\n',
                        ),
                        TextSpan(
                          text:
                              '👉 Bên B không được sử dụng xe vào bất kỳ mục đích nào khác ngoài các nội dung nêu trên.',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ĐIỀU 2. THỜI HẠN ỦY QUYỀN',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thời hạn ủy quyền: từ ngày $effectiveDate cho đến khi đăng kiểm xong\n'
                    'Văn bản ủy quyền tự động chấm dứt hiệu lực sau khi Bên B hoàn thành việc bàn giao xe và giấy tờ liên quan cho Bên A.',
                    style: const TextStyle(
                        fontSize: 12, height: 1.55, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ĐIỀU 3. CAM KẾT CỦA BÊN B (ĐƠN VỊ DỊCH VỤ)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Thực hiện đúng phạm vi ủy quyền, tuân thủ luật giao thông đường bộ.\n'
                    '• Chịu trách nhiệm đối với các vi phạm giao thông phát sinh do lỗi của Bên B trong thời gian nhận và điều khiển xe.\n'
                    '• Bồi thường thiệt hại nếu xảy ra mất mát, hư hỏng xe do lỗi của Bên B.\n'
                    '• Không giao xe cho bên thứ ba khi chưa có sự đồng ý của Bên A (trừ trường hợp nhân sự của công ty thực hiện theo phân công nội bộ).',
                    style: TextStyle(
                        fontSize: 12, height: 1.55, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ĐIỀU 4. CAM KẾT CỦA BÊN A (CHỦ XE)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Cam kết xe đủ điều kiện lưu hành, không tranh chấp, không bị cầm cố, thế chấp trái pháp luật.\n'
                    '• Cung cấp đầy đủ, trung thực giấy tờ liên quan đến xe (đăng ký xe, bảo hiểm, giấy tờ khác nếu có).\n'
                    '• Chịu trách nhiệm đối với các lỗi kỹ thuật, tình trạng xe không đạt đăng kiểm không phát sinh từ quá trình vận chuyển của Bên B.\n'
                    '• Thanh toán đầy đủ chi phí dịch vụ theo thỏa thuận.',
                    style: TextStyle(
                        fontSize: 12, height: 1.55, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ĐIỀU 5. GIỚI HẠN TRÁCH NHIỆM',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bên B không chịu trách nhiệm đối với:\n'
                    '• Các hư hỏng, sự cố do lỗi kỹ thuật có sẵn của xe.\n'
                    '• Việc xe không đạt đăng kiểm do nguyên nhân khách quan hoặc tình trạng xe.\n'
                    '• Sự kiện bất khả kháng (tai nạn không do lỗi, thiên tai, sự cố giao thông ngoài tầm kiểm soát).',
                    style: TextStyle(
                        fontSize: 12, height: 1.55, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ĐIỀU 6. HIỆU LỰC',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Văn bản này được lập thành 02 bản, mỗi bên giữ 01 bản, có giá trị pháp lý như nhau.\n'
                    'Hai bên đã đọc, hiểu rõ quyền và nghĩa vụ của mình và tự nguyện ký tên dưới đây.',
                    style: TextStyle(
                        fontSize: 12, height: 1.55, color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ĐẠI DIỆN BÊN A\n(Ký, ghi rõ họ tên)',
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.6),
                            ),
                            SizedBox(height: 56),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              'ĐẠI DIỆN BÊN B\n(Ký, ghi rõ họ tên, đóng dấu)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.6),
                            ),
                            SizedBox(height: 56),
                            Text(
                              'ĐẶNG HỒNG NAM',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessStepper() {
    final currentIndex = _currentStep.index;
    final steps = [
      ('Hợp đồng + Ký', Icons.description_outlined),
      ('Thanh toán', Icons.credit_card_rounded),
      ('Chụp ảnh xe & giấy tờ', Icons.camera_alt_outlined),
    ];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final lineDone = currentIndex > index ~/ 2;
          return Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.only(bottom: 32),
              color: lineDone
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFD1D5DB),
            ),
          );
        }

        final stepIndex = index ~/ 2;
        final isActive = currentIndex == stepIndex;
        final isDone = currentIndex > stepIndex;
        final bgColor = isDone
            ? const Color(0xFF16A34A)
            : isActive
                ? const Color(0xFF2563EB)
                : const Color(0xFFE5E7EB);

        return SizedBox(
          width: 92,
          child: Column(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : steps[stepIndex].$2,
                  color: isActive || isDone
                      ? Colors.white
                      : const Color(0xFF9CA3AF),
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                steps[stepIndex].$1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: isActive || isDone
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isActive || isDone
                      ? const Color(0xFF111827)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
    List<Color> colors = const [Color(0xFF2563EB), Color(0xFF1D4ED8)],
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? colors
                : [const Color(0xFFD1D5DB), const Color(0xFFD1D5DB)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled ? Colors.white : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: enabled ? Colors.white : const Color(0xFF9CA3AF),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentSuccessCard() {
    final paymentLabel = _paymentMethod == 0 ? 'QR' : 'tiền mặt';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xFF16A34A),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thanh toán thành công!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Đã nhận thanh toán $paymentLabel ${widget.totalCost}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection() {
    final docReqs = _documentRequirements;
    if (docReqs.isEmpty && !_isLoadingRequirements) {
      return const SizedBox.shrink(); // Không có requirement giấy tờ
    }

    return _buildSectionCard(
      icon: Icons.folder_copy_outlined,
      iconColor: const Color(0xFF8B5CF6),
      title: '6. Chụp ảnh giấy tờ ($_documentCount/${docReqs.length})',
      hint: 'Chụp rõ toàn bộ nội dung giấy tờ xe để hoàn tất hồ sơ',
      hintBg: const Color(0xFFF5F3FF),
      hintText: const Color(0xFF7C3AED),
      hintIcon: Icons.collections_bookmark_outlined,
      hintIconColor: const Color(0xFF8B5CF6),
      child: Column(
        children: List.generate(docReqs.length, (i) {
          final req = docReqs[i];
          final uploaded = _uploadedMap[req.id];
          final isUploading = _uploadingMap[req.id] == true;
          final localPath = _localFileMap[req.id];
          final hasImage = uploaded != null || localPath != null;

          return GestureDetector(
            onTap: isUploading ? null : () => _pickAndUploadImage(req),
            child: Container(
              margin: EdgeInsets.only(bottom: i == docReqs.length - 1 ? 0 : 12),
              height: 188,
              decoration: BoxDecoration(
                color: hasImage ? const Color(0xFFF0FDF4) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasImage ? const Color(0xFF86EFAC) : const Color(0xFFD1D5DB),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildRequirementContent(
                requirement: req,
                uploaded: uploaded,
                isUploading: isUploading,
                localPath: localPath,
                isDocument: true,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSection2() {
    final vehicleReqs = _vehicleRequirements;

    // Khi đang loading hoặc lỗi
    if (_isLoadingRequirements) {
      return _buildSectionCard(
        icon: Icons.camera_alt_outlined,
        iconColor: const Color(0xFF2563EB),
        title: '4. Chụp ảnh thực tế của xe',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFF2563EB)),
          ),
        ),
      );
    }

    if (_requirementsError != null) {
      return _buildSectionCard(
        icon: Icons.camera_alt_outlined,
        iconColor: const Color(0xFF2563EB),
        title: '4. Chụp ảnh thực tế của xe',
        child: Column(
          children: [
            Text(
              _requirementsError!,
              style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loadRequirementsAndMedia,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (vehicleReqs.isEmpty) {
      return _buildSectionCard(
        icon: Icons.camera_alt_outlined,
        iconColor: const Color(0xFF2563EB),
        title: '4. Chụp ảnh thực tế của xe',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Không có yêu cầu ảnh xe nào.',
              style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
        ),
      );
    }

    return _buildSectionCard(
      icon: Icons.camera_alt_outlined,
      iconColor: const Color(0xFF2563EB),
      title: '4. Chụp ảnh thực tế của xe ($_photoCount/${vehicleReqs.length})',
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
              child: _buildRequirementContent(
                requirement: req,
                uploaded: uploaded,
                isUploading: isUploading,
                localPath: localPath,
                isDocument: false,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Widget dùng chung để render nội dung của một ô ảnh (cả xe lẫn giấy tờ).
  Widget _buildRequirementContent({
    required ImageRequirement requirement,
    required UploadedMedia? uploaded,
    required bool isUploading,
    required String? localPath,
    required bool isDocument,
  }) {
    // Đang upload: hiển local file + loading overlay
    if (isUploading && localPath != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(localPath),
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.3),
            colorBlendMode: BlendMode.darken,
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Đang upload...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Đã upload thành công
    if (uploaded != null) {
      // Ưu tiên hiển file local nếu có (nhanh hơn), fallback sang URL server
      final imageWidget = localPath != null
          ? Image.file(File(localPath), fit: BoxFit.cover)
          : Image.network(
              uploaded.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    color: Color(0xFF9CA3AF), size: 32),
              ),
            );

      return Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              color: const Color(0xCC16A34A),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isDocument) ...[
                    Text(
                      requirement.positionEmoji,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                  ] else
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 16),
                  if (isDocument) const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      requirement.name,
                      style: TextStyle(
                        fontSize: isDocument ? 13 : 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!isDocument)
            const Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.check_circle_rounded,
                  color: Color(0xFF16A34A), size: 22),
            ),
        ],
      );
    }

    // Chưa upload - hiển placeholder
    if (isDocument) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.description_outlined,
                size: 38, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 10),
            Text(
              requirement.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Nhấn để chụp tài liệu',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            if (requirement.isRequired)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Bắt buộc *',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Vehicle photo placeholder
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined,
            color: Color(0xFF9CA3AF), size: 24),
        const SizedBox(height: 6),
        Text(
          requirement.positionEmoji,
          style: const TextStyle(fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(
          requirement.name,
          style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          textAlign: TextAlign.center,
        ),
        if (requirement.isRequired)
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(
              '*',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFDC2626),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSection3() {
    final checklistReqs = _checklistRequirements;

    if (_isLoadingRequirements) {
      return _buildSectionCard(
        icon: Icons.check_rounded,
        iconColor: const Color(0xFF7C3AED),
        title: '5. Checklist kiểm tra',
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
          ),
        ),
      );
    }

    if (checklistReqs.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      icon: Icons.check_rounded,
      iconColor: const Color(0xFF7C3AED),
      title: '5. Checklist ki\u1EC3m tra ($_checkCount/${checklistReqs.length})',
      hint: 'Mỗi hạng mục cần chụp 1 ảnh chứng minh',
      hintBg: const Color(0xFFF5F3FF),
      hintText: const Color(0xFF5B21B6),
      hintIcon: Icons.lightbulb_outline_rounded,
      hintIconColor: const Color(0xFF7C3AED),
      child: Column(
        children: checklistReqs.map((req) {
          final uploaded = _uploadedMap[req.id];
          final isUploading = _uploadingMap[req.id] == true;
          final localPath = _localFileMap[req.id];
          final checked = uploaded != null;

          return GestureDetector(
            onTap: isUploading ? null : () => _pickAndUploadImage(req),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color:
                    checked ? const Color(0xFFEFFEF2) : const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: checked
                      ? const Color(0xFFBBF7D0)
                      : const Color(0xFFE5E7EB),
                ),
              ),
              child: Row(
                children: [
                   // Check icon
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: checked ? const Color(0xFF16A34A) : Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: checked
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: checked
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name
                  Expanded(
                    child: Text(
                      req.name,
                      style: TextStyle(
                        fontSize: 13,
                        color: checked
                            ? const Color(0xFF15803D)
                            : const Color(0xFF374151),
                        fontWeight: checked ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Photo action / thumbnail
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: isUploading && localPath != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(File(localPath), fit: BoxFit.cover),
                              Container(color: Colors.black38),
                              const Center(
                                child: SizedBox(
                                  width: 16, height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                ),
                              ),
                            ],
                          )
                        : (uploaded != null)
                            ? (localPath != null
                                ? Image.file(File(localPath), fit: BoxFit.cover)
                                : Image.network(uploaded.thumbnailUrl, fit: BoxFit.cover))
                            : const Icon(Icons.camera_alt_outlined, color: Color(0xFF9CA3AF), size: 20),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection4() {
    return _buildSectionCard(
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF6B7280),
      title: '7. Ghi chú chung (tùy chọn)',
      child: TextField(
        controller: _noteCtrl,
        maxLines: 4,
        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
        decoration: InputDecoration(
          hintText: 'Nhập ghi chú thêm về tình trạng xe...',
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
            borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
      ),
    );
  }

  Widget _buildSignatureSection() {
    return _buildSectionCard(
      icon: Icons.edit_outlined,
      iconColor: const Color(0xFFEA580C),
      title: '3. Ch\u1EEF k\u00FD kh\u00E1ch h\u00E0ng',
      hint: 'Y\u00EAu c\u1EA7u kh\u00E1ch h\u00E0ng k\u00FD v\u00E0o bi\u00EAn b\u1EA3n \u1EE7y quy\u1EC1n',
      hintBg: const Color(0xFFFFF7ED),
      hintText: const Color(0xFFB45309),
      hintIcon: Icons.warning_amber_rounded,
      hintIconColor: const Color(0xFFF59E0B),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showSignaturePad = true),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: double.infinity,
              padding: EdgeInsets.all(_showSignaturePad ? 12 : 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _hasSigned
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD1D5DB),
                ),
              ),
              child: _showSignaturePad
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 180,
                            color: Colors.white,
                            child: Signature(
                              controller: _signatureCtrl,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _hasSigned
                                    ? 'Kh\u00E1ch h\u00E0ng \u0111\u00E3 k\u00FD, c\u00F3 th\u1EC3 x\u00F3a \u0111\u1EC3 k\u00FD l\u1EA1i'
                                    : 'M\u1EDDi kh\u00E1ch h\u00E0ng k\u00FD v\u00E0o khung b\u00EAn tr\u00EAn',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                _signatureCtrl.clear();
                                setState(() => _hasSigned = false);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                                side: const BorderSide(
                                  color: Color(0xFFFCA5A5),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                              ),
                              label: const Text('X\u00F3a'),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE5E7EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.draw_rounded,
                            color: Color(0xFFEA580C),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Ch\u01B0a c\u00F3 ch\u1EEF k\u00FD',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Nh\u1EA5n v\u00E0o \u00F4 ch\u1EEF k\u00FD \u0111\u1EC3 m\u1EDF v\u00F9ng k\u00FD',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _hasSigned
                ? () {
                    FocusScope.of(context).unfocus();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ch\u1EEF k\u00FD \u0111\u00E3 \u0111\u01B0\u1EE3c x\u00E1c nh\u1EADn'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                : () => setState(() => _showSignaturePad = true),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEA580C), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _hasSigned ? '\u0110\u00E3 x\u00E1c nh\u1EADn ch\u1EEF k\u00FD' : 'X\u00E1c nh\u1EADn ch\u1EEF k\u00FD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildSection6() {
    final methods = [
      ('VietQR', 'Quét mã thanh toán', '🔳'),
      ('Tiền mặt', 'Thu tiền trực tiếp', '💵'),
    ];

    return _buildSectionCard(
      icon: Icons.credit_card_outlined,
      iconColor: const Color(0xFF2563EB),
      title: 'Phương thức thanh toán',
      hint: 'Chọn phương thức thanh toán phù hợp',
      hintBg: const Color(0xFFEFF6FF),
      hintText: const Color(0xFF1D4ED8),
      hintIcon: Icons.lightbulb_outline_rounded,
      hintIconColor: const Color(0xFF3B82F6),
      child: Row(
        children: List.generate(2, (i) {
          final selected = _paymentMethod == i;
          final selectedColor =
              i == 0 ? const Color(0xFF2563EB) : const Color(0xFF16A34A);
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _paymentMethod = i),
              child: Container(
                margin: EdgeInsets.only(right: i == 0 ? 10 : 0),
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? (i == 0
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF0FDF4))
                      : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected ? selectedColor : const Color(0xFFE5E7EB),
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      i == 0
                          ? Icons.qr_code_2_rounded
                          : Icons.payments_outlined,
                      size: 30,
                      color: selected
                          ? selectedColor
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      methods[i].$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color:
                            selected ? selectedColor : const Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      methods[i].$2,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFF6B7280)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompletionStatus() {
    // Build dynamic items từ requirements
    final vehicleReqs = _vehicleRequirements;
    final docReqs = _documentRequirements;

    final items = <(String, String?, bool)>[
      // Ảnh xe
      ('1. Ảnh xe', '$_photoCount/${vehicleReqs.length}',
          _photoCount == vehicleReqs.length && vehicleReqs.isNotEmpty),
      // Checklist
      ('2. Checklist', '$_checkCount/8', _checkCount == 8),
      // Giấy tờ - hiển thị từng requirement
      ...docReqs.map((req) => (
            req.name,
            null as String?,
            _uploadedMap.containsKey(req.id),
          )),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
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
              children: const [
                Icon(Icons.task_alt_rounded,
                    color: Color(0xFF2563EB), size: 20),
                SizedBox(width: 8),
                Text(
                  'Tình trạng hoàn thành',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...items.map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text(item.$1,
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF374151))),
                    const Spacer(),
                    if (item.$2 != null)
                      Text(item.$2!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF6B7280))),
                    const SizedBox(width: 8),
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.$3
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD1D5DB),
                          width: 2,
                        ),
                        color: item.$3
                            ? const Color(0xFF16A34A)
                            : Colors.transparent,
                      ),
                      child: item.$3
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 12)
                          : null,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final canPay = _canGoToPaymentStep && !_paymentCompleted;
    final isQr = _paymentMethod == 0;
    return _buildPrimaryButton(
      label: isQr ? 'Gửi yêu cầu thanh toán QR' : 'Xác nhận thu tiền mặt',
      icon: isQr ? Icons.qr_code_rounded : Icons.payments_rounded,
      onTap: _submitPayment,
      enabled: canPay,
      colors: isQr
          ? const [Color(0xFF2563EB), Color(0xFF1D4ED8)]
          : const [Color(0xFF16A34A), Color(0xFF16A34A)],
    );
  }

  Widget _buildBottomNav() {
    final tabs = [
      (Icons.home_rounded, 'Trang chủ'),
      (Icons.receipt_long_outlined, 'Đơn hàng'),
      (Icons.person_outline_rounded, 'Cá nhân'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(3, (i) {
              final selected = i == 1;
              return Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 32 : 0,
                      height: 3,
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Icon(tabs[i].$1,
                        size: 24,
                        color: selected
                            ? const Color(0xFF16A34A)
                            : Colors.grey.shade400),
                    const SizedBox(height: 3),
                    Text(tabs[i].$2,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w400,
                          color: selected
                              ? const Color(0xFF16A34A)
                              : Colors.grey.shade400,
                        )),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(size.width - 32, size.height * 0.35), 48, paint);
    canvas.drawCircle(Offset(size.width - 90, size.height * 0.25), 28, paint);
    canvas.drawCircle(Offset(24, size.height * 0.8), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Tự động chèn dấu `/` khi người dùng gõ ngày theo định dạng dd/MM/yyyy.
class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final trimmed = digits.length > 8 ? digits.substring(0, 8) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < trimmed.length; i++) {
      buffer.write(trimmed[i]);
      if ((i == 1 || i == 3) && i != trimmed.length - 1) {
        buffer.write('/');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

