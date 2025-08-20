import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/dashboard/dashboard_bloc.dart';
import 'package:hybrid_storage_app/bloc/dashboard/dashboard_event.dart';
import 'package:hybrid_storage_app/bloc/dashboard/dashboard_state.dart';

// Écran du tableau de bord, connecté au DashboardBloc.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DashboardBloc()..add(LoadDashboardData()),
      child: const DashboardView(),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DashboardBloc>().add(RefreshDashboardData());
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DashboardLoaded) {
            return _buildDashboardContent(context, state);
          }
          if (state is DashboardError) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('État non géré.'));
        },
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardLoaded state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          Text(
            'État du Stockage',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          _StorageStatCard(
            icon: Icons.phone_android,
            title: 'Stockage du Smartphone',
            stats: state.localStats,
          ),
          const SizedBox(height: 12),
          _StorageStatCard(
            icon: Icons.computer,
            title: 'Stockage de l\'Ordinateur',
            stats: state.remoteStats,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Widget réutilisable pour afficher les statistiques de stockage.
class _StorageStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final StorageStats stats;

  const _StorageStatCard({
    required this.icon,
    required this.title,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    '${stats.usedSpaceGB.toStringAsFixed(1)} Go / ${stats.totalSpaceGB.toStringAsFixed(0)} Go utilisés',
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: stats.usagePercentage,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
