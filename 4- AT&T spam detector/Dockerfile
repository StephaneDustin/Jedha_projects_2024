# Utilisation de l'image de base Miniconda
FROM continuumio/miniconda3

WORKDIR /home/app

RUN apt-get update -y \
    && apt-get install -y nano unzip

# Pip va chercher les librairies nécessaires, spécifiées dans le fichier 'requirements.txt'. J'espère sans pb
# de compatibilité cette fois si Dockers gère correctement.
COPY requirements.txt /dependencies/requirements.txt
RUN pip install -r /dependencies/requirements.txt

# Copie du code source de l'application dans le conteneur
COPY . /home/app

# Command pour ouvrir ensuite le notebook dans Jupyter
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--allow-root", "--no-browser", "--NotebookApp.token="]

