import 'package:get_it/get_it.dart';
import 'package:hybrid_storage_app/core/repositories/settings_repository.dart';
import 'package:hybrid_storage_app/core/repositories/shared_prefs_settings_repository.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';
import 'package:hybrid_storage_app/core/services/crypto_service.dart';
import 'package:hybrid_storage_app/core/services/background_service.dart';
import 'package:hybrid_storage_app/core/services/real_communication_service.dart';

// Instance globale du localisateur de services.
final getIt = GetIt.instance;

// Fonction pour configurer et enregistrer les services.
void setupLocator() {
  // Enregistre le service de communication.
  getIt.registerLazySingleton<CommunicationService>(() => RealCommunicationService());

  // Enregistre le repository des paramètres avec la vraie implémentation.
  getIt.registerLazySingleton<SettingsRepository>(() => SharedPrefsSettingsRepository());

  // Enregistre le service de cryptographie.
  getIt.registerLazySingleton<CryptoService>(() => CryptoService());

  // Enregistre le service de tâches de fond.
  getIt.registerLazySingleton<BackgroundService>(() => BackgroundService());
}
