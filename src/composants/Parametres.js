import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './Parametres.css';

const API_URL = 'http://localhost:8000';

function Parametres() {
  const [parametres, definirParametres] = useState(null);
  const [erreur, definirErreur] = useState('');
  const [chargement, definirChargement] = useState(true);

  // Récupère les paramètres initiaux depuis le backend
  useEffect(() => {
    const recupererParametres = async () => {
      definirChargement(true);
      try {
        const reponse = await axios.get(`${API_URL}/api/v1/parametres`);
        definirParametres(reponse.data);
      } catch (err) {
        definirErreur('Impossible de charger les paramètres.');
        console.error(err);
      } finally {
        definirChargement(false);
      }
    };
    recupererParametres();
  }, []);

  // Gestionnaire générique pour les changements dans les champs
  const handleChangement = (categorie, cle, valeur) => {
    definirParametres(prev => ({
      ...prev,
      [categorie]: {
        ...prev[categorie],
        [cle]: valeur,
      }
    }));
  };

  const sauvegarderParametres = async () => {
    try {
      await axios.post(`${API_URL}/api/v1/parametres`, parametres);
      alert("Paramètres sauvegardés avec succès !");
    } catch (err) {
      alert("Erreur lors de la sauvegarde des paramètres.");
      console.error(err);
    }
  };

  if (chargement) return <div>Chargement des paramètres...</div>;
  if (erreur) return <div className="erreur-message">{erreur}</div>;
  if (!parametres) return <div>Aucun paramètre trouvé.</div>;

  return (
    <div className="ecran-parametres">
      <h1>Paramètres</h1>

      <div className="section-parametres">
        <h2>Stockage</h2>
        <div className="champ-parametre">
          <label htmlFor="dossier_principal">Dossier de stockage principal</label>
          <div className="champ-avec-bouton">
            <input
              type="text"
              id="dossier_principal"
              value={parametres.stockage.dossier_principal}
              onChange={(e) => handleChangement('stockage', 'dossier_principal', e.target.value)}
            />
            <button>Parcourir...</button>
          </div>
        </div>
      </div>

      <div className="section-parametres">
        <h2>Application</h2>
        <div className="champ-parametre-checkbox">
          <input
            type="checkbox"
            id="lancement_demarrage"
            checked={parametres.application.lancement_demarrage}
            onChange={(e) => handleChangement('application', 'lancement_demarrage', e.target.checked)}
          />
          <label htmlFor="lancement_demarrage">Lancer l'application au démarrage du système</label>
        </div>
      </div>

      <div className="actions-globales">
        <button className="bouton-sauvegarder" onClick={sauvegarderParametres}>
          Sauvegarder les changements
        </button>
      </div>
    </div>
  );
}

export default Parametres;
