import React from 'react';
import { Routes, Route, Link, useLocation } from 'react-router-dom';
import './App.css'; // Importation des styles

// Importation des composants pour chaque écran
import TableauDeBord from './composants/TableauDeBord';
import ExplorateurFichiers from './composants/ExplorateurFichiers';
// import Appareils from './composants/Appareils';
// import Parametres from './composants/Parametres';
import EcranAppairage from './composants/EcranAppairage';

// Composant de navigation latérale (Sidebar)
function BarreLaterale() {
  const location = useLocation(); // Hook pour obtenir l'URL actuelle

  // Fonction pour déterminer si un lien est actif
  const estActif = (chemin) => location.pathname === chemin;

  return (
    <nav className="barre-laterale">
      <div className="logo-conteneur">
        {/* Placeholder pour le logo */}
        <h2>HybridStorage</h2>
      </div>
      <ul>
        {/* Les liens de navigation. La classe 'actif' est ajoutée si le lien correspond à la page actuelle. */}
        <li className={estActif('/') ? 'actif' : ''}>
          <Link to="/">Tableau de bord</Link>
        </li>
        <li className={estActif('/explorateur') ? 'actif' : ''}>
          <Link to="/explorateur">Explorateur</Link>
        </li>
        <li className={estActif('/appareils') ? 'actif' : ''}>
          <Link to="/appareils">Appareils</Link>
        </li>
        <li className={estActif('/parametres') ? 'actif' : ''}>
          <Link to="/parametres">Paramètres</Link>
        </li>
      </ul>
    </nav>
  );
}

// Composant principal de l'application
function App() {
  // Pour le développement, on passe à `true` pour voir l'interface principale.
  // Dans une vraie application, cet état serait géré dynamiquement.
  const estAppaire = true;

  if (!estAppaire) {
    return <EcranAppairage />;
  }

  return (
    <div className="app-conteneur">
      <BarreLaterale />
      <main className="contenu-principal">
        <Routes>
          {/* Définition des routes. Chaque route correspond à un écran. */}
          <Route path="/" element={<TableauDeBord />} />
          <Route path="/explorateur" element={<ExplorateurFichiers />} />
          {/* <Route path="/appareils" element={<Appareils />} /> */}
          {/* <Route path="/parametres" element={<Parametres />} /> */}
        </Routes>
      </main>
    </div>
  );
}

export default App;
