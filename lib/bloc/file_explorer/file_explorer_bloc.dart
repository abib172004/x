import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_event.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_event.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_state.dart';
import 'package:hybrid_storage_app/core/di/service_locator.dart';
import 'package:hybrid_storage_app/core/models/file_info.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';

class FileExplorerBloc extends Bloc<FileExplorerEvent, FileExplorerState> {
  final CommunicationService _communicationService = getIt<CommunicationService>();

  FileExplorerBloc() : super(FileExplorerInitial()) {
    on<LoadDirectory>(_onLoadDirectory);
    on<SortFiles>(_onSortFiles);
    on<SearchFiles>(_onSearchFiles);
  }

  Future<void> _onLoadDirectory(
    LoadDirectory event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(FileExplorerLoading());
    try {
      final files = await _communicationService.listRemoteDirectory(event.path);
      emit(FileExplorerLoaded(files: files, currentPath: event.path));
    } catch (e) {
      emit(FileExplorerError('Impossible de charger le répertoire: ${e.toString()}'));
    }
  }

  void _onSortFiles(SortFiles event, Emitter<FileExplorerState> emit) {
    if (state is FileExplorerLoaded) {
      final currentState = state as FileExplorerLoaded;
      final List<FileInfo> files = List.from(currentState.files);

      // Tri des fichiers en fonction du critère.
      files.sort((a, b) {
        switch (event.criterion) {
          case SortCriterion.name:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case SortCriterion.date:
            return b.modifiedAt.compareTo(a.modifiedAt); // plus récent en premier
          case SortCriterion.size:
            return b.sizeInBytes.compareTo(a.sizeInBytes); // plus gros en premier
        }
      });

      emit(FileExplorerLoaded(files: files, currentPath: currentState.currentPath));
    }
  }

  Future<void> _onSearchFiles(
    SearchFiles event,
    Emitter<FileExplorerState> emit,
  ) async {
    emit(FileExplorerLoading());
    try {
      // Simule une recherche. Dans une vraie app, on appellerait un endpoint de recherche.
      await Future.delayed(const Duration(milliseconds: 500));
      final allFiles = await _communicationService.listRemoteDirectory('/');
      final results = allFiles
          .where((file) => file.name.toLowerCase().contains(event.query.toLowerCase()))
          .toList();
      emit(FileExplorerLoaded(files: results, currentPath: 'Résultats de recherche'));
    } catch (e) {
      emit(FileExplorerError('Erreur de recherche: ${e.toString()}'));
    }
  }
}
