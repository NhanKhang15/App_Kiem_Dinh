import 'package:equatable/equatable.dart';

/// Một xe từ API GET /api/vehicles/
class VehicleModel extends Equatable {
  const VehicleModel({
    required this.id,
    required this.vehicleTypeName,
    required this.licensePlate,
    required this.brand,
    required this.model,
    required this.color,
    this.manufactureYear,
    this.chassisNumber,
    this.engineNumber,
    this.registrationDate,
    this.lastInspectionDate,
    this.nextInspectionDate,
    this.status,
    this.customer,
    this.vehicleType,
  });

  final int id;
  final String vehicleTypeName;
  final String licensePlate;
  final String brand;
  final String model;
  final String color;
  final int? manufactureYear;
  final String? chassisNumber;
  final String? engineNumber;
  final String? registrationDate;
  final String? lastInspectionDate;
  final String? nextInspectionDate;
  final String? status;
  final int? customer;
  final int? vehicleType;

  /// Hãng + model, ví dụ "Toyota Vios"
  String get brandModel => '$brand $model'.trim();

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: _toInt(json['id']),
      vehicleTypeName: json['vehicle_type_name']?.toString() ?? '',
      licensePlate: json['license_plate']?.toString() ?? '',
      brand: json['brand']?.toString() ?? '',
      model: json['model']?.toString() ?? '',
      color: json['color']?.toString() ?? '',
      manufactureYear: json['manufacture_year'] != null ? _toInt(json['manufacture_year']) : null,
      chassisNumber: json['chassis_number']?.toString(),
      engineNumber: json['engine_number']?.toString(),
      registrationDate: json['registration_date']?.toString(),
      lastInspectionDate: json['last_inspection_date']?.toString(),
      nextInspectionDate: json['next_inspection_date']?.toString(),
      status: json['status']?.toString(),
      customer: json['customer'] != null ? _toInt(json['customer']) : null,
      vehicleType: json['vehicle_type'] != null ? _toInt(json['vehicle_type']) : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        licensePlate,
        brand,
        model,
        vehicleTypeName,
        color,
        nextInspectionDate,
      ];
}
