import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/transfer/transfer_event.dart';
import 'package:hybrid_storage_app/bloc/transfer/transfer_state.dart';
import 'package:hybrid_storage_app/core/di/service_locator.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final CommunicationService _communicationService = getIt<CommunicationService>();

  TransferBloc() : super(const TransferState()) {
    on<StartDownload>(_onStartDownload);
    // on<StartUpload>(_onStartUpload); // Implémentation similaire
    on<_UpdateTransferProgress>(_onUpdateProgress);
    on<_CompleteTransfer>(_onCompleteTransfer);
  }

  void _onStartDownload(StartDownload event, Emitter<TransferState> emit) {
    // Crée un nouvel objet de transfert.
    final newTransfer = Transfer(
      file: event.fileToDownload,
      status: TransferStatus.ongoing,
      type: TransferType.download,
    );

    // Ajoute le nouveau transfert à la liste existante.
    final updatedTransfers = List<Transfer>.from(state.transfers)..add(newTransfer);
    emit(state.copyWith(transfers: updatedTransfers));

    // Appelle le service et écoute le stream de progression.
    _communicationService
        .downloadFile(event.fileToDownload.path, '/fake/local/path')
        .listen(
      (progress) {
        // Pour chaque mise à jour de la progression, on ajoute un événement interne.
        add(_UpdateTransferProgress(newTransfer.id, progress));
      },
      onDone: () {
        // Quand le transfert est terminé, on ajoute un autre événement interne.
        add(_CompleteTransfer(newTransfer.id));
      },
      onError: (error) {
        // TODO: Gérer les erreurs de transfert.
      },
    );
  }

  void _onUpdateProgress(
    _UpdateTransferProgress event,
    Emitter<TransferState> emit,
  ) {
    // Met à jour la progression du transfert concerné.
    final updatedTransfers = state.transfers.map((transfer) {
      if (transfer.id == event.transferId) {
        return transfer.copyWith(progress: event.progress);
      }
      return transfer;
    }).toList();

    emit(state.copyWith(transfers: updatedTransfers));
  }

  void _onCompleteTransfer(
    _CompleteTransfer event,
    Emitter<TransferState> emit,
  ) {
    // Marque le transfert comme terminé.
    final updatedTransfers = state.transfers.map((transfer) {
      if (transfer.id == event.transferId) {
        return transfer.copyWith(status: TransferStatus.completed, progress: 1.0);
      }
      return transfer;
    }).toList();

    emit(state.copyWith(transfers: updatedTransfers));
  }
}
