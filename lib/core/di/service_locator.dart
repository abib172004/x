import 'package:get_it/get_it.dart';
import 'package:hybrid_storage_app/core/repositories/mock_settings_repository.dart';
import 'package:hybrid_storage_app/core/repositories/settings_repository.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';
import 'package:hybrid_storage_app/core/services/mock_communication_service.dart';

import 'package:hybrid_storage_app/core/services/real_communication_service.dart';

// Instance globale du localisateur de services.
final getIt = GetIt.instance;

// Fonction pour configurer et enregistrer les services.
void setupLocator() {
  // Enregistre le service de communication.
  // On utilise maintenant la vraie implémentation au lieu de la simulation.
  getIt.registerLazySingleton<CommunicationService>(() => RealCommunicationService());

  // Enregistre le repository des paramètres.
  getIt.registerLazySingleton<SettingsRepository>(() => MockSettingsRepository());
}
