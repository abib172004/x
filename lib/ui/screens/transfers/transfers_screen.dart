import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/transfer/transfer_bloc.dart';
import 'package:hybrid_storage_app/bloc/transfer/transfer_event.dart';
import 'package:hybrid_storage_app/bloc/transfer/transfer_state.dart';
import 'package:hybrid_storage_app/core/models/file_info.dart';

// Écran des transferts, maintenant connecté au TransferBloc.
class TransfersScreen extends StatelessWidget {
  const TransfersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TransferBloc(),
      child: const TransfersView(),
    );
  }
}

class TransfersView extends StatelessWidget {
  const TransfersView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transferts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En cours'),
              Tab(text: 'Terminés'),
              Tab(text: 'Échoués'),
            ],
          ),
        ),
        body: BlocBuilder<TransferBloc, TransferState>(
          builder: (context, state) {
            return TabBarView(
              children: [
                _buildTransferList(state.ongoingTransfers),
                _buildTransferList(state.completedTransfers),
                _buildTransferList(state.failedTransfers),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            // Simule le démarrage d'un nouveau téléchargement.
            final mockFile = FileInfo(
              name: 'nouveau_fichier_test.zip',
              path: '/remote/nouveau_fichier_test.zip',
              sizeInBytes: 12345678,
              modifiedAt: DateTime.now(),
              type: FileType.file,
              isLocal: false,
            );
            context.read<TransferBloc>().add(StartDownload(mockFile));
          },
        ),
      ),
    );
  }

  Widget _buildTransferList(List<Transfer> transfers) {
    if (transfers.isEmpty) {
      return const Center(child: Text('Aucun transfert dans cette catégorie.'));
    }
    return ListView.builder(
      itemCount: transfers.length,
      itemBuilder: (context, index) {
        final transfer = transfers[index];
        return _buildTransferListItem(transfer);
      },
    );
  }

  Widget _buildTransferListItem(Transfer transfer) {
    Icon leadingIcon;
    Widget trailing;

    if (transfer.status == TransferStatus.ongoing) {
      leadingIcon = const Icon(Icons.sync);
      trailing = SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(value: transfer.progress),
      );
    } else if (transfer.status == TransferStatus.completed) {
      leadingIcon = Icon(
        Icons.check_circle,
        color: transfer.type == TransferType.download ? Colors.green : Colors.blue,
      );
      trailing = const Icon(Icons.done);
    } else { // failed
      leadingIcon = const Icon(Icons.error, color: Colors.red);
      trailing = const Icon(Icons.replay);
    }

    return ListTile(
      leading: leadingIcon,
      title: Text(transfer.file.name),
      subtitle: transfer.status == TransferStatus.ongoing
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                LinearProgressIndicator(value: transfer.progress),
                const SizedBox(height: 4),
                Text('${(transfer.progress * 100).toInt()}%'),
              ],
            )
          : Text(transfer.file.readableSize),
      trailing: trailing,
    );
  }
}
