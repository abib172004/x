import 'package:equatable/equatable.dart';
import 'package:hybrid_storage_app/core/models/file_info.dart';
import 'package:uuid/uuid.dart';

// Énumération pour le statut d'un transfert.
enum TransferStatus { ongoing, completed, failed }
// Énumération pour le type de transfert.
enum TransferType { upload, download }

// Classe de modèle pour représenter un transfert individuel dans la liste.
class Transfer extends Equatable {
  final String id;
  final FileInfo file;
  final TransferStatus status;
  final TransferType type;
  final double progress; // De 0.0 à 1.0
  final String? errorMessage;

  Transfer({
    String? id,
    required this.file,
    required this.status,
    required this.type,
    this.progress = 0.0,
    this.errorMessage,
  }) : id = id ?? const Uuid().v4();

  Transfer copyWith({
    TransferStatus? status,
    double? progress,
    String? errorMessage,
  }) {
    return Transfer(
      id: id,
      file: file,
      status: status ?? this.status,
      type: type,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [id, file, status, progress, errorMessage];
}

// L'état principal du BLoC des transferts.
// Il contient une liste de tous les transferts (en cours, terminés, etc.).
class TransferState extends Equatable {
  final List<Transfer> transfers;

  const TransferState({this.transfers = const []});

  // Sélecteurs pour facilement filtrer les listes pour l'UI.
  List<Transfer> get ongoingTransfers =>
      transfers.where((t) => t.status == TransferStatus.ongoing).toList();

  List<Transfer> get completedTransfers =>
      transfers.where((t) => t.status == TransferStatus.completed).toList();

  List<Transfer> get failedTransfers =>
      transfers.where((t) => t.status == TransferStatus.failed).toList();

  @override
  List<Object> get props => [transfers];

  TransferState copyWith({
    List<Transfer>? transfers,
  }) {
    return TransferState(
      transfers: transfers ?? this.transfers,
    );
  }
}
