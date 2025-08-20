import 'package:flutter/material.dart';

// Écran des paramètres.
// Permet à l'utilisateur de configurer l'application.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          // Section pour la gestion des appareils
          const ListTile(
            leading: Icon(Icons.devices),
            title: Text('Appareils Appairés'),
            subtitle: Text('Gérer les ordinateurs connectés'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Naviguer vers l'écran de gestion des appareils.
            },
          ),
          const Divider(),

          // Section pour les règles de transfert
          ListTile(
            title: Text('Règles de Transfert', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: const Text('Transfert automatique'),
            subtitle: const Text('Transférer les fichiers automatiquement'),
            value: true, // TODO: Lier à l'état du BLoC
            onChanged: (bool value) {
              // TODO: Mettre à jour l'état via le BLoC.
            },
          ),
          ListTile(
            title: const Text('Seuil de déclenchement'),
            subtitle: const Text('Quand l\'espace est inférieur à 10%'),
            onTap: () {
              // TODO: Afficher un dialogue pour changer la valeur.
            },
          ),
          const Divider(),

          // Section pour la sécurité
          ListTile(
            title: Text('Sécurité', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            title: Text('Chiffrement'),
            subtitle: Text('Activé (AES-256-GCM)'),
          ),
          ListTile(
            title: const Text('Changer le mot de passe'),
            onTap: () {
              // TODO: Implémenter le flux de changement de mot de passe.
            },
          ),
          const Divider(),

          // Section "À propos"
          ListTile(
            title: Text('À propos', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          ),
          const ListTile(
            title: Text('Version de l'application'),
            subtitle: Text('1.0.0 (Build 1)'),
          ),
          ListTile(
            title: const Text('Licences open source'),
            onTap: () {
              // TODO: Afficher la page des licences.
            },
          ),
        ],
      ),
    );
  }
}
