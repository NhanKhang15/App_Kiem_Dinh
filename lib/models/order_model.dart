class OrderModel {
  final String id;
  final String order_code;
  final String customerName;
  final String customerPhone;
  final String plateNumber;
  final String vehicleType;
  final String vehicleBrand;
  final String vehicleColor;
  final String appointmentTime;
  final String appointmentDate;
  final String stationAddress;
  final String status;
  final String statusType; 
  final List<OrderServiceItem>? services;
  final String? totalCost;
  final String? note;
  final double? stationLat;
  final double? stationLng;

  OrderModel({
    required this.id,
    required this.order_code,
    required this.customerName,
    required this.customerPhone,
    required this.plateNumber,
    required this.vehicleType,
    required this.vehicleBrand,
    required this.vehicleColor,
    required this.appointmentTime,
    required this.appointmentDate,
    required this.stationAddress,
    required this.status,
    required this.statusType,
    this.services,
    this.totalCost,
    this.note,
    this.stationLat,
    this.stationLng,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // API trả về tiếng Việt trong 'status_name' (VD: "Hoàn thành")
    String displayStatus = json['status_name']?.toString() ?? 'unknown';

    // Ánh xạ lại từ tiếng Việt sang các mã tiếng Anh ("pending", "completed"...) 
    // để giao diện (màu sắc, phân loại tab) hiểu được và hiển thị đúng!
    String mappedStatusType = 'unknown';
    if (displayStatus == 'Chờ xác nhận') mappedStatusType = 'pending';
    else if (displayStatus == 'Đã xác nhận') mappedStatusType = 'confirmed';
    else if (displayStatus == 'Đang đến') mappedStatusType = 'en_route';
    else if (displayStatus == 'Đang nhận xe') mappedStatusType = 'receiving';
    else if (displayStatus == 'Đang thực hiện') mappedStatusType = 'inspecting';
    else if (displayStatus == 'Đang trả xe') mappedStatusType = 'returning';
    else if (displayStatus == 'Đang chờ thanh toán') mappedStatusType = 'waiting_payment';
    else if (displayStatus == 'Hoàn thành') mappedStatusType = 'completed';
    else if (displayStatus == 'Đã hủy') mappedStatusType = 'cancelled';
    else if (displayStatus == 'Đang xử lý') mappedStatusType = 'in_progress';
    else mappedStatusType = displayStatus; // Dự phòng báo lỡ trường hợp vẫn trả về tiếng Anh

    final stationData = json['station'] is Map<String, dynamic>
        ? json['station'] as Map<String, dynamic>
        : json['station'] is Map
            ? Map<String, dynamic>.from(json['station'] as Map)
            : json['inspection_station'] is Map<String, dynamic>
                ? json['inspection_station'] as Map<String, dynamic>
                : json['inspection_station'] is Map
                    ? Map<String, dynamic>.from(json['inspection_station'] as Map)
                    : null;

    // DEBUG: In ra toàn bộ keys/values từ API để xác định tên field tọa độ
    assert(() {
      print('[OrderModel] RAW JSON keys: ${json.keys.toList()}');
      print('[OrderModel] station_lat=${json["station_lat"]}, station_lng=${json["station_lng"]}');
      print('[OrderModel] latitude=${json["latitude"]}, longitude=${json["longitude"]}');
      print('[OrderModel] lat=${json["lat"]}, lng=${json["lng"]}');
      if (stationData != null) {
        print('[OrderModel] stationData keys: ${stationData.keys.toList()}');
        print('[OrderModel] stationData lat=${stationData["lat"] ?? stationData["latitude"] ?? stationData["station_lat"]}');
        print('[OrderModel] stationData lng=${stationData["lng"] ?? stationData["longitude"] ?? stationData["station_lng"]}');
      } else {
        print('[OrderModel] stationData = null (key "station" and "inspection_station" not found)');
      }
      return true;
    }());

    final resolvedStationAddress =
        json['station_address']?.toString() ??
        stationData?['address']?.toString() ??
        '';
    final resolvedStationLat = _parseDouble(
      json['station_lat'] ??
          json['latitude'] ??
          json['lat'] ??
          stationData?['station_lat'] ??
          stationData?['latitude'] ??
          stationData?['lat'],
    );
    final resolvedStationLng = _parseDouble(
      json['station_lng'] ??
          json['longitude'] ??
          json['lng'] ??
          json['lon'] ??
          json['long'] ??
          stationData?['station_lng'] ??
          stationData?['longitude'] ??
          stationData?['lng'] ??
          stationData?['lon'] ??
          stationData?['long'],
    );

    return OrderModel(
      id: json['id']?.toString() ?? '',
      order_code: json['order_code']?.toString() ?? '',
      customerName: json['customer_name']?.toString() ?? '',
      customerPhone: json['customer_phone']?.toString() ?? '',
      plateNumber: json['vehicle_plate']?.toString() ?? '', 
      vehicleType: json['vehicle_type']?.toString() ?? '',
      vehicleBrand: json['vehicle_manufacturer']?.toString() ?? '', 
      vehicleColor: json['vehicle_color']?.toString() ?? '',
      appointmentTime: json['appointment_time']?.toString() ?? '',
      appointmentDate: json['appointment_date']?.toString() ?? '',
      stationAddress: resolvedStationAddress,
      status: displayStatus,        // Hiển thị chữ tiếng Việt từ API: "Hoàn thành"
      statusType: mappedStatusType, // Lấy biến đã phiên dịch ngược để app giữ đúng màu sắc ("completed")
      services: (json['services'] as List?)
          ?.map((e) => OrderServiceItem.fromJson(e))
          .toList(),
      totalCost: json['total_amount']?.toString() ?? '0',
      note: json['customer_notes']?.toString(), 
      stationLat: resolvedStationLat,
      stationLng: resolvedStationLng,
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_code': order_code,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'vehicle_plate': plateNumber,
      'vehicle_type': vehicleType,
      'vehicle_manufacturer': vehicleBrand,
      'vehicle_color': vehicleColor,
      'appointment_time': appointmentTime,
      'appointment_date': appointmentDate,
      'station_address': stationAddress,
      'status_name': status,
      'status_type': statusType,
      'total_amount': totalCost,
      'customer_notes': note,
      'station_lat': stationLat,
      'station_lng': stationLng,
    };
  }

  OrderModel copyWith({
    String? id,
    String? order_code,
    String? customerName,
    String? customerPhone,
    String? plateNumber,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleColor,
    String? appointmentTime,
    String? appointmentDate,
    String? stationAddress,
    String? status,
    String? statusType,
    List<OrderServiceItem>? services,
    String? totalCost,
    String? note,
    double? stationLat,
    double? stationLng,
  }) {
    return OrderModel(
      id: id ?? this.id,
      order_code: order_code ?? this.order_code,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      appointmentTime: appointmentTime ?? this.appointmentTime,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      stationAddress: stationAddress ?? this.stationAddress,
      status: status ?? this.status,
      statusType: statusType ?? this.statusType,
      services: services ?? this.services,
      totalCost: totalCost ?? this.totalCost,
      note: note ?? this.note,
      stationLat: stationLat ?? this.stationLat,
      stationLng: stationLng ?? this.stationLng,
    );
  }
}

class OrderServiceItem {
  final String name;
  final String price;

  OrderServiceItem({required this.name, required this.price});

  factory OrderServiceItem.fromJson(Map<String, dynamic> json) {
    return OrderServiceItem(
      name: json['name']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }
}
