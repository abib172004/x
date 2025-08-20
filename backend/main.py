# -*- coding: utf-8 -*-

import os
import socket
import hashlib
import datetime
import json
from typing import Optional, List

from fastapi import FastAPI, Query, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
import uvicorn

# --- Gestionnaire de Connexions WebSocket ---
class GestionnaireConnexions:
    def __init__(self):
        self.connexions_actives: List[WebSocket] = []
    async def connecter(self, websocket: WebSocket):
        await websocket.accept()
        self.connexions_actives.append(websocket)
    def deconnecter(self, websocket: WebSocket):
        self.connexions_actives.remove(websocket)
    async def envoyer_message_personnel(self, message: str, websocket: WebSocket):
        await websocket.send_text(message)

gestionnaire = GestionnaireConnexions()

# --- Configuration de l'application FastAPI ---
application_fastapi = FastAPI(title="API du Stockage Hybride Desktop")
application_fastapi.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"],
)

# --- "Base de données" en mémoire ---
REPERTOIRE_DE_BASE = os.path.join(os.path.expanduser("~"), "HybridStorage")
appareils_appaires_db = {}
cle_privee_serveur = None
parametres_db = {
    "stockage": {"dossier_principal": REPERTOIRE_DE_BASE},
    "application": {"lancement_demarrage": True, "theme": "systeme"},
    "reseau": {"port_ecoute": 8000},
}

@application_fastapi.on_event("startup")
def au_demarrage():
    global cle_privee_serveur
    if not os.path.exists(REPERTOIRE_DE_BASE):
        os.makedirs(REPERTOIRE_DE_BASE)
    cle_privee_serveur = rsa.generate_private_key(public_exponent=65537, key_size=2048)

# --- Modèles Pydantic ---
class AppareilClient(BaseModel):
    id_appareil: str
    nom_appareil: str
    cle_publique_pem: str

class ParametresStockage(BaseModel):
    dossier_principal: str
class ParametresApplication(BaseModel):
    lancement_demarrage: bool
    theme: str
class ParametresReseau(BaseModel):
    port_ecoute: int
class ParametresComplets(BaseModel):
    stockage: ParametresStockage
    application: ParametresApplication
    reseau: ParametresReseau

# --- Endpoints HTTP ---
@application_fastapi.get("/")
def lire_racine():
    return {"message": "Bienvenue !"}

@application_fastapi.get("/api/v1/appairage/generer-code")
def generer_code_appairage():
    cle_publique = cle_privee_serveur.public_key()
    pem_cle_publique = cle_publique.public_bytes(encoding=serialization.Encoding.PEM, format=serialization.PublicFormat.SubjectPublicKeyInfo)
    der_cle_publique = cle_publique.public_bytes(encoding=serialization.Encoding.DER, format=serialization.PublicFormat.SubjectPublicKeyInfo)
    hachage = hashlib.sha256(der_cle_publique).hexdigest()
    empreinte_formatee = ':'.join(hachage[i:i+2] for i in range(0, 32, 2)).upper()
    donnees_qr = {"nom_hote": socket.gethostname(), "cle_publique_pem": pem_cle_publique.decode('utf-8')}
    return {"donnees_pour_qr": donnees_qr, "empreinte_securite": empreinte_formatee}

@application_fastapi.post("/api/v1/appairage/completer")
def completer_appairage(appareil_client: AppareilClient):
    appareils_appaires_db[appareil_client.id_appareil] = appareil_client.dict()
    return {"statut": "succes"}

@application_fastapi.get("/api/v1/appareils")
def lister_appareils():
    return list(appareils_appaires_db.values())

@application_fastapi.delete("/api/v1/appareils/{id_appareil}")
def revoquer_appareil(id_appareil: str):
    if id_appareil in appareils_appaires_db:
        del appareils_appaires_db[id_appareil]
        return {"statut": "succes"}
    return {"statut": "erreur"}

def lister_fichiers_logique(chemin: str):
    chemin_securise = os.path.normpath(os.path.join(REPERTOIRE_DE_BASE, chemin.strip('/\\')))
    if not chemin_securise.startswith(os.path.normpath(REPERTOIRE_DE_BASE)):
        raise ValueError("Accès non autorisé")
    contenu = []
    for nom in os.listdir(chemin_securise):
        chemin_complet = os.path.join(chemin_securise, nom)
        stats = os.stat(chemin_complet)
        contenu.append({
            "nom": nom, "chemin": os.path.join(chemin, nom),
            "type": "dossier" if os.path.isdir(chemin_complet) else "fichier",
            "tailleOctets": stats.st_size,
            "modifieLe": datetime.datetime.fromtimestamp(stats.st_mtime).isoformat()
        })
    return {"chemin_actuel": chemin, "contenu": contenu}

@application_fastapi.get("/api/v1/fichiers/lister")
def lister_fichiers_http(chemin: Optional[str] = Query(default="/")):
    try:
        return lister_fichiers_logique(chemin)
    except Exception as e:
        return {"erreur": str(e)}

@application_fastapi.get("/api/v1/parametres")
def lire_parametres():
    return parametres_db

@application_fastapi.post("/api/v1/parametres")
def sauvegarder_parametres(parametres: ParametresComplets):
    global parametres_db
    parametres_db = parametres.dict()
    print(f"Paramètres sauvegardés: {parametres_db}")
    return {"statut": "succes"}

# --- Endpoint WebSocket ---
@application_fastapi.websocket("/ws/{id_appareil}")
async def websocket_endpoint(websocket: WebSocket, id_appareil: str):
    if id_appareil not in appareils_appaires_db:
        await websocket.close(code=1008); return
    await gestionnaire.connecter(websocket)
    try:
        while True:
            donnees = await websocket.receive_text()
            message = json.loads(donnees)
            action = message.get("action")
            if action == "lister_fichiers":
                chemin = message.get("charge_utile", {}).get("chemin", "/")
                try:
                    reponse = {"action": "liste_fichiers", "statut": "succes", "donnees": lister_fichiers_logique(chemin)}
                except Exception as e:
                    reponse = {"action": "liste_fichiers", "statut": "erreur", "message": str(e)}
                await gestionnaire.envoyer_message_personnel(json.dumps(reponse), websocket)
    except WebSocketDisconnect:
        gestionnaire.deconnecter(websocket)

# --- Lancement ---
if __name__ == "__main__":
    uvicorn.run("main:application_fastapi", host="127.0.0.1", port=8000, reload=True)
