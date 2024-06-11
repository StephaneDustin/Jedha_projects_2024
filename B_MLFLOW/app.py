import time
import mlflow
import pandas as pd
from mlflow.models.signature import infer_signature
from sklearn.compose import ColumnTransformer
from sklearn.ensemble import GradientBoostingRegressor
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler

if __name__ == "__main__":
    # Set your variables for your environment
    EXPERIMENT_NAME = "Jedha-fullstack-deployment"

    # Set your tracking uri
    # mlflow.set_tracking_uri("localhost:5000")

    # Set experiment's info
    mlflow.set_experiment(EXPERIMENT_NAME)

    # Get our experiment info
    experiment = mlflow.get_experiment_by_name(EXPERIMENT_NAME)

    print("Training model...")

    # Time execution
    start_time = time.time()

    # Call mlflow autolog
    mlflow.sklearn.autolog()

    df = pd.read_csv('https://jedha-deployment.s3.amazonaws.com/get_around_pricing_project.csv')
    df = df.iloc[:, 1:]

    # X, y split 
    X = df.iloc[:, :-1]
    y = df.iloc[:, -1]

    # Train / test split 
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    numeric_features = []
    categorical_features = []
    for i, t in X.dtypes.items():
        if ('float' in str(t)) or ('int' in str(t)):
            numeric_features.append(i)
        else:
            categorical_features.append(i)

    numeric_transformer = StandardScaler()
    categorical_transformer = OneHotEncoder(drop='first', handle_unknown='ignore')

    preprocessor = ColumnTransformer(
        transformers=[
            ('num', numeric_transformer, numeric_features),
            ('cat', categorical_transformer, categorical_features)
        ])

    model = Pipeline(
        steps=[("Preprocessing", preprocessor), ("Regressor", GradientBoostingRegressor())]
    )

    with mlflow.start_run(experiment_id=experiment.experiment_id):
        model.fit(X_train, y_train)

        # Store metrics 
        accuracy = model.score(X_test, y_test)

        # Print results 
        print("GradientBoost model")
        print(f"Accuracy: {accuracy}")

        # Log Metric 
        mlflow.log_metric("Accuracy", accuracy)

    print("...Done!")
    print(f"---Total training time: {time.time()-start_time}")
