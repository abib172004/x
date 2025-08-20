import 'package:hybrid_storage_app/core/models/file_info.dart';
import 'dart:io';

// Contrat (interface abstraite) pour le service de communication.
// Ceci permet de découpler la logique métier de l'implémentation spécifique
// des protocoles réseau (WebSocket, gRPC).
// On pourra ainsi facilement mocker ce service pour les tests.
abstract class CommunicationService {

  // Établit la connexion avec le serveur desktop.
  Future<void> connect(String host, int port);

  // Ferme la connexion.
  Future<void> disconnect();

  // Obtient la liste des fichiers et dossiers pour un chemin donné sur l'ordinateur.
  Future<List<FileInfo>> listRemoteDirectory(String path);

  // Envoie une commande générique au serveur (par exemple, pour la recherche).
  // Le type de retour sera défini plus précisément.
  Future<dynamic> sendCommand(String command, Map<String, dynamic> params);

  // Lance le téléchargement d'un fichier depuis l'ordinateur vers le smartphone.
  // Retourne un Stream pour suivre la progression.
  Stream<double> downloadFile(String remotePath, String localPath);

  // Lance l'envoi d'un fichier depuis le smartphone vers l'ordinateur.
  // Prend un objet File de dart:io.
  // Retourne un Stream pour suivre la progression.
  Stream<double> uploadFile(File file, String remotePath);
}
