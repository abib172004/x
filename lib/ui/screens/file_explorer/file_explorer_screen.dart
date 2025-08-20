import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_bloc.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_event.dart';
import 'package:hybrid_storage_app/bloc/file_explorer/file_explorer_state.dart';
import 'package:hybrid_storage_app/bloc/transfer/transfer_bloc.dart';
import 'package:hybrid_storage_app/bloc/transfer/transfer_event.dart';
import 'package:hybrid_storage_app/core/models/file_info.dart';

class FileExplorerScreen extends StatelessWidget {
  const FileExplorerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => FileExplorerBloc()..add(const LoadDirectory('/')),
        ),
        BlocProvider(create: (context) => TransferBloc()),
      ],
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
  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  AppBar _buildAppBar(BuildContext context) {
    final title = _isSearchActive ? _buildSearchField() : const Text('Explorateur');
    final leading = _isSearchActive ? _buildBackButton() : null;

    return AppBar(
      title: title,
      leading: leading,
      actions: _isSearchActive ? _buildSearchActions() : _buildDefaultActions(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Rechercher des fichiers...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white70),
      ),
      style: const TextStyle(color: Colors.white),
      onSubmitted: (query) {
        context.read<FileExplorerBloc>().add(SearchFiles(query));
      },
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        setState(() {
          _isSearchActive = false;
          _searchController.clear();
        });
        context.read<FileExplorerBloc>().add(const LoadDirectory('/'));
      },
    );
  }

  List<Widget> _buildSearchActions() {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => _searchController.clear(),
      )
    ];
  }

  List<Widget> _buildDefaultActions() {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () => setState(() => _isSearchActive = true),
      ),
      IconButton(
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
          child: Icon(
            _isGridView ? Icons.view_list : Icons.view_module,
            key: ValueKey<bool>(_isGridView),
          ),
        ),
        onPressed: () => setState(() => _isGridView = !_isGridView),
      ),
      PopupMenuButton<SortCriterion>(
        icon: const Icon(Icons.sort),
        onSelected: (criterion) {
          context.read<FileExplorerBloc>().add(SortFiles(criterion));
        },
        itemBuilder: (context) => [
          const PopupMenuItem(value: SortCriterion.name, child: Text('Trier par nom')),
          const PopupMenuItem(value: SortCriterion.date, child: Text('Trier par date')),
          const PopupMenuItem(value: SortCriterion.size, child: Text('Trier par taille')),
        ],
      )
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: BlocBuilder<FileExplorerBloc, FileExplorerState>(
        builder: (context, state) {
          if (state is FileExplorerLoading || state is FileExplorerInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is FileExplorerLoaded) {
            return _buildAnimatedFileList(context, state.files);
          }
          if (state is FileExplorerError) {
            return Center(child: Text(state.message, textAlign: TextAlign.center));
          }
          return const Center(child: Text('État non géré.'));
        },
      ),
    );
  }

  Widget _buildAnimatedFileList(BuildContext context, List<FileInfo> files) {
    if (files.isEmpty) {
      return const Center(child: Text('Aucun fichier trouvé.'));
    }
    return AnimationLimiter(
      child: ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildFileListItem(context, file),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFileListItem(BuildContext context, FileInfo file) {
    final isFolder = file.type == FileType.directory;
    return ListTile(
      leading: Icon(
        isFolder ? Icons.folder : _getIconForFileType(file.name),
        color: isFolder ? Colors.amber.shade700 : Theme.of(context).primaryColor,
        size: 40,
      ),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(isFolder ? 'Dossier' : file.readableSize),
      onTap: () {
        if (isFolder) {
          context.read<FileExplorerBloc>().add(LoadDirectory(file.path));
        }
      },
      onLongPress: () => _showContextMenu(context, file),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showContextMenu(context, file),
      ),
    );
  }

  void _showContextMenu(BuildContext context, FileInfo file) {
    showModalBottomSheet(
      context: context,
      builder: (modalContext) {
        final transferBloc = BlocProvider.of<TransferBloc>(context);
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Télécharger sur le téléphone'),
              onTap: () {
                transferBloc.add(StartDownload(file));
                Navigator.pop(modalContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Téléchargement de ${file.name} démarré.')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Renommer'),
              onTap: () => Navigator.pop(modalContext),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Supprimer', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(modalContext),
            ),
          ],
        );
      },
    );
  }

  IconData _getIconForFileType(String fileName) {
    final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : '';
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'mp3':
      case 'wav':
      case 'm4a':
        return Icons.audiotrack;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }
}
