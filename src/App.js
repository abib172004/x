import React, { useState } from 'react';
import { Routes, Route, Link, useLocation } from 'react-router-dom';
import './App.css';

import TableauDeBord from './composants/TableauDeBord';
import ExplorateurFichiers from './composants/ExplorateurFichiers';
import Appareils from './composants/Appareils';
import Parametres from './composants/Parametres';
import EcranAppairage from './composants/EcranAppairage';

function BarreLaterale() {
  const location = useLocation();
  const estActif = (chemin) => location.pathname === chemin;

  return (
    <nav className="barre-laterale">
      <div className="logo-conteneur">
        <h2>HybridStorage</h2>
      </div>
      <ul>
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

function App() {
  const [estAppaire, definirEstAppaire] = useState(false);

  // Cette fonction sera passée à l'écran d'appairage pour qu'il puisse
  // mettre à jour l'état de l'application principale.
  const handleAppairageReussi = () => {
    definirEstAppaire(true);
  };

  // On vérifie s'il y a déjà des appareils au démarrage (simulation)
  // Dans une vraie app, on appellerait le backend.
  React.useEffect(() => {
    // axios.get(`${API_URL}/api/v1/appareils`).then(reponse => {
    //   if (reponse.data.length > 0) {
    //     definirEstAppaire(true);
    //   }
    // });
  }, []);

  if (!estAppaire) {
    return <EcranAppairage surAppairageReussi={handleAppairageReussi} />;
  }

  return (
    <div className="app-conteneur">
      <BarreLaterale />
      <main className="contenu-principal">
        <Routes>
          <Route path="/" element={<TableauDeBord />} />
          <Route path="/explorateur" element={<ExplorateurFichiers />} />
          <Route path="/appareils" element={<Appareils />} />
          <Route path="/parametres" element={<Parametres />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;
