import 'package:equatable/equatable.dart';

/// Một trạm đăng kiểm từ GET /api/stations/
class StationModel extends Equatable {
  const StationModel({
    required this.id,
    required this.stationCode,
    required this.stationName,
    this.address,
    this.phone,
    this.email,
    this.latitude,
    this.longitude,
    this.capacity,
    this.dailyCapacity,
    this.workingHours,
    this.openTime,
    this.closeTime,
    this.status = 'active',
    this.createdAt,
  });

  final int id;
  final String stationCode;
  final String stationName;
  final String? address;
  final String? phone;
  final String? email;
  final String? latitude;
  final String? longitude;
  final int? capacity;
  final int? dailyCapacity;
  final String? workingHours;
  final String? openTime;
  final String? closeTime;
  final String status;
  final String? createdAt;

  factory StationModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return StationModel(
      id: id is int ? id : int.tryParse(id?.toString() ?? '0') ?? 0,
      stationCode: json['station_code']?.toString() ?? '',
      stationName: json['station_name']?.toString() ?? '',
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      capacity: json['capacity'] is int ? json['capacity'] as int : int.tryParse(json['capacity']?.toString() ?? ''),
      dailyCapacity: json['daily_capacity'] is int ? json['daily_capacity'] as int : int.tryParse(json['daily_capacity']?.toString() ?? ''),
      workingHours: json['working_hours']?.toString(),
      openTime: json['open_time']?.toString(),
      closeTime: json['close_time']?.toString(),
      status: json['status']?.toString() ?? 'active',
      createdAt: json['created_at']?.toString(),
    );
  }

  /// Giờ mở/đóng dạng ngắn (vd. "07:00 - 17:00").
  String? get hoursDisplay {
    final open = openTime;
    final close = closeTime;
    if (open == null && close == null) return null;
    if (open != null && close != null) return '$open - $close';
    return open ?? close;
  }

  @override
  List<Object?> get props => [
        id, stationCode, stationName, address, phone, email,
        latitude, longitude, capacity, dailyCapacity, workingHours, openTime, closeTime, status, createdAt,
      ];
}
