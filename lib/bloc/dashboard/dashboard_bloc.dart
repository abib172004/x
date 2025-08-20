import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/dashboard/dashboard_event.dart';
import 'package:hybrid_storage_app/bloc/dashboard/dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  // TODO: Injecter un service qui peut fournir ces statistiques.
  // final StatsService _statsService = getIt<StatsService>();

  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboardData>(_onLoadData);
    on<RefreshDashboardData>(_onLoadData); // Le rafraîchissement recharge les données
  }

  Future<void> _onLoadData(
    DashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    try {
      // Simule un appel réseau pour obtenir les statistiques.
      await Future.delayed(const Duration(milliseconds: 800));

      // Données de simulation
      const localStats = StorageStats(totalSpaceGB: 128, usedSpaceGB: 80);
      const remoteStats = StorageStats(totalSpaceGB: 1000, usedSpaceGB: 450);
      const recentTransfers = 5;

      emit(const DashboardLoaded(
        localStats: localStats,
        remoteStats: remoteStats,
        recentTransfersCount: recentTransfers,
      ));
    } catch (e) {
      emit(DashboardError('Erreur lors du chargement des données: ${e.toString()}'));
    }
  }
}
