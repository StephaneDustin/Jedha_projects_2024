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
    docker build -t api-app .
    ```

3. Run the Docker Container

    Run the Docker container and map the container's port 8080 to your local machine's port 8080:

    ```sh
    docker run -it -p 8080:8080 api-app python app.py
    ```

4. Access the Application

    Open your web browser and go to:

    ```
    http://localhost:8080
    ```

5. Access the Application Documentation

    Open your web browser and go to:

    ```
    http://localhost:8080/docs
    ```

6. Test the Predict Endpoint

    Use the following command to test the predict endpoint:

    ```sh
    curl -X POST http://localhost:8080/predict \
     -H "Content-Type: application/json" \
     -d '{
           "model_key": "Fiat",
           "mileage": 150000,
           "engine_power": 90,
           "fuel": "diesel",
           "paint_color": "white",
           "car_type": "sedan",
           "private_parking_available": true,
           "has_gps": true,
           "has_air_conditioning": true,
           "automatic_car": true,
           "has_getaround_connect": true,
           "has_speed_regulator": true,
           "winter_tires": true
         }'
    ```

