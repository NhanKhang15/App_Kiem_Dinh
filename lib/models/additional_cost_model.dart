/// Model cho chi phí phát sinh từ API 6.4
/// POST /api/orders/{order_id}/vehicle-return-additional-costs/
class AdditionalCost {
  final int id;
  final String? orderCode;
  final String? createdByName;
  final String costType;
  final String costName;
  final String? description;
  final String amount;
  final String? photoUrl;
  final String? invoiceUrl;
  final bool isRequired;
  final bool isApproved;
  final String? notes;
  final String? approvedAt;
  final String? paymentMethod;
  final String paymentStatus;
  final String? qrCodeUrl;
  final String? qrContent;
  final String? paidAt;
  final String? paymentProofUrl;
  final String? transactionId;
  final String? paymentNote;
  final String createdAt;
  final String updatedAt;
  final int? returnLog;
  final int? order;
  final int? createdBy;

  AdditionalCost({
    required this.id,
    this.orderCode,
    this.createdByName,
    required this.costType,
    required this.costName,
    this.description,
    required this.amount,
    this.photoUrl,
    this.invoiceUrl,
    this.isRequired = false,
    this.isApproved = false,
    this.notes,
    this.approvedAt,
    this.paymentMethod,
    this.paymentStatus = 'pending',
    this.qrCodeUrl,
    this.qrContent,
    this.paidAt,
    this.paymentProofUrl,
    this.transactionId,
    this.paymentNote,
    required this.createdAt,
    required this.updatedAt,
    this.returnLog,
    this.order,
    this.createdBy,
  });

  /// Đã thanh toán chưa
  bool get isPaid => paymentStatus == 'paid';

  /// Đang chờ thanh toán
  bool get isPending => paymentStatus == 'pending';

  /// Số tiền hiển thị
  String get displayAmount {
    final parsed = double.tryParse(amount);
    if (parsed == null) return '${amount}đ';
    if (parsed == parsed.truncateToDouble()) {
      return '${parsed.toInt()}đ';
    }
    return '${parsed.toStringAsFixed(0)}đ';
  }

  /// Label cho loại chi phí
  String get costTypeLabel {
    switch (costType) {
      case 'repair':
        return 'Sửa chữa';
      case 'cleaning':
        return 'Vệ sinh';
      case 'fuel':
        return 'Nhiên liệu';
      case 'parking':
        return 'Đỗ xe';
      case 'other':
        return 'Khác';
      default:
        return costType;
    }
  }

  /// Creates a copy with optional field overrides (used after payment status refresh).
  AdditionalCost copyWith({
    String? paymentStatus,
    String? paymentMethod,
    String? paidAt,
    String? transactionId,
    String? paymentNote,
    String? updatedAt,
  }) {
    return AdditionalCost(
      id: id,
      orderCode: orderCode,
      createdByName: createdByName,
      costType: costType,
      costName: costName,
      description: description,
      amount: amount,
      photoUrl: photoUrl,
      invoiceUrl: invoiceUrl,
      isRequired: isRequired,
      isApproved: isApproved,
      notes: notes,
      approvedAt: approvedAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      qrCodeUrl: qrCodeUrl,
      qrContent: qrContent,
      paidAt: paidAt ?? this.paidAt,
      paymentProofUrl: paymentProofUrl,
      transactionId: transactionId ?? this.transactionId,
      paymentNote: paymentNote ?? this.paymentNote,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      returnLog: returnLog,
      order: order,
      createdBy: createdBy,
    );
  }

  factory AdditionalCost.fromJson(Map<String, dynamic> json) {
    return AdditionalCost(
      id: json['id'] as int,
      orderCode: json['order_code']?.toString(),
      createdByName: json['created_by_name']?.toString(),
      costType: json['cost_type']?.toString() ?? 'other',
      costName: json['cost_name']?.toString() ?? '',
      description: json['description']?.toString(),
      amount: json['amount']?.toString() ?? '0',
      photoUrl: json['photo_url']?.toString(),
      invoiceUrl: json['invoice_url']?.toString(),
      isRequired: json['is_required'] == true,
      isApproved: json['is_approved'] == true,
      notes: json['notes']?.toString(),
      approvedAt: json['approved_at']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      qrCodeUrl: json['qr_code_url']?.toString(),
      qrContent: json['qr_content']?.toString(),
      paidAt: json['paid_at']?.toString(),
      paymentProofUrl: json['payment_proof_url']?.toString(),
      transactionId: json['transaction_id']?.toString(),
      paymentNote: json['payment_note']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      returnLog: json['return_log'] as int?,
      order: json['order'] as int?,
      createdBy: json['created_by'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': orderCode,
      'created_by_name': createdByName,
      'cost_type': costType,
      'cost_name': costName,
      'description': description,
      'amount': amount,
      'photo_url': photoUrl,
      'invoice_url': invoiceUrl,
      'is_required': isRequired,
      'is_approved': isApproved,
      'notes': notes,
      'approved_at': approvedAt,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'qr_code_url': qrCodeUrl,
      'qr_content': qrContent,
      'paid_at': paidAt,
      'payment_proof_url': paymentProofUrl,
      'transaction_id': transactionId,
      'payment_note': paymentNote,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'return_log': returnLog,
      'order': order,
      'created_by': createdBy,
    };
  }
}
