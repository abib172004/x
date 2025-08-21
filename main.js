// Importations des modules nécessaires d'Electron.
const { app, BrowserWindow } = require('electron');
const path = require('path');
const { spawn } = require('child_process'); // Pour lancer le processus Python

// Variable globale pour garder une référence à la fenêtre principale.
// Si on ne fait pas ça, la fenêtre pourrait être fermée automatiquement
// lorsque l'objet JavaScript est récupéré par le ramasse-miettes (garbage collector).
let fenetre_principale;
let processus_fastapi;
let processus_grpc;

// Fonction pour créer la fenêtre de l'application.
function creer_fenetre() {
  // Crée une nouvelle fenêtre de navigateur.
  fenetre_principale = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      // Le `preload.js` n'est pas utilisé dans cette configuration simple,
      // mais il est essentiel pour une communication sécurisée entre le processus principal
      // et le processus de rendu (le frontend React).
      // preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: true, // Non recommandé pour la production, mais simple pour démarrer.
      contextIsolation: false, // Idem.
    },
  });

  // Charge l'URL du frontend React.
  // En développement, React est servi par `react-scripts` sur le port 3000.
  fenetre_principale.loadURL('http://localhost:3000');

  // Ouvre les Outils de Développement (DevTools) pour le débogage.
  fenetre_principale.webContents.openDevTools();

  // Émis lorsque la fenêtre est fermée.
  fenetre_principale.on('closed', () => {
    // Supprime la référence à la fenêtre.
    fenetre_principale = null;
  });
}

// Fonctions pour démarrer les serveurs backend.
function demarrer_serveur_fastapi() {
  console.log('Démarrage du serveur FastAPI sur le port 8001...');
  processus_fastapi = spawn('python', ['-m', 'uvicorn', 'main:application_fastapi', '--host', '127.0.0.1', '--port', '8001'], {
    cwd: path.join(__dirname, 'backend'),
    shell: true,
  });

  processus_fastapi.stdout.on('data', (data) => console.log(`[FastAPI]: ${data}`));
  processus_fastapi.stderr.on('data', (data) => console.error(`[Erreur FastAPI]: ${data}`));
}

function demarrer_serveur_grpc() {
  console.log('Démarrage du serveur gRPC...');
  processus_grpc = spawn('python', ['grpc_server.py'], {
    cwd: path.join(__dirname, 'backend'),
    shell: true,
  });

  processus_grpc.stdout.on('data', (data) => console.log(`[gRPC]: ${data}`));
  processus_grpc.stderr.on('data', (data) => console.error(`[Erreur gRPC]: ${data}`));
}

// Cette méthode sera appelée quand Electron aura fini
// son initialisation et sera prêt à créer des fenêtres de navigateur.
// Certaines APIs peuvent être utilisées uniquement après cet événement.
app.on('ready', () => {
  demarrer_serveur_fastapi();
  demarrer_serveur_grpc();
  creer_fenetre();
});

// Quitte l'application quand toutes les fenêtres sont fermées.
app.on('window-all-closed', () => {
  // Sur macOS, il est commun pour les applications et leur barre de menu
  // de rester actives jusqu'à ce que l'utilisateur quitte explicitement avec Cmd + Q.
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// Sur macOS, il est commun de recréer une fenêtre dans l'application quand
// l'icône du dock est cliquée et qu'il n'y a pas d'autres fenêtres d'ouvertes.
app.on('activate', () => {
  if (fenetre_principale === null) {
    creer_fenetre();
  }
});

// Assure que les processus Python sont bien terminés quand l'application Electron quitte.
app.on('will-quit', () => {
  console.log('Arrêt des serveurs backend...');
  if (processus_fastapi) processus_fastapi.kill();
  if (processus_grpc) processus_grpc.kill();
});
