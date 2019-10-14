# Overview

This repository is an example of deployment of Cloud Endpoint secured with API Keys for reaching
private Cloud Function, private Cloud Run and IAP protected App Engine

See the [Medium article for more details](https://medium.com/google-cloud/secure-cloud-run-cloud-functions-and-app-engine-with-api-key-73c57bededd1)

# Deployment

The service have 5 elements
- Google Cloud Endpoint service (fully managed/serverless)
- Cloud Run with Endpoint container deployed on it
- Private Cloud Run service with HelloWorld container
- Private Cloud Functions with HelloWorld function
- IAP protected AppEngine with HelloWorld app

## Cloud Run endpoint gateway

It's a publicly accessible Cloud Run with Endpoint container deployed on it.
It has a specific service account for managing its own right independently of the default service account

Change the `<PROJECT_ID>` by your project ID

```bash
gcloud beta iam service-accounts create endpoint-id

gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member=serviceAccount:endpoint-id@<PROJECT_ID>.iam.gserviceaccount.com \
  --role=roles/servicemanagement.configEditor
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member=serviceAccount:endpoint-id@<PROJECT_ID>.iam.gserviceaccount.com \ 
  --role=roles/run.invoker
gcloud projects add-iam-policy-binding <PROJECT_ID> \
  --member=serviceAccount:endpoint-id@<PROJECT_ID>.iam.gserviceaccount.com \
  --role=roles/cloudfunctions.invoker

# Don't work today.
# gcloud projects add-iam-policy-binding gdglyon-cloudrun \
#   --member=serviceAccount:endpoint-id@gdglyon-cloudrun.iam.gserviceaccount.com \
#   --role=roles/iap.httpResourceAccesssor

gcloud beta run deploy endpoint \
    --image="gcr.io/endpoints-release/endpoints-runtime-serverless:1" \
    --allow-unauthenticated --region us-central1 --platform managed \
    --service-account endpoint-idy@<PROJECT_ID>.iam.gserviceaccount.com
```

## Backend services

The backend is a simple Go helloWorld which answer the name in query parameter, if provided, world if not.

The environment variable `ENV` is also added to the response to differentiate the running platform in the tests 

### Function

Deploy the function with an explicit env var.

```bash
# Deploy the alpha function
# Change the env vars by your values
gcloud beta functions deploy apikey-endpoint --trigger-http --region us-central1 \
   --runtime go112 --source function --no-allow-unauthenticated \
   --entry-point HelloWorld --set-env-vars=ENV="Cloud Functions"
```

### AppEngine Standard

Deploy into the default service. 

```
gcloud app deploy
``` 

### Cloud Run

Before deploying, the service, the container have to be built.

```bash
# Run the build
# Change <PROJECT_ID> by your project ID.
gcloud builds submit --tag gcr.io/<PROJECT_ID>/apikey-endpoint

# Deploy on Cloud run 
# Change <PROJECT_ID> by your project ID.
gcloud beta run deploy apikey-endpoint --region us-central1 --platform managed \
    --no-allow-unauthenticated --image gcr.io/<PROJECT_ID>/apikey-endpoint 
```

## Cloud Endpoint

Set up the Cloud Endpoint service wit the `endpoint.yaml` file. Think to update it with the Cloud Run Endpoint gateway,
private Cloud Run URL, private Cloud Functions URL and IAP protected App Engine url

The Cloud Run Endpoint gateway name is the URL of the Cloud Run  `endpoint` service without the `https://`

```
gcloud endpoints services deploy endpoint.yaml

# Update the ENDPOINTS_SERVICE_NAME the Cloud Run Endpoint gateway name
gcloud beta run services update endpoint --platform managed --region us-central1 \
    --set-env-vars="^|^ENDPOINTS_SERVICE_NAME=endpoint-<hash>-uc.a.run.app|ESP_ARGS=--rollout_strategy=managed"  
```

# Tests 

Before testing, activate the service on your project

The Cloud Run Endpoint gateway name is the URL of the Cloud Run  `endpoint` service without the `https://`
```
# Update the service name with  the Cloud Run Endpoint gateway name
gcloud services enable endpoint-<hash>-uc.a.run.app
```
 
And create an API Key through the GUI.

Now you can test
```
# Use the URL of Cloud Run Endpoint gateway
curl https://endpoint-<hash>-uc.a.run.app/hello?key=<API KEY>
curl https://endpoint-<hash>-uc.a.run.app/hello-gcf?key=<API KEY>
curl https://endpoint-<hash>-uc.a.run.app/hello-gae?key=<API KEY>
```

# License

This library is licensed under Apache 2.0. Full license text is available in
[LICENSE](https://github.com/guillaumeblaquiere/serverless-oracle/tree/master/LICENSE).