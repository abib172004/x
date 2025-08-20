// Importations des modules nécessaires d'Electron.
const { app, BrowserWindow } = require('electron');
const path = require('path');
const { spawn } = require('child_process'); // Pour lancer le processus Python

// Variable globale pour garder une référence à la fenêtre principale.
// Si on ne fait pas ça, la fenêtre pourrait être fermée automatiquement
// lorsque l'objet JavaScript est récupéré par le ramasse-miettes (garbage collector).
let fenetre_principale;
let processus_python;

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

// Fonction pour démarrer le serveur backend Python.
function demarrer_backend() {
  console.log('Démarrage du serveur backend Python...');
  // Utilise `spawn` pour lancer le serveur uvicorn.
  // Le chemin vers le script python est relatif.
  processus_python = spawn('python', ['-m', 'uvicorn', 'main:application_fastapi', '--host', '127.0.0.1', '--port', '8000'], {
    cwd: path.join(__dirname, 'backend'), // Spécifie le répertoire de travail pour le processus Python.
    shell: true,
  });

  // Affiche la sortie standard du processus Python dans la console d'Electron.
  processus_python.stdout.on('data', (donnees) => {
    console.log(`[Backend Python]: ${donnees}`);
  });

  // Affiche les erreurs du processus Python.
  processus_python.stderr.on('data', (donnees) => {
    console.error(`[Erreur Backend Python]: ${donnees}`);
  });

  processus_python.on('close', (code) => {
    console.log(`Le processus backend Python s'est terminé avec le code ${code}`);
  });
}

// Cette méthode sera appelée quand Electron aura fini
// son initialisation et sera prêt à créer des fenêtres de navigateur.
// Certaines APIs peuvent être utilisées uniquement après cet événement.
app.on('ready', () => {
  demarrer_backend();
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

// Assure que le processus Python est bien terminé quand l'application Electron quitte.
app.on('will-quit', () => {
  if (processus_python) {
    console.log('Arrêt du processus backend Python...');
    processus_python.kill();
  }
});
