# -*- coding: utf-8 -*-

# Importations nécessaires depuis FastAPI et autres bibliothèques
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn

# Création de l'instance de l'application FastAPI.
# C'est le cœur de notre backend.
application_fastapi = FastAPI(
    title="API du Stockage Hybride Desktop",
    description="Ce serveur gère les fichiers et la communication avec l'application mobile.",
    version="1.0.0",
)

# Configuration des CORS (Cross-Origin Resource Sharing).
# C'est une mesure de sécurité importante qui permet à notre frontend Electron
# de communiquer avec ce backend, même s'ils n'ont pas la même "origine".
# Ici, nous autorisons toutes les origines, méthodes et en-têtes pour la simplicité
# du développement local. Pour la production, il faudrait être plus restrictif.
application_fastapi.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Accepte les requêtes de n'importe quelle origine.
    allow_credentials=True,
    allow_methods=["*"],  # Accepte toutes les méthodes HTTP (GET, POST, etc.).
    allow_headers=["*"],  # Accepte tous les en-têtes.
)


# Définition d'une "route" ou d'un "endpoint".
# C'est une URL spécifique que le frontend peut appeler pour obtenir une information
# ou déclencher une action.
# Le décorateur `@application_fastapi.get("/")` indique que cette fonction
# répondra aux requêtes HTTP GET sur l'URL racine ("/").
@application_fastapi.get("/")
def lire_racine():
    """
    Endpoint racine qui retourne un message de bienvenue.
    Utile pour vérifier rapidement que le serveur est bien démarré.
    """
    return {"message": "Bienvenue sur le serveur du Stockage Hybride !"}


@application_fastapi.get("/status")
import socket
import hashlib
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

def lire_status():
    """
    Endpoint de statut pour vérifier l'état de santé du serveur.
    L'application Electron pourra appeler cet endpoint pour s'assurer que le backend Python
    est bien en cours d'exécution avant de continuer.
    """
    return {"statut": "ok", "message": "Le serveur est en ligne."}


@application_fastapi.get("/api/v1/appairage/generer-code")
def generer_code_appairage():
    """
    Génère une nouvelle paire de clés cryptographiques et retourne les informations
    nécessaires à l'appairage sous forme de JSON.
    """
    # 1. Générer une nouvelle paire de clés RSA
    cle_privee = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )
    cle_publique = cle_privee.public_key()

    # 2. Sérialiser la clé publique au format PEM (un format standard)
    pem_cle_publique = cle_publique.public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )

    # 3. Calculer l'empreinte de sécurité (SHA-256 de la clé publique) pour la vérification manuelle
    # On utilise le format DER (binaire) pour un hachage cohérent
    der_cle_publique = cle_publique.public_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PublicFormat.SubjectPublicKeyInfo
    )
    hachage = hashlib.sha256(der_cle_publique).hexdigest()
    # Formate l'empreinte pour une meilleure lisibilité (ex: A1:B2:C3...)
    empreinte_formatee = ':'.join(hachage[i:i+2] for i in range(0, 32, 2)).upper()

    # 4. Obtenir le nom de l'hôte de l'ordinateur
    nom_hote = socket.gethostname()

    # TODO: Stocker la clé privée de manière sécurisée pour une utilisation future.
    # Pour l'instant, elle n'est pas sauvegardée et est perdue après cet appel.

    # 5. Construire les données à inclure dans le QR code
    donnees_qr_structure = {
        "nom_hote": nom_hote,
        "cle_publique_pem": pem_cle_publique.decode('utf-8'),
        # On pourrait ajouter d'autres informations ici, comme l'IP locale ou les ports
    }

    # 6. Retourner la réponse complète au frontend
    return {
        "donnees_pour_qr": donnees_qr_structure,
        "empreinte_securite": empreinte_formatee
    }


