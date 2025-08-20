import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:hybrid_storage_app/core/models/file_info.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';
import 'package:hybrid_storage_app/core/services/grpc/transfer.pbgrpc.dart';
import 'package:web_socket_channel/io.dart';
import 'package:http/http.dart' as http;

class RealCommunicationService implements CommunicationService {
  IOWebSocketChannel? _channel;
  StreamController<List<FileInfo>>? _fileListController;
  FileTransferClient? _grpcClient;
  ClientChannel? _grpcChannel;

  final String _host = "127.0.0.1";
  final int _apiPort = 8000;
  final int _grpcPort = 50051;

  // Méthode pour initialiser les connexions
  Future<void> _init() async {
    if (_channel == null) {
      final String idAppareil = "appareil-test-123";
      final url = Uri.parse('ws://$_host:$_apiPort/ws/$idAppareil');
      _channel = IOWebSocketChannel.connect(url);
      _fileListController = StreamController<List<FileInfo>>.broadcast();
      _listenToWebSocket();
    }
    if (_grpcClient == null) {
      _grpcChannel = ClientChannel(
        _host,
        port: _grpcPort,
        options: const ChannelOptions(credentials: ChannelCredentials.insecure()),
      );
      _grpcClient = FileTransferClient(_grpcChannel!);
    }
  }

  void _listenToWebSocket() {
    _channel?.stream.listen((message) {
      final decodedMessage = jsonDecode(message);
      if (decodedMessage['action'] == 'liste_fichiers' && decodedMessage['statut'] == 'succes') {
        final List<dynamic> contenu = decodedMessage['donnees']['contenu'];
        // Utilise maintenant le factory constructor
        final files = contenu.map((data) => FileInfo.fromMap(data)).toList();
        _fileListController?.add(files);
      }
    });
  }

  @override
  Future<void> connect(String host, int port) async {
    await _init();
  }

  @override
  Future<void> disconnect() async {
    _channel?.sink.close();
    _fileListController?.close();
    await _grpcChannel?.shutdown();
  }

  @override
  Future<List<FileInfo>> listRemoteDirectory(String path) async {
    await _init();
    final command = {"action": "lister_fichiers", "charge_utile": {"chemin": path}};
    _channel?.sink.add(jsonEncode(command));
    return await _fileListController!.stream.first;
  }

  @override
  Stream<double> downloadFile(String remotePath, String localPath) {
    _init();
    final request = DownloadRequest()..remoteFilePath = remotePath;
    final responseStream = _grpcClient!.downloadFile(request);
    return responseStream.map((chunk) => chunk.content.length.toDouble());
  }

  @override
  Stream<double> uploadFile(File? file, String remotePath) {
    if (file == null) return Stream.value(0);
    _init();

    Stream<Chunk> _generateChunks(File file) async* {
      final stream = file.openRead();
      await for (var data in stream) {
        yield Chunk()..content = data;
      }
    }

    final responseFuture = _grpcClient!.uploadFile(
      _generateChunks(file),
      options: CallOptions(metadata: {'nom-fichier': file.path.split('/').last}),
    );
    return responseFuture.asStream().map((status) => status.success ? 1.0 : 0.0);
  }

  Future<bool> completerAppairage(String host, Map<String, dynamic> donneesAppareil) async {
    final url = Uri.parse('http://$host:$_apiPort/api/v1/appairage/completer');
    try {
      final reponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(donneesAppareil),
      );
      return reponse.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future sendCommand(String command, Map<String, dynamic> params) {
    throw UnimplementedError();
  }
}
