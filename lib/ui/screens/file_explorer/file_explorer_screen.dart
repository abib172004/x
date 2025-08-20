import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_bloc.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_event.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_state.dart';
import 'package:hybrid_storage_app/core/models/file_info.dart';

// Écran de l'explorateur de fichiers, maintenant connecté au FileExplorerBloc.
class FileExplorerScreen extends StatelessWidget {
  const FileExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FileExplorerBloc()..add(const LoadDirectory('/')),
      child: const FileExplorerView(),
    );
  }
}

class FileExplorerView extends StatefulWidget {
  const FileExplorerView({super.key});

  @override
  State<FileExplorerView> createState() => _FileExplorerViewState();
}

class _FileExplorerViewState extends State<FileExplorerView> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorateur de Fichiers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.view_module),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
        builder: (context, state) {
          if (state is FileExplorerLoading || state is FileExplorerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FileExplorerLoaded) {
            return _buildFileList(state.files);
          }
          if (state is FileExplorerError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      context.read<FileExplorerBloc>().add(const LoadDirectory('/'));
                    },
                    child: const Text('Réessayer'),
                  )
                ],
              ),
            );
          }
          return const Center(child: Text('État non géré.'));
        },
      ),
    );
  }

  Widget _buildFileList(List<FileInfo> files) {
    if (files.isEmpty) {
      return const Center(child: Text('Ce dossier est vide.'));
    }

    return ListView.builder(
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        final isFolder = file.type == FileType.directory;

        return ListTile(
          leading: Icon(
            isFolder ? Icons.folder : _getIconForFileType(file.name),
            color: isFolder ? Colors.amber : Theme.of(context).primaryColor,
            size: 40,
          ),
          title: Text(file.name),
          subtitle: Text(file.readableSize),
          onTap: () {
            if (isFolder) {
              context.read<FileExplorerBloc>().add(LoadDirectory(file.path));
            }
          },
          trailing: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        );
      },
    );
  }

  IconData _getIconForFileType(String fileName) {
    if (fileName.endsWith('.jpg') || fileName.endsWith('.png')) {
      return Icons.image;
    }
    if (fileName.endsWith('.pdf')) {
      return Icons.picture_as_pdf;
    }
    if (fileName.endsWith('.mp3') || fileName.endsWith('.wav')) {
      return Icons.audiotrack;
    }
    if (fileName.endsWith('.mp4') || fileName.endsWith('.mov')) {
      return Icons.videocam;
    }
    return Icons.insert_drive_file;
  }
}
