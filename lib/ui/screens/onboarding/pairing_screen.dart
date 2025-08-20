import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/auth/auth_cubit.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';

// Écran d'appairage où l'utilisateur découvre et se connecte à l'ordinateur.
class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  // final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  // QRViewController? controller;
  bool _isDiscovering = true;

  @override
  void initState() {
    super.initState();
    // Simule une découverte réseau
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isDiscovering = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appairer un appareil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Scannez le QR code affiché sur l\'application de votre ordinateur.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Placeholder pour la vue du scanner QR
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('Vue du scanner QR'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Section pour la découverte automatique
            _isDiscovering
                ? const Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Découverte des ordinateurs sur le réseau...'),
                    ],
                  )
                : Card(
                    child: ListTile(
                      leading: const Icon(Icons.computer),
                      title: const Text('PC-DE-BUREAU'),
                      subtitle: const Text('Prêt pour l\'appairage'),
                      trailing: ElevatedButton(
                        child: const Text('Appairer'),
                        onPressed: () {
                          // Simule un appairage réussi
                          context.read<AuthCubit>().devicePaired();
                          // Retour à l'écran principal
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                      ),
                    ),
                  ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // TODO: Implémenter la saisie manuelle de l'IP
              },
              child: const Text('Saisir une adresse IP manuellement'),
            ),
          ],
        ),
      ),
    );
  }
}
