import 'package:equatable/equatable.dart';

/// Headline dashboard stats shown in the stat-card row.
class DashboardOverviewEntity extends Equatable {
  final int totalPieces;
  final int wearsPerWeek;
  final double avgCostPerWear;

  const DashboardOverviewEntity({
    required this.totalPieces,
    required this.wearsPerWeek,
    required this.avgCostPerWear,
  });

  static const empty = DashboardOverviewEntity(
    totalPieces: 0,
    wearsPerWeek: 0,
    avgCostPerWear: 0,
  );

  @override
  List<Object?> get props => [totalPieces, wearsPerWeek, avgCostPerWear];
}
