import 'dart:async';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/transfer/transfer_event.dart';
import 'package:hybrid_storage_app/bloc/transfer/transfer_state.dart';
import 'package:hybrid_storage_app/core/di/service_locator.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';

class TransferBloc extends Bloc<TransferEvent, TransferState> {
  final CommunicationService _communicationService = getIt<CommunicationService>();
  // Liste pour garder une référence à toutes les souscriptions de stream actives.
  final List<StreamSubscription> _subscriptions = [];

  TransferBloc() : super(const TransferState()) {
    on<StartDownload>(_onStartDownload);
    on<StartUpload>(_onStartUpload);
    on<UpdateTransferProgress>(_onUpdateProgress);
    on<CompleteTransfer>(_onCompleteTransfer);
    on<FailTransfer>(_onFailTransfer);
  }

  void _onStartDownload(StartDownload event, Emitter<TransferState> emit) {
    final newTransfer = Transfer(
      file: event.fileToDownload,
      status: TransferStatus.ongoing,
      type: TransferType.download,
    );
    _initiateTransfer(newTransfer, emit);
  }

  void _onStartUpload(StartUpload event, Emitter<TransferState> emit) {
    final newTransfer = Transfer(
      file: event.fileToUpload,
      status: TransferStatus.ongoing,
      type: TransferType.upload,
    );
    _initiateTransfer(newTransfer, emit);
  }

  void _initiateTransfer(Transfer transfer, Emitter<TransferState> emit) {
    final updatedTransfers = List<Transfer>.from(state.transfers)..add(transfer);
    emit(state.copyWith(transfers: updatedTransfers));

    Stream<double> progressStream;
    if (transfer.type == TransferType.download) {
      progressStream = _communicationService.downloadFile(transfer.file.path, '/fake/local/path');
    } else {
      progressStream = _communicationService.uploadFile(null, transfer.file.path);
    }

    // On stocke la souscription pour pouvoir l'annuler plus tard.
    final subscription = progressStream.listen(
      (progress) {
        if (!isClosed) add(UpdateTransferProgress(transfer.id, progress));
      },
      onDone: () {
        if (!isClosed) add(CompleteTransfer(transfer.id));
      },
      onError: (error) {
        if (!isClosed) add(FailTransfer(transfer.id, error.toString()));
      },
    );
    _subscriptions.add(subscription);
  }

  void _onUpdateProgress(
    UpdateTransferProgress event,
    Emitter<TransferState> emit,
  ) {
    final updatedTransfers = state.transfers.map((transfer) {
      if (transfer.id == event.transferId) {
        return transfer.copyWith(progress: event.progress);
      }
      return transfer;
    }).toList();

    emit(state.copyWith(transfers: updatedTransfers));
  }

  void _onCompleteTransfer(
    CompleteTransfer event,
    Emitter<TransferState> emit,
  ) {
    final updatedTransfers = state.transfers.map((transfer) {
      if (transfer.id == event.transferId) {
        return transfer.copyWith(status: TransferStatus.completed, progress: 1.0);
      }
      return transfer;
    }).toList();

    emit(state.copyWith(transfers: updatedTransfers));
  }

  void _onFailTransfer(FailTransfer event, Emitter<TransferState> emit) {
    final updatedTransfers = state.transfers.map((transfer) {
      if (transfer.id == event.transferId) {
        return transfer.copyWith(status: TransferStatus.failed, errorMessage: event.errorMessage);
      }
      return transfer;
    }).toList();

    emit(state.copyWith(transfers: updatedTransfers));
  }

  // On surcharge la méthode `close` du BLoC.
  @override
  Future<void> close() {
    // On annule chaque souscription active pour éviter les fuites de mémoire et les erreurs.
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    // On appelle la méthode `close` de la classe parente pour terminer le nettoyage.
    return super.close();
  }
}
