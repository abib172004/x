import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hybrid_storage_app/core/models/file_info.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;

class RealCommunicationService implements CommunicationService {
  IOWebSocketChannel? _channel;
  StreamController<List<FileInfo>>? _fileListController;

  // TODO: Rendre l'hôte et le port dynamiques
  final String _host = "127.0.0.1";
  final int _port = 8000;

  @override
  Future<void> connect(String host, int port) async {
    // L'ID de l'appareil devrait être stocké de manière persistante
    final String idAppareil = "appareil-test-123";
    final url = Uri.parse('ws://$_host:$_port/ws/$idAppareil');

    _channel = IOWebSocketChannel.connect(url);
    _fileListController = StreamController<List<FileInfo>>.broadcast();

    _channel?.stream.listen((message) {
      final decodedMessage = jsonDecode(message);
      if (decodedMessage['action'] == 'liste_fichiers' && decodedMessage['statut'] == 'succes') {
        final List<dynamic> contenu = decodedMessage['donnees']['contenu'];
        final files = contenu.map((data) => FileInfo(
          name: data['nom'],
          path: data['chemin'],
          sizeInBytes: data['tailleOctets'],
          modifiedAt: DateTime.parse(data['modifieLe']),
          type: data['type'] == 'dossier' ? FileType.directory : FileType.file,
          isLocal: false,
        )).toList();
        _fileListController?.add(files);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _channel?.sink.close();
    _fileListController?.close();
  }

  @override
  Future<List<FileInfo>> listRemoteDirectory(String path) async {
    if (_channel == null || _fileListController == null) {
      await connect(_host, _port);
    }

    final command = {
      "action": "lister_fichiers",
      "charge_utile": {"chemin": path}
    };
    _channel?.sink.add(jsonEncode(command));

    // Attend la prochaine liste de fichiers reçue sur le stream
    return await _fileListController!.stream.first;
  }

  // Cette méthode ne fait pas partie du contrat initial mais est nécessaire pour l'appairage.
  Future<bool> completerAppairage(String host, Map<String, dynamic> donneesAppareil) async {
     final url = Uri.parse('http://$host:$_port/api/v1/appairage/completer');
     try {
        final reponse = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(donneesAppareil),
        );
        return reponse.statusCode == 200;
     } catch (e) {
       print("Erreur lors de la complétion de l'appairage: $e");
       return false;
     }
  }

  // --- Implémentations restantes du contrat (simulées pour l'instant) ---

  @override
  Stream<double> downloadFile(String remotePath, String localPath) {
    // TODO: Implémenter le transfert de fichier réel (probablement via gRPC ou un autre endpoint HTTP)
    return Stream.periodic(const Duration(milliseconds: 300), (tick) {
      return (tick + 1) * 0.1;
    }).take(10);
  }

  @override
  Stream<double> uploadFile(File? file, String remotePath) {
    // TODO: Implémenter le transfert de fichier réel
    return Stream.periodic(const Duration(milliseconds: 200), (tick) {
      return (tick + 1) * 0.05;
    }).take(20);
  }

  @override
  Future sendCommand(String command, Map<String, dynamic> params) {
    // TODO: Implémenter une commande générique si nécessaire
    throw UnimplementedError();
  }
}
