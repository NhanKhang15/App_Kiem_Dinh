/// Model cho ảnh đã upload từ API POST /api/v1/media/upload/
/// và API GET /api/v1/media/
class UploadedMedia {
  final int id;
  final String url;
  final String thumbnailUrl;
  final String category;     
  final String position;    
  final String stage;        
  final int requirementId;
  final int? orderId;
  final String? fileType;   
  final int? fileSize;       
  final String? createdAt;

  UploadedMedia({
    required this.id,
    required this.url,
    required this.thumbnailUrl,
    required this.category,
    required this.position,
    required this.stage,
    required this.requirementId,
    this.orderId,
    this.fileType,
    this.fileSize,
    this.createdAt,
  });

  factory UploadedMedia.fromJson(Map<String, dynamic> json) {
    return UploadedMedia(
      id: json['id'] as int,
      url: json['url']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? json['url']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      position: json['position']?.toString() ?? '',
      stage: json['stage']?.toString() ?? '',
      requirementId: json['requirement_id'] as int? ?? 0,
      orderId: json['order_id'] as int?,
      fileType: json['file_type']?.toString(),
      fileSize: json['file_size'] as int?,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'position': position,
      'stage': stage,
      'requirement_id': requirementId,
      'order_id': orderId,
      'file_type': fileType,
      'file_size': fileSize,
      'created_at': createdAt,
    };
  }
}