@application_fastapi.get("/api/v1/tableau-de-bord/statistiques")
def lire_statistiques_tableau_de_bord():
    """
    Retourne des statistiques simulées pour l'affichage sur le tableau de bord.
    """
    # Dans une vraie application, ces données proviendraient de la surveillance
    # du disque, de la base de données des appareils et des journaux d'activité.
    donnees_simulees = {
        "stockage": {
            "totalGo": 1000,
            "utiliseGo": 450,
            "ventilation": [
                {"type": "Photos", "tailleGo": 200},
                {"type": "Vidéos", "tailleGo": 150},
                {"type": "Documents", "tailleGo": 50},
                {"type": "Autres", "tailleGo": 50},
            ]
        },
        "appareilsConnectes": [
            {"nom": "Smartphone de Jules", "type": "Android", "statut": "Connecté"},
            {"nom": "iPhone de Claire", "type": "iOS", "statut": "En veille"},
        ],
        "activiteRecente": [
            {"heure": "14:25", "action": "Transfert de 50 photos terminé depuis \"iPhone de Claire\"."},
            {"heure": "13:10", "action": "Connexion de \"Smartphone de Jules\"."},
            {"heure": "11:50", "action": "Espace de stockage faible détecté sur \"iPhone de Claire\"."},
        ]
    }
    return donnees_simulees


import os
import datetime
from fastapi import Query
from typing import Optional

# Le répertoire de base où tous les fichiers seront stockés.
# Pour la sécurité, l'application ne pourra pas accéder à des fichiers en dehors de ce dossier.
REPERTOIRE_DE_BASE = os.path.join(os.path.expanduser("~"), "HybridStorage")


@application_fastapi.on_event("startup")
def au_demarrage():
    """
    Fonction exécutée au démarrage du serveur pour s'assurer que le répertoire de base existe.
    """
    if not os.path.exists(REPERTOIRE_DE_BASE):
        print(f"Création du répertoire de stockage à: {REPERTOIRE_DE_BASE}")
        os.makedirs(REPERTOIRE_DE_BASE)


@application_fastapi.get("/api/v1/fichiers/lister")
def lister_fichiers(chemin: Optional[str] = Query(default="/")):
    """
    Liste les fichiers et dossiers pour un chemin donné à l'intérieur du répertoire de base.
    """
    try:
        # Sécurisation du chemin pour éviter les attaques de type "directory traversal"
        chemin_securise = os.path.normpath(os.path.join(REPERTOIRE_DE_BASE, chemin.strip('/\\')))
        if not chemin_securise.startswith(os.path.normpath(REPERTOIRE_DE_BASE)):
            return {"erreur": "Accès non autorisé"}

        contenu_repertoire = os.listdir(chemin_securise)
        liste_fichiers = []

        for nom_element in contenu_repertoire:
            chemin_complet = os.path.join(chemin_securise, nom_element)
            stats = os.stat(chemin_complet)
            est_un_dossier = os.path.isdir(chemin_complet)

            infos_element = {
                "nom": nom_element,
                "chemin": os.path.join(chemin, nom_element),
                "type": "dossier" if est_un_dossier else "fichier",
                "tailleOctets": stats.st_size,
                "modifieLe": datetime.datetime.fromtimestamp(stats.st_mtime).isoformat()
            }
            liste_fichiers.append(infos_element)

        return {"chemin_actuel": chemin, "contenu": liste_fichiers}

    except FileNotFoundError:
        return {"erreur": f"Le chemin '{chemin}' n'a pas été trouvé."}
    except Exception as e:
        return {"erreur": f"Une erreur est survenue: {str(e)}"}


# Ce bloc de code est exécuté seulement si le script est lancé directement
# (par exemple, avec `python main.py`).
# Il n'est pas exécuté si le script est importé comme un module.
# C'est utile pour le développement et le test.
if __name__ == "__main__":
    # Lance le serveur Uvicorn, qui est un serveur ASGI (Asynchronous Server Gateway Interface).
    # Il écoute sur l'adresse 127.0.0.1 (localhost) sur le port 8000.
    # `reload=True` permet au serveur de se redémarrer automatiquement si on modifie le code.
    uvicorn.run("main:application_fastapi", host="127.0.0.1", port=8000, reload=True)
