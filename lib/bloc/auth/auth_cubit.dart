import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/auth/auth_state.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Un Cubit est une version simplifiée d'un BLoC qui n'a pas d'Événements
// et expose directement des fonctions pour changer l'état.
// C'est parfait pour une logique simple comme la gestion de l'état d'appairage.

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  // Utilisation de flutter_secure_storage pour vérifier si une clé d'appairage existe.
  // C'est un indicateur simple pour savoir si l'app a déjà été appairée.
  final _secureStorage = const FlutterSecureStorage();
  static const _pairingKey = 'device_paired_certificate';

  // Vérifie le statut d'authentification au démarrage de l'application.
  Future<void> checkAuthStatus() async {
    // Simule une petite latence pour un effet de chargement.
    await Future.delayed(const Duration(seconds: 1));

    try {
      final hasPairedDevice = await _secureStorage.containsKey(key: _pairingKey);

      if (hasPairedDevice) {
        // Si une clé existe, on considère l'utilisateur comme authentifié.
        emit(AuthAuthenticated());
      } else {
        // Sinon, il doit passer par l'appairage.
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      // En cas d'erreur, on assume non authentifié.
      emit(AuthUnauthenticated());
    }
  }

  // Méthode appelée après un appairage réussi.
  Future<void> devicePaired() async {
    // Stocke une valeur factice pour indiquer que l'appairage a eu lieu.
    // Dans une vraie implémentation, on stockerait le certificat ou une clé.
    await _secureStorage.write(key: _pairingKey, value: 'true');
    emit(AuthAuthenticated());
  }

  // Méthode pour se "déconnecter" (supprimer l'appairage).
  Future<void> unpairDevice() async {
    await _secureStorage.delete(key: _pairingKey);
    emit(AuthUnauthenticated());
  }
}
