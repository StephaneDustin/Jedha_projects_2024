# README

## Getting Started

1. Clone the Repository

    First, clone the repository to your local machine:

    ```sh
    git clone https://github.com/your-username/your-repository.git
    cd your-repository
    ```

2. Build the Docker Image

    Build the Docker image using the following command:

    ```sh
    docker build -t mlflow-app .
    ```

3. Run the Docker Container

    Run the Docker container and map the container's port 8080 to your local machine's port 8080:

    ```sh
    docker run -p 8501:8501 streamlit-app
    ```

4. Access the Application

    Open your web browser and go to:

    ```
    http://localhost:8501
    ```

    You should see your Streamlit application running.

## Additional Information

### Customizing the Port

If you want to run the application on a different port, modify the CMD instruction in the Dockerfile and the docker run command accordingly. For example, to run on port 8501:

Modify Dockerfile:

```dockerfile
CMD streamlit run --server.port 8501 app.py
```

Launch ML training:

```sh
docker run -it \
-e AWS_ACCESS_KEY_ID="AKIAUP7OJ727UIDJNFHV" \
-e AWS_SECRET_ACCESS_KEY="woXDKD1mOnwXse+zWvo1XYspzwfYEsBudx+kunRDi" \
-e BACKEND_STORE_URI="postgresql://udps6utt6o09cu:p976db0f4d297d5fcd854608c4751a6f982ebacb95ba608d56013d0f363820a25@ceu9lmqblp8t3q.cluster-czrs8kj4isg7.us-east-1.rds.amazonaws.com:5432/d20cc2jf8i866f" \
-e ARTIFACT_ROOT="s3://jedha-fullstack-deployment/artefacts/" \
mlflow-app python app.py
```
