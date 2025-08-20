import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/auth/auth_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hybrid_storage_app/core/di/service_locator.dart';
import 'package:hybrid_storage_app/core/services/background_service.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final _secureStorage = const FlutterSecureStorage();
  final _backgroundService = getIt<BackgroundService>();

  // Clés pour le stockage sécurisé
  static const _keyDeviceId = 'id_appareil';
  static const _keyDevicePrivateKey = 'cle_privee_mobile';
  static const _keyServerPublicKey = 'cle_publique_serveur';

  // Vérifie le statut d'authentification au démarrage de l'application.
  Future<void> checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      // On vérifie si l'ID de l'appareil est sauvegardé. C'est notre indicateur d'appairage.
      final hasPairedDevice = await _secureStorage.containsKey(key: _keyDeviceId);

      if (hasPairedDevice) {
        emit(AuthAuthenticated());
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  // Méthode appelée après un appairage réussi.
  Future<void> devicePaired({
    required String idAppareil,
    required String clePriveeMobile,
    required String clePubliqueServeur,
  }) async {
    try {
      // Sauvegarde toutes les informations nécessaires à la connexion future.
      await _secureStorage.write(key: _keyDeviceId, value: idAppareil);
      await _secureStorage.write(key: _keyDevicePrivateKey, value: clePriveeMobile);
      await _secureStorage.write(key: _keyServerPublicKey, value: clePubliqueServeur);

      // Planifie la tâche de fond pour les transferts automatiques.
      await _backgroundService.schedulePeriodicCheck();

      emit(AuthAuthenticated());
    } catch (e) {
      // En cas d'erreur de sauvegarde, on ne considère pas l'appairage comme réussi.
      emit(AuthUnauthenticated());
    }
  }

  // Méthode pour se "déconnecter" (supprimer l'appairage).
  Future<void> unpairDevice() async {
    await _secureStorage.delete(key: _keyDeviceId);
    await _secureStorage.delete(key: _keyDevicePrivateKey);
    await _secureStorage.delete(key: _keyServerPublicKey);

    // Annule les tâches de fond planifiées.
    await _backgroundService.cancelAllTasks();

    emit(AuthUnauthenticated());
  }
}
