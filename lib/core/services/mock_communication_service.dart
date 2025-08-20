import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:hybrid_storage_app/core/models/file_info.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';

// Implémentation de simulation (mock) du service de communication.
// Elle ne se connecte à aucun vrai serveur mais retourne des données pré-définies
// après une latence simulée, pour permettre le développement de l'UI et de la logique métier.
class MockCommunicationService implements CommunicationService {
  final Random _random = Random();

  @override
  Future<void> connect(String host, int port) async {
    print('Mock connect to $host:$port');
    await Future.delayed(const Duration(milliseconds: 500));
    // Ne fait rien, simule juste une connexion réussie.
  }

  @override
  Future<void> disconnect() async {
    print('Mock disconnect');
    await Future.delayed(const Duration(milliseconds: 200));
    // Ne fait rien.
  }

  @override
  Future<List<FileInfo>> listRemoteDirectory(String path) async {
    print('Mock listRemoteDirectory for path: $path');
    await Future.delayed(const Duration(seconds: 1)); // Simule la latence réseau

    // Retourne une liste de fichiers factice.
    return [
      FileInfo(
        name: 'Photos de Vacances',
        path: '$path/photos',
        sizeInBytes: 0,
        modifiedAt: DateTime.now().subtract(const Duration(days: 10)),
        type: FileType.directory,
        isLocal: false,
      ),
      FileInfo(
        name: 'Rapport Final.docx',
        path: '$path/Rapport Final.docx',
        sizeInBytes: 2348 * 1024, // 2.3 MB
        modifiedAt: DateTime.now().subtract(const Duration(hours: 5)),
        type: FileType.file,
        isLocal: false,
      ),
      FileInfo(
        name: 'video_drone.mp4',
        path: '$path/video_drone.mp4',
        sizeInBytes: 1024 * 1024 * 150, // 150 MB
        modifiedAt: DateTime.now().subtract(const Duration(days: 2)),
        type: FileType.file,
        isLocal: false,
      ),
      FileInfo(
        name: 'presentation.pptx',
        path: '$path/presentation.pptx',
        sizeInBytes: 5829 * 1024, // 5.8 MB
        modifiedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        type: FileType.file,
        isLocal: false,
      ),
    ];
  }

  @override
  Stream<double> downloadFile(String remotePath, String localPath) {
    // Simule une progression de téléchargement.
    // Une chance sur quatre de simuler une erreur.
    if (_random.nextInt(4) == 0) {
      return Stream.periodic(const Duration(milliseconds: 100), (tick) {
        if (tick > 5) {
          throw Exception('Erreur réseau simulée');
        }
        return (tick + 1) * 0.1;
      }).take(10);
    }

    return Stream.periodic(const Duration(milliseconds: 300), (tick) {
      return (tick + 1) * 0.1;
    }).take(10);
  }

  @override
  Stream<double> uploadFile(File? file, String remotePath) {
    // Simule une progression d'envoi.
    return Stream.periodic(const Duration(milliseconds: 200), (tick) {
      return (tick + 1) * 0.05;
    }).take(20);
  }

  @override
  Future<dynamic> sendCommand(String command, Map<String, dynamic> params) async {
    print('Mock sendCommand: $command with params: $params');
    await Future.delayed(const Duration(milliseconds: 400));
    if (command == 'search') {
      return {'results': ['result1.pdf', 'result2.jpg']};
    }
    return {'status': 'ok'};
  }
}
