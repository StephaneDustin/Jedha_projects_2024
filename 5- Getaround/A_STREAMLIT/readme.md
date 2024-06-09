# README (yes! Readme until the end to have tip's that can make your 'docker build' command easier !)

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
    docker build -t streamlit-app . # if your Dockerfile has another name than 'Dockerfile', for example 'Dockerfile.streamlit', just call it like this in your line command: docker build -f Dockerfile.streamlit before others arguments
    ```

3. Run the Docker Container

    Run the Docker container and map the container's port 8501 to your local machine's port 8501:

    ```sh
    docker run -p 8501:8501 streamlit-app
    ```

4. Access the Application

    Open your web browser and go to:

    ```
    http://localhost:8501
    ```

    You should see your Streamlit application running.

## Additional Informations

### Customizing the Port

If you want to run the application on a different port than the 8501 port which is by default the configured port in Streamlit, modify the CMD instruction in the Dockerfile and the docker run command accordingly. For example, to run on port 8888:

Modify Dockerfile:

```dockerfile
CMD streamlit run --server.port 8888 app.py
```

Run the container:

```sh
docker run -p 8888:8888 streamlit-app
```

### Stopping the Container

To stop the running Docker container, use the docker ps command to find the container ID and then docker stop to stop it:

```sh
docker ps
docker stop <container_id> # the number of the container appears in the beginning on the returned command line where other informations are availables: name of this container, etc...
```
### To delete the previous container before running another :

```sh
docker rm <container_id>
```

### To build another image without cache of previous ones (usefull +++):

```sh
docker build --no-cache ### to be used on first argument on your line command
```

### Wish you smart dockerizations !
