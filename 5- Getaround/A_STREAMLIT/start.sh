#!/bin/bash

# Affichez la valeur de $PORT pour le débogage
echo "PORT is set to: $PORT"

# Démarrez Streamlit avec le port spécifié
streamlit run app.py --server.port=$PORT


# Lire la variable d'environnement PORT et utiliser 8501 comme défaut si non définie
#PORT=${PORT:-8501}

# Démarrer Streamlit avec le port spécifié
#streamlit run --server.port=$PORT app.py
