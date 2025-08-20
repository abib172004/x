import React, { useState, useEffect } from 'react';
import axios from 'axios'; // Pour faire des requêtes HTTP vers le backend
import { QRCodeSVG } from 'qrcode.react'; // Pour générer le QR code
import './EcranAppairage.css'; // Styles spécifiques à cet écran

// L'URL de base de notre API backend.
// En développement, le serveur Python tourne sur le port 8000.
const API_URL = 'http://localhost:8000';

function EcranAppairage() {
  // Déclaration des états du composant avec le hook `useState`.
  const [donnees_qr, definir_donnees_qr] = useState(null); // Pour stocker les données du QR code
  const [empreinte, definir_empreinte] = useState(''); // Pour stocker l'empreinte de sécurité
  const [erreur, definir_erreur] = useState(''); // Pour gérer les erreurs

  // Le hook `useEffect` est utilisé pour exécuter du code après le rendu du composant.
  // C'est l'endroit idéal pour aller chercher des données.
  useEffect(() => {
    // Fonction asynchrone pour générer les informations d'appairage.
    const generer_infos_appairage = async () => {
      try {
        // Fait un appel GET à l'endpoint du backend.
        const reponse = await axios.get(`${API_URL}/api/v1/appairage/generer-code`);

        // Les données pour le QR code sont un objet JSON, nous devons le convertir en chaîne.
        const donnees_qr_en_chaine = JSON.stringify(reponse.data.donnees_pour_qr);

        // Met à jour les états avec les données reçues du backend.
        definir_donnees_qr(donnees_qr_en_chaine);
        definir_empreinte(reponse.data.empreinte_securite);
        definir_erreur(''); // Réinitialise les erreurs
      } catch (err) {
        // En cas d'erreur (ex: le backend ne répond pas), on met à jour l'état d'erreur.
        console.error("Erreur lors de la génération des informations d'appairage:", err);
        definir_erreur('Impossible de contacter le serveur. Veuillez vérifier qu\'il est bien lancé.');
      }
    };

    generer_infos_appairage();
  }, []); // Le tableau vide `[]` signifie que cet effet ne s'exécute qu'une seule fois, au montage du composant.

  return (
    <div className="ecran-appairage-conteneur">
      <div className="carte-appairage">
        <h1>Appairer un nouvel appareil</h1>
        <p>Scannez ce QR code avec l'application mobile Hybrid Storage pour connecter votre appareil.</p>

        <div className="qr-code-wrapper">
          {/* Affiche le QR code si les données sont prêtes, sinon un message de chargement ou une erreur. */}
          {donnees_qr ? (
            <QRCodeSVG value={donnees_qr} size={256} bgColor={"#ffffff"} fgColor={"#000000"} />
          ) : (
            <p>{erreur ? erreur : 'Génération du code...'}</p>
          )}
        </div>

        <div className="empreinte-conteneur">
          <h2>Empreinte de sécurité</h2>
          <p>Pour plus de sécurité, vérifiez que cette empreinte correspond à celle affichée sur votre mobile.</p>
          {/* Affiche l'empreinte si elle est prête. */}
          {empreinte && <pre className="empreinte-texte">{empreinte}</pre>}
        </div>

        <div className="statut-connexion">
          <p>En attente d'une connexion...</p>
        </div>
      </div>
    </div>
  );
}

export default EcranAppairage;
