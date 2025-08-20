import 'package:pointycastle/export.dart' as pc;
import 'dart:convert';
import 'dart:typed_data';
import 'package:asn1lib/asn1lib.dart';

// Modèle pour contenir la paire de clés
class PaireDeCles {
  final pc.RSAPublicKey clePublique;
  final pc.RSAPrivateKey clePrivee;

  PaireDeCles(this.clePublique, this.clePrivee);
}

// Service pour gérer les opérations de cryptographie
class CryptoService {

  // Génère une nouvelle paire de clés RSA
  PaireDeCles genererPaireDeClesRSA() {
    final keyGen = pc.RSAKeyGenerator()
      ..init(pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
        _getSecureRandom(),
      ));

    final pair = keyGen.generateKeyPair();
    return PaireDeCles(pair.publicKey as pc.RSAPublicKey, pair.privateKey as pc.RSAPrivateKey);
  }

  // Encode une clé publique au format PEM PKCS#1
  String encoderClePubliqueEnPem(pc.RSAPublicKey clePublique) {
    var asn1RsaPublicKey = ASN1Sequence();
    asn1RsaPublicKey.add(ASN1Integer(clePublique.modulus!));
    asn1RsaPublicKey.add(ASN1Integer(clePublique.exponent!));
    var asn1Sequence = ASN1Sequence();
    asn1Sequence.add(ASN1Object.fromBytes(Uint8List.fromList([0x6, 0x9, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0xd, 0x1, 0x1, 0x1])));
    asn1Sequence.add(ASN1Null());
    var asn1BitString = ASN1BitString(stringValues: asn1RsaPublicKey.encodedBytes);
    var topLevelSeq = ASN1Sequence();
    topLevelSeq.add(asn1Sequence);
    topLevelSeq.add(asn1BitString);

    var dataBase64 = base64.encode(topLevelSeq.encodedBytes);
    return """-----BEGIN PUBLIC KEY-----\n$dataBase64\n-----END PUBLIC KEY-----""";
  }

  // Fournit un générateur de nombres aléatoires sécurisé
  pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final seedSource = pc.Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextUint8());
    }
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}
