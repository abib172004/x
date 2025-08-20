import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css'; // Fichier de styles global
import App from './App'; // Le composant principal de l'application
import { BrowserRouter } from 'react-router-dom';

// Crée la racine de l'application React.
// C'est le point de montage principal dans le fichier public/index.html.
const racine = ReactDOM.createRoot(document.getElementById('root'));

// Rend l'application.
// React.StrictMode est un outil pour mettre en évidence les problèmes potentiels dans une application.
// BrowserRouter est nécessaire pour gérer le routage côté client.
racine.render(
  <React.StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </React.StrictMode>
);
