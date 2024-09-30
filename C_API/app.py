import uvicorn
from fastapi import FastAPI
import pandas as pd
from pydantic import BaseModel
from typing import Union
import joblib
import mlflow
from mlflow.tracking import MlflowClient


# Move import statements to the top
description = """Welcome to the Getaround API ! Let estimate your car daily rental price. \n
The API has 3 groups of endpoints:

### Introduction Endpoints \n
- **/**: Return a simple welcoming message

### Exploration Endpoint\n
- **/Search_by_brand** : Allows you to request the data for a desired brand car \n
- **/Search_by_max_mileage** : Allows you to request the data for a desired max mileage \n
- **/Get_unique_values** : Allows you to get all the unique values from the desired column (listed in /predict endpoint)

### Machine Learning Prediction Endpoint
- **/predict**: Gives you an estimated rental price per day for a car.\n

Don't hesitate to try it out \n
More informations on this project available on my Github account below """

tags_metadata = [
    {
        "name": "Introduction Endpoint",
        "description": "Simple endpoints to try out!",
    },
    {
        "name": "Machine Learning Prediction Endpoint",
        "description": "Prediction price."
    },
    {
        "name": "Exploration Endpoint",
        "description": "Allows you to query the data."
    }
]

app = FastAPI(
    title="GetAroundAPI",
    description=description,
    version="0.1",
    contact={
        "name": "Github account",
        "url": "https://github.com/StephaneDustin",
    },
    openapi_tags=tags_metadata
)


class CarFeatures(BaseModel):
    model_key: str = 'Fiat'
    mileage: Union[int, float] = 150000
    engine_power: Union[int, float] = 90
    fuel: str = "diesel"
    paint_color: str = "white"
    car_type: str = "sedan"
    private_parking_available: bool
    has_gps: bool
    has_air_conditioning: bool
    automatic_car: bool
    has_getaround_connect: bool
    has_speed_regulator: bool
    winter_tires: bool

    class Config:
        protected_namespaces = ()


@app.get("/", tags=["Introduction Endpoint"], responses={200: {"description": "Welcome message"}})
async def root() -> str:
    """
    Returns a simple welcoming message.
    """
    message = """👋🏻 Welcome to the Getaround API. 🗒️ The documentation of this API is available at the /docs section"""
    return message


@app.get("/Search_by_brand", tags=["Exploration Endpoint"], responses={200: {"description": "Data for the desired brand"}})
async def search_by_brand(brand: str = "Ford") -> dict:
    """
    Returns the data for the desired brand car.
    """
    brand_list = ['Citroën', 'Peugeot', 'PGO', 'Renault', 'Audi', 'BMW', 'Ford',
                  'Mercedes', 'Opel', 'Porsche', 'Volkswagen', 'KIA Motors',
                  'Alfa Romeo', 'Ferrari', 'Fiat', 'Lamborghini', 'Maserati',
                  'Lexus', 'Honda', 'Mazda', 'Mini', 'Mitsubishi', 'Nissan', 'SEAT',
                  'Subaru', 'Suzuki', 'Toyota', 'Yamaha']
    try:
        if brand not in brand_list:
            raise ValueError("The value you entered is not part of the brand_list. Please check and try again.")
        df = pd.read_csv("https://jedha-deployment.s3.amazonaws.com/get_around_pricing_project.csv")
        model = df[df["model_key"] == brand]

        return model.to_dict()

    except Exception as e:
        return {"error": str(e)}


@app.get("/Search_by_max_mileage", tags=["Exploration Endpoint"], responses={200: {"description": "Data for the desired max mileage"}})
async def search_max_mileage(max_mileage: int = 50000) -> dict:
    """
    Returns the data for the desired max mileage.
    """
    try:
        if max_mileage < 0:
            raise ValueError("You must enter a positive number. Please check and try again.")
        df = pd.read_csv("https://jedha-deployment.s3.amazonaws.com/get_around_pricing_project.csv")
        maximum_mileage = df[df["mileage"] <= max_mileage]

        return maximum_mileage.to_dict()

    except Exception as e:
        return {"error": str(e)}


@app.get("/Get_unique_values", tags=["Exploration Endpoint"], responses={200: {"description": "Unique values for the desired column"}})
async def get_unique_values(col: str) -> list:
    """
    Returns all the available values for a desired column.
    """
    try:
        df = pd.read_csv("https://jedha-deployment.s3.amazonaws.com/get_around_pricing_project.csv")
        list_of_unique_values = df[col].unique()
        return list(list_of_unique_values)

    except Exception as e:
        return {"error": str(e)}


def get_last_experiment_model ():
    mlflow.set_tracking_uri("https://mlflow-with-heroku-89756a40d909.herokuapp.com")


    client = MlflowClient()

    # Récupérer l'ID de l'expérience (par exemple si tu sais laquelle utiliser)
    experiment_id = "34"  # Remplace par l'ID de ton expérience ou utilise client.list_experiments()

    # Récupérer la dernière exécution (run) de l'expérience
    runs = client.search_runs(experiment_id, order_by=["start_time DESC"], max_results=1)

    if runs:
        latest_run = runs[0]
        run_id = latest_run.info.run_id

        # Récupérer l'URI du modèle associé au dernier run
        #model_uri = f"https://st-using-heroku.s3.eu-west-3.amazonaws.com/artifacts/{experiment_id}/{run_id}/artifacts/model/model.pkl"
        model_uri = f"mlruns/{experiment_id}/{run_id}/artifacts/model"
    
    
        local_model_path = mlflow.artifacts.download_artifacts(run_id=run_id, dst_path="models")
        
        return local_model_path
    else:
        print("Aucun modèle trouvé dans cette expérience.")





@app.post("/predict", tags=["Machine Learning Prediction Endpoint"], responses={200: {"description": "Estimated rental price per day"}})
async def predict(car_features: CarFeatures) -> dict:
    model_path=get_last_experiment_model()

    """
    Returns the estimated rental price per day for a car.
    """
    df = pd.DataFrame(dict(car_features), index=[0])
    try:
        model = joblib.load(f"{model_path}/model/model.pkl")
        # preprocessor = joblib.load('model/preprocessor.pkl')
    except Exception as e:
        return {"error": str(e)}

    # try:
    #     X = preprocessor.transform(df)
    # except Exception as e:
    #     return {"error": str(e)}

    try:
        prediction = model.predict(df)
        return {"result": f"The estimated rental price per day for this vehicle is {round(prediction[0], 2)} $"}
    except Exception as e:
        return {"error": str(e)}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8080)
