import '../../domain/entities/dashboard_overview_entity.dart';

class DashboardOverviewModel {
  final int totalPieces;
  final int wearsPerWeek;
  final double avgCostPerWear;

  DashboardOverviewModel({
    required this.totalPieces,
    required this.wearsPerWeek,
    required this.avgCostPerWear,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    return DashboardOverviewModel(
      totalPieces: (json['total_pieces'] as num?)?.toInt() ?? 0,
      wearsPerWeek: (json['wears_per_week'] as num?)?.toInt() ?? 0,
      avgCostPerWear: (json['avg_cost_per_wear'] as num?)?.toDouble() ?? 0,
    );
  }

  DashboardOverviewEntity toEntity() => DashboardOverviewEntity(
        totalPieces: totalPieces,
        wearsPerWeek: wearsPerWeek,
        avgCostPerWear: avgCostPerWear,
      );
}
