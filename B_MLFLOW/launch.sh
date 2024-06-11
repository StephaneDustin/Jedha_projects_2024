 docker run -it -p "4000:80" \
 -e PORT=80 \
 -e AWS_ACCESS_KEY_ID=AKIA5HOXYRWA75Y2EPM4 \
 -e AWS_SECRET_ACCESS_KEY=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 \
 -e BACKEND_STORE_URI=postgresql://ue6kudu0dqj9ib:p99f6b08de9dff7fed9ef2539cd440abb8a2e1df8a43a5b0b2be17aa8d1f3c74b@c5flugvup2318r.cluster-czrs8kj4isg7.us-east-1.rds.amazonaws.com:5432/d26n4v44dtm64b \
 -e ARTIFACT_ROOT=s3://st-using-heroku/artifacts/ \
 mlflow-server