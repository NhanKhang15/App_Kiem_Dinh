import 'package:equatable/equatable.dart';
import 'package:vehicle_registration_app/models/vehicle_model.dart';

/// Response từ GET /api/vehicles/
class VehiclesListResponse extends Equatable {
  const VehiclesListResponse({
    required this.count,
    this.next,
    this.previous,
    required this.results,
  });

  final int count;
  final String? next;
  final String? previous;
  final List<VehicleModel> results;

  factory VehiclesListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return VehiclesListResponse(
      count: json['count'] as int? ?? 0,
      next: json['next']?.toString(),
      previous: json['previous']?.toString(),
      results: list
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [count, next, previous, results];
}
