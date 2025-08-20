import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_event.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_state.dart';
import 'package:hybrid_storage_app/core/di/service_locator.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';

class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {
  // Récupère l'instance du service de communication via le service locator.
  final CommunicationService _communicationService = getIt<CommunicationService>();

  FileExplorerBloc() : super(FileExplorerInitial()) {
    // Enregistre le gestionnaire pour l'événement LoadDirectory.
    on<LoadDirectory>(_onLoadDirectory);
  }

  Future<void> _onLoadDirectory(
    LoadDirectory event,
    Emitter<FileExplorerState> emit,
  ) async {
    try {
      // Émet l'état de chargement pour que l'UI puisse afficher un spinner.
      emit(FileExplorerLoading());

      // Appelle le service pour récupérer la liste des fichiers.
      // C'est ici que notre MockCommunicationService sera appelé.
      final files = await _communicationService.listRemoteDirectory(event.path);

      // Une fois les données reçues, émet l'état de succès avec les données.
      emit(FileExplorerLoaded(files: files, currentPath: event.path));
    } catch (e) {
      // En cas d'erreur, émet l'état d'erreur avec un message.
      emit(FileExplorerError('Impossible de charger le répertoire: ${e.toString()}'));
    }
  }
}
