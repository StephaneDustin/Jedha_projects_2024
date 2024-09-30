 docker run -it -p "4000:80" \
 -e PORT=80 \
 -e AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID} \
 -e AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY} \
 -e BACKEND_STORE_URI=${DATABASE_URL} \
 -e ARTIFACT_ROOT=s3://st-using-heroku/artifacts/ \
 mlflow-server