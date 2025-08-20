import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/auth/auth_state.dart';
import 'package:hybrid_storage_app/ui/screens/main_layout.dart';
import 'package:hybrid_storage_app/ui/theme/app_theme.dart';
import 'package:hybrid_storage_app/bloc/auth/auth_cubit.dart';
import 'package:hybrid_storage_app/ui/screens/onboarding/welcome_screen.dart';
import 'package:hybrid_storage_app/core/di/service_locator.dart';

// Point d'entrée de l'application.
void main() {
  // Assure que les bindings Flutter sont initialisés avant toute opération asynchrone.
  WidgetsFlutterBinding.ensureInitialized();
  // Configure le localisateur de services pour l'injection de dépendances.
  setupLocator();
  // Lance l'application.
  runApp(const HybridStorageApp());
}

class HybridStorageApp extends StatelessWidget {
  const HybridStorageApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Le BlocProvider pour l'authentification est placé ici pour être accessible
    // partout dans l'application, car il détermine l'écran à afficher.
    return BlocProvider(
      create: (context) => AuthCubit()..checkAuthStatus(),
      child: MaterialApp(
        title: 'Hybrid Storage',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // S'adapte au thème du système.
        debugShowCheckedModeBanner: false,
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              // Si l'utilisateur est authentifié (appareil appairé),
              // on affiche l'écran principal.
              return const MainLayout();
            } else {
              // Sinon, on affiche l'écran de bienvenue pour démarrer l'appairage.
              return const WelcomeScreen();
            }
          },
        ),
      ),
    );
  }
}
