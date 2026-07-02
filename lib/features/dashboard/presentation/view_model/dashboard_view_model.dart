import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/get_overview_usecase.dart';
import '../state/dashboard_state.dart';

final dashboardViewModelProvider =
    NotifierProvider<DashboardViewModel, DashboardState>(DashboardViewModel.new);

class DashboardViewModel extends Notifier<DashboardState> {
  late GetOverviewUsecase _getOverview;

  @override
  DashboardState build() {
    _getOverview = ref.read(getOverviewUsecaseProvider);
    return const DashboardState();
  }

  Future<void> load() async {
    state = state.copyWith(status: DashboardStatus.loading);
    final result = await _getOverview();
    result.fold(
      (failure) => state = state.copyWith(
        status: DashboardStatus.error,
        error: failure.message,
      ),
      (overview) => state = state.copyWith(
        status: DashboardStatus.loaded,
        overview: overview,
        error: null,
      ),
    );
  }
}
