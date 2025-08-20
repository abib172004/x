import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hybrid_storage_app/bloc/auth/auth_cubit.dart';
import 'package:hybrid_storage_app/core/di/service_locator.dart';
import 'package:hybrid_storage_app/core/services/crypto_service.dart';
import 'package:hybrid_storage_app/core/services/real_communication_service.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:uuid/uuid.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appairer un appareil')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text('Scannez le code affiché sur votre ordinateur.'),
            ),
          )
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing || scanData.code == null) return;

      setState(() { _isProcessing = true; });
      controller.pauseCamera();

      try {
        final decodedQr = jsonDecode(scanData.code!);
        final String nomHote = decodedQr['nom_hote'];
        final String clePubliqueServeurPem = decodedQr['cle_publique_pem'];

        // 1. Générer la paire de clés pour ce mobile
        final cryptoService = getIt<CryptoService>();
        final paireDeClesMobile = cryptoService.genererPaireDeClesRSA();
        final clePubliqueMobilePem = cryptoService.encoderClePubliqueEnPem(paireDeClesMobile.clePublique);

        // 2. Préparer les données à envoyer au serveur
        final donneesAppareil = {
          "id_appareil": const Uuid().v4(), // Génère un ID unique pour ce mobile
          "nom_appareil": "Mon Appareil Mobile", // TODO: Rendre ce nom configurable
          "cle_publique_pem": clePubliqueMobilePem,
        };

        // 3. Envoyer les données au serveur pour compléter l'appairage
        final communicationService = getIt<CommunicationService>() as RealCommunicationService;
        final success = await communicationService.completerAppairage(nomHote, donneesAppareil);

        if (success && mounted) {
          // 4. Sauvegarder les clés et marquer comme authentifié
          // TODO: Vraie sauvegarde des clés dans le secure storage
          context.read<AuthCubit>().devicePaired(
            idAppareil: donneesAppareil['id_appareil']!,
            clePriveeMobile: 'fake_private_key', // Remplacer par la vraie clé
            clePubliqueServeur: clePubliqueServeurPem,
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          throw Exception("L'appairage a échoué côté serveur.");
        }

      } catch (e) {
        print("Erreur d'appairage: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'appairage: ${e.toString()}")),
        );
        controller.resumeCamera();
        setState(() { _isProcessing = false; });
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
