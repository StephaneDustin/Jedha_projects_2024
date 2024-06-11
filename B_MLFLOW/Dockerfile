FROM continuumio/miniconda3

WORKDIR /home/app

# Install necessary packages
RUN apt-get update && \
    apt-get install -y nano unzip curl

# Install Deta CLI
RUN curl -fsSL https://get.deta.dev/cli.sh | sh

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install

# Copy and install Python dependencies
COPY requirements.txt /dependencies/requirements.txt
RUN pip install -r /dependencies/requirements.txt
COPY app.py /home/app/app.py

# Set environment variables
ENV AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
ENV AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
ENV BACKEND_STORE_URI=$BACKEND_STORE_URI
ENV ARTIFACT_ROOT=$ARTIFACT_ROOT

# Start MLflow server
CMD mlflow server -p $PORT \
    --host 0.0.0.0 \
    --backend-store-uri $BACKEND_STORE_URI \
    --default-artifact-root $ARTIFACT_ROOT
