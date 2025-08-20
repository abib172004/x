import 'package:get_it/get_it.dart';
import 'package:hybrid_storage_app/core/repositories/mock_settings_repository.dart';
import 'package:hybrid_storage_app/core/repositories/settings_repository.dart';
import 'package:hybrid_storage_app/core/services/communication_service.dart';
import 'package:hybrid_storage_app/core/services/mock_communication_service.dart';

// Instance globale du localisateur de services.
final getIt = GetIt.instance;

// Fonction pour configurer et enregistrer les services.
void setupLocator() {
  // Enregistre le service de communication.
  // getIt.registerLazySingleton<T>(() => Implementation());
  // Un "Lazy Singleton" signifie que l'instance de MockCommunicationService ne sera
  // créée que la première fois qu'elle est demandée.

  // Pour le développement, nous enregistrons l'implémentation de simulation.
  // Pour la production, il suffirait de changer cette ligne pour enregistrer la vraie implémentation.
  getIt.registerLazySingleton<CommunicationService>(() => MockCommunicationService());

  // Enregistre le repository des paramètres.
  getIt.registerLazySingleton<SettingsRepository>(() => MockSettingsRepository());
}
