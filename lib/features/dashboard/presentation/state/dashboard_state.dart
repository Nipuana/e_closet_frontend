import 'package:equatable/equatable.dart';

import '../../domain/entities/dashboard_overview_entity.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final DashboardOverviewEntity overview;
  final String? error;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.overview = DashboardOverviewEntity.empty,
    this.error,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    DashboardOverviewEntity? overview,
    String? error,
  }) {
    return DashboardState(
      status: status ?? this.status,
      overview: overview ?? this.overview,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, overview, error];
}
