 docker run -it -p "4000:80" \
 -e PORT=80 \
 -e AWS_ACCESS_KEY_ID=${ACCESS_KEY_ID} \
 -e AWS_SECRET_ACCESS_KEY=${SECRET_KEY} \
 -e BACKEND_STORE_URI=postgresql://${USER_NAME}:${PASSWORD}@c5flugvup2318r.cluster-czrs8kj4isg7.us-east-1.rds.amazonaws.com:5432/d26n4v44dtm64b \
 -e ARTIFACT_ROOT=s3://st-using-heroku/artifacts/ \
 mlflow-server