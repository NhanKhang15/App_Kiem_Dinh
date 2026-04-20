/// Model cho cấu hình ảnh bắt buộc từ API GET /api/v1/image-requirements/
class ImageRequirement {
  final int id;
  final String name;
  final String category;   
  final String position;   
  final String stage;     
  final bool isRequired;
  final int sortOrder;
  final int? vehicleType;
  final String? vehicleTypeCode;

  ImageRequirement({
    required this.id,
    required this.name,
    required this.category,
    required this.position,
    required this.stage,
    required this.isRequired,
    required this.sortOrder,
    this.vehicleType,
    this.vehicleTypeCode,
  });

  factory ImageRequirement.fromJson(Map<String, dynamic> json) {
    return ImageRequirement(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      stage: json['stage']?.toString() ?? '',
      isRequired: json['is_required'] == true,
      sortOrder: json['sort_order'] as int? ?? 0,
      vehicleType: json['vehicle_type'] as int?,
      vehicleTypeCode: json['vehicle_type_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'position': position,
      'stage': stage,
      'is_required': isRequired,
      'sort_order': sortOrder,
      'vehicle_type': vehicleType,
      'vehicle_type_code': vehicleTypeCode,
    };
  }

  /// Trả về emoji icon dựa trên position, dùng cho UI.
  String get positionEmoji {
    switch (position) {
      case 'FRONT':
        return '🚗';
      case 'BACK':
        return '🚙';
      case 'LEFT':
        return '🚘';
      case 'RIGHT':
        return '🚖';
      case 'INTERIOR':
        return '💺';
      case 'DASHBOARD':
        return '🎛️';
      default:
        return '📷';
    }
  }

  /// Trả về icon dựa trên category cho giấy tờ.
  String get categoryIcon {
    switch (category) {
      case 'DOCUMENT':
        return '📄';
      case 'CHECKLIST':
        return '✅';
      case 'RECEIPT':
        return '🧾';
      default:
        return '📷';
    }
  }
}
