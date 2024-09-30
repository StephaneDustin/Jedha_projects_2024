FROM continuumio/miniconda3

WORKDIR /home/app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    nano \
    unzip \
    curl

# Install Python 3.10
RUN apt-get install -y python3.10

# Install Deta CLI
RUN curl -fsSL https://get.deta.dev/cli.sh | sh

# Copy and install Python dependencies
COPY requirements.txt /dependencies/requirements.txt
RUN pip install -r /dependencies/requirements.txt
COPY heroku.yml /home/app/heroku.yml

# Copy the application code
COPY . /home/app

ENV AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}
# Set the default command to run the application LIGNE INITIALE AVANT MODIFICATION PAR LA SUIVANTE
#CMD gunicorn app:app --bind 0.0.0.0:5000 --worker-class uvicorn.workers.UvicornWorker

# suggestion ChatGPT pour ouvrir sur port spécifié par Heroku:
CMD ["sh", "-c", "gunicorn app:app --bind 0.0.0.0:$PORT --worker-class uvicorn.workers.UvicornWorker"]
