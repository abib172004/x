import 'package:workmanager/workmanager.dart';
import 'package:disk_space/disk_space.dart';
import 'package:hybrid_storage_app/core/di/service_locator.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';
import 'dart:io';

const backgroundTaskName = "hybridStorageCheck";

// Cette fonction est le point d'entrée pour la tâche de fond.
// Elle doit être une fonction de premier niveau (pas à l'intérieur d'une classe).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundTaskName) {
      print("Tâche de fond '$backgroundTaskName' en cours d'exécution...");

      try {
        // 1. Vérifier l'espace disque
        final double? freeSpace = await DiskSpace.getFreeDiskSpace; // en Mo
        final double? totalSpace = await DiskSpace.getTotalDiskSpace; // en Mo

        if (freeSpace == null || totalSpace == null) return false;

        final double freeSpacePercentage = (freeSpace / totalSpace) * 100;
        print("Espace disque libre : ${freeSpacePercentage.toStringAsFixed(2)}%");

        // TODO: Récupérer le seuil depuis les paramètres sauvegardés
        const int seuil = 10;

        if (freeSpacePercentage < seuil) {
          print("Espace disque faible détecté ! Démarrage du transfert automatique.");

          // 2. Identifier les fichiers à transférer
          // Ceci est une simulation. Une vraie app scannerait le stockage.
          final List<File> fichiers_a_transferer = [
            // On ne peut pas créer de vrais fichiers ici, donc on simule
          ];
          print("${fichiers_a_transferer.length} fichiers à transférer (simulation).");

          // 3. Lancer le transfert
          // On ne peut pas facilement injecter de dépendances ici,
          // donc on devrait avoir une logique plus complexe pour accéder au service.
          // Pour la démo, on suppose qu'on peut l'appeler.
          // final communicationService = getIt<CommunicationService>();
          // for (var fichier in fichiers_a_transferer) {
          //   await communicationService.uploadFile(fichier, '/auto-transfer/${fichier.path.split('/').last}');
          // }
        } else {
          print("Espace disque suffisant.");
        }

        return Future.value(true);
      } catch (err) {
        print("Erreur dans la tâche de fond : $err");
        return Future.value(false);
      }
    }
    return Future.value(false);
  });
}

class BackgroundService {
  Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Affiche les logs en mode debug
    );
  }

  Future<void> schedulePeriodicCheck() async {
    await Workmanager().registerPeriodicTask(
      "1", // ID unique de la tâche
      backgroundTaskName,
      frequency: const Duration(hours: 1), // Vérifie toutes les heures
      constraints: Constraints(
        networkType: NetworkType.unmetered, // Uniquement en Wi-Fi
        requiresCharging: true, // Uniquement en charge
      ),
    );
    print("Tâche de fond planifiée pour s'exécuter toutes les heures en Wi-Fi et en charge.");
  }

  Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    print("Toutes les tâches de fond annulées.");
  }
}
