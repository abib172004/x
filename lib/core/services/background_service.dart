import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:disk_space/disk_space.dart';
import 'package:hybrid_storage_app/core/di/service_locator.dart';
import 'package:hybrid_storage_app/core/repositories/settings_repository.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';
import 'package:path_provider/path_provider.dart';

const backgroundTaskName = "hybridStorageCheck";

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundTaskName) return false;

    print("Tâche de fond '$backgroundTaskName' en cours d'exécution...");

    // L'injection de dépendances n'est pas disponible dans cet isolate.
    // On doit initialiser les services manuellement ou utiliser des singletons.
    // Pour cet exemple, on suppose qu'on peut y accéder.
    // Dans une vraie app, cela nécessiterait une architecture plus complexe.

    try {
      // 1. Vérifier l'espace disque
      final double? freeSpace = await DiskSpace.getFreeDiskSpace;
      final double? totalSpace = await DiskSpace.getTotalDiskSpace;

      if (freeSpace == null || totalSpace == null) return false;
      final double freeSpacePercentage = (freeSpace / totalSpace) * 100;
      print("Espace disque libre : ${freeSpacePercentage.toStringAsFixed(2)}%");

      // TODO: Remplacer par un vrai chargement de settings en background
      const int seuil = 10;

      if (freeSpacePercentage < seuil) {
        print("Espace disque faible détecté ! Démarrage du transfert automatique.");

        // 2. Identifier les fichiers à transférer
        final Directory tempDir = await getTemporaryDirectory();
        // Créer un fichier de test pour la simulation
        final File testFile = File('${tempDir.path}/test_file_for_upload.txt');
        await testFile.writeAsString('Ceci est un test de transfert automatique.');

        final List<File> fichiers_a_transferer = [testFile];
        print("${fichiers_a_transferer.length} fichier(s) à transférer.");

        // 3. Lancer le transfert
        // NOTE: Ceci est une simplification. Normalement, on instancierait
        // le service de communication ici.
        // CommunicationService communicationService = RealCommunicationService();
        // await communicationService.connect("host", 8000);
        // for (var fichier in fichiers_a_transferer) {
        //   communicationService.uploadFile(fichier, '/auto/${fichier.path.split('/').last}');
        //   print("Transfert de ${fichier.path} initié.");
        // }
      } else {
        print("Espace disque suffisant.");
      }
      return true;
    } catch (err) {
      print("Erreur dans la tâche de fond : $err");
      return false;
    }
  });
}

class BackgroundService {
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true,
    );
  }

  Future<void> schedulePeriodicCheck() async {
    await Workmanager().registerPeriodicTask(
      "1",
      backgroundTaskName,
      frequency: const Duration(minutes: 15), // Fréquence minimum pour le test
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresCharging: false, // Pour faciliter les tests
      ),
    );
    print("Tâche de fond planifiée.");
  }

  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    print("Toutes les tâches de fond annulées.");
  }
}
