import 'package:flutter/material.dart';

class DeviceManagementScreen extends StatelessWidget {
  const DeviceManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appareils Appairés'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.computer, color: Colors.green),
            title: const Text('PC-DE-BUREAU'),
            subtitle: const Text('Connecté'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                // TODO: Implémenter la logique de dissociation.
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.laptop_mac),
            title: const Text('MacBook Pro'),
            subtitle: const Text('Dernière connexion: hier'),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () {
                // TODO: Implémenter la logique de dissociation.
              },
            ),
          ),
        ],
      ),
    );
  }
}
