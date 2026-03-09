import 'package:equatable/equatable.dart';
import 'package:vehicle_registration_app/models/station_model.dart';

/// Response từ GET /api/stations/
class StationsListResponse extends Equatable {
  const StationsListResponse({
    required this.count,
    required this.results,
  });

  final int count;
  final List<StationModel> results;

  factory StationsListResponse.fromJson(Map<String, dynamic> json) {
    final list = json['results'] as List<dynamic>? ?? [];
    return StationsListResponse(
      count: json['count'] is int ? json['count'] as int : int.tryParse(json['count']?.toString() ?? '0') ?? 0,
      results: list
          .map((e) => StationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [count, results];
}
