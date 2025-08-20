import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './ExplorateurFichiers.css';

const API_URL = 'http://localhost:8000';

// --- Helper Functions ---

// Formate les octets en une chaîne lisible (Ko, Mo, Go)
const formaterTaille = (octets) => {
  if (octets === 0) return '0 o';
  const k = 1024;
  const tailles = ['o', 'Ko', 'Mo', 'Go', 'To'];
  const i = Math.floor(Math.log(octets) / Math.log(k));
  return parseFloat((octets / Math.pow(k, i)).toFixed(2)) + ' ' + tailles[i];
};

// Formate la date ISO en un format plus simple (JJ/MM/AAAA)
const formaterDate = (dateISO) => {
  return new Date(dateISO).toLocaleDateString('fr-FR');
};

// Retourne une icône textuelle simple basée sur le type de fichier
const obtenirIcone = (type, nom) => {
  if (type === 'dossier') return '📁';
  const extension = nom.split('.').pop().toLowerCase();
  if (['jpg', 'png', 'gif'].includes(extension)) return '🖼️';
  if (['mp4', 'mov', 'avi'].includes(extension)) return '🎬';
  if (['doc', 'docx', 'pdf'].includes(extension)) return '📄';
  return '❔';
};


// --- React Component ---

function ExplorateurFichiers() {
  const [cheminActuel, definirCheminActuel] = useState('/');
  const [contenu, definirContenu] = useState([]);
  const [fichierSelectionne, definirFichierSelectionne] = useState(null);
  const [vueEnGrille, definirVueEnGrille] = useState(false);
  const [erreur, definirErreur] = useState('');
  const [chargement, definirChargement] = useState(true);

  // Hook pour récupérer les données du backend à chaque changement de `cheminActuel`
  useEffect(() => {
    const listerContenu = async () => {
      definirChargement(true);
      definirErreur('');
      try {
        const reponse = await axios.get(`${API_URL}/api/v1/fichiers/lister`, {
          params: { chemin: cheminActuel }
        });
        if (reponse.data.erreur) {
          definirErreur(reponse.data.erreur);
          definirContenu([]);
        } else {
          definirContenu(reponse.data.contenu);
        }
      } catch (err) {
        definirErreur('Impossible de contacter le serveur.');
        console.error(err);
      } finally {
        definirChargement(false);
      }
    };
    listerContenu();
  }, [cheminActuel]);

  const handleItemClick = (item) => {
    if (item.type === 'dossier') {
      definirCheminActuel(item.chemin);
      definirFichierSelectionne(null);
    } else {
      definirFichierSelectionne(item);
    }
  };

  const allerAuParent = () => {
    if (cheminActuel === '/') return;
    const segments = cheminActuel.split('/').filter(Boolean);
    segments.pop();
    definirCheminActuel('/' + segments.join('/'));
  };

  return (
    <div className="explorateur-conteneur">
      <div className="explorateur-principal">
        <div className="barre-outils">
          <div className="navigation-chemin">
            {cheminActuel !== '/' && <button onClick={allerAuParent}>↑ Parent</button>}
            <span>Chemin: {cheminActuel}</span>
          </div>
          <div className="actions-vue">
            <button onClick={() => definirVueEnGrille(false)} disabled={!vueEnGrille}>Liste</button>
            <button onClick={() => definirVueEnGrille(true)} disabled={vueEnGrille}>Grille</button>
          </div>
        </div>

        <div className={`liste-fichiers ${vueEnGrille ? 'vue-grille' : 'vue-liste'}`}>
          {chargement ? <p>Chargement...</p> :
           erreur ? <p className="erreur-message">{erreur}</p> :
           contenu.map((item, index) => (
            <div
              key={index}
              className={`item-fichier ${fichierSelectionne === item ? 'selectionne' : ''}`}
              onClick={() => handleItemClick(item)}
              onDoubleClick={() => item.type === 'dossier' && handleItemClick(item)}
            >
              <span className="icone-fichier">{obtenirIcone(item.type, item.nom)}</span>
              <span className="nom-fichier">{item.nom}</span>
              {!vueEnGrille && <span className="taille-fichier">{formaterTaille(item.tailleOctets)}</span>}
              {!vueEnGrille && <span className="date-fichier">{formaterDate(item.modifieLe)}</span>}
            </div>
          ))}
        </div>
      </div>

      {fichierSelectionne && (
        <div className="panneau-previsualisation">
          <h3>Détails</h3>
          <div className="details-contenu">
            <span className="icone-preview">{obtenirIcone(fichierSelectionne.type, fichierSelectionne.nom)}</span>
            <strong>Nom:</strong>
            <p>{fichierSelectionne.nom}</p>
            <strong>Taille:</strong>
            <p>{formaterTaille(fichierSelectionne.tailleOctets)}</p>
            <strong>Modifié le:</strong>
            <p>{formaterDate(fichierSelectionne.modifieLe)}</p>
            <button className="bouton-action">Ouvrir</button>
            <button className="bouton-action bouton-supprimer">Supprimer</button>
          </div>
        </div>
      )}
    </div>
  );
}

export default ExplorateurFichiers;
