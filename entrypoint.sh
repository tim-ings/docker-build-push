#!/bin/sh

# Put GCP service account key from base64 to json on a file if specified.
if [ -n "$GCLOUD_AUTH" ]
 then
  echo "$GCLOUD_AUTH" | base64 -d > "$HOME"/gcloud-service-key.json
# Put Docker Hub password to a text file if specified.
elif [ -n "$DOCKER_PASSWORD"$ ]
  then
   echo "$DOCKER_PASSWORD" > "$HOME"/docker-login_password.text
else
  echo "Not auth credentials specified"
fi

# If GCLOUD_AUTH is provided, then we setup registry url with project id
if [ -n "$GCLOUD_AUTH" ]
 then
  DOCKER_REGISTRY_URL="$REGISTRY_URL/$GCLOUD_PROJECT_ID"
else
  DOCKER_REGISTRY_URL="$REGISTRY_URL"
fi

DOCKER_IMAGE_NAME="$1"
DOCKER_IMAGE_TAG="$2"
DOCKER_DIR="$3"
DOCKER_TARGET="$4"

USERNAME=${GITHUB_REPOSITORY%%/*}
REPOSITORY=${GITHUB_REPOSITORY#*/}

REGISTRY=${DOCKER_REGISTRY_URL} ## use default Docker Hub as registry unless specified
NAMESPACE=${DOCKER_NAMESPACE:-$USERNAME} ## use github username as docker namespace unless specified
IMAGE_NAME=${DOCKER_IMAGE_NAME:-$REPOSITORY} ## use github repository name as docker image name unless specified
IMAGE_TAG=${DOCKER_IMAGE_TAG:-$GIT_TAG} ## use git ref value as docker image tag unless specified


# Login Docker with GCP Service Account key or Docker username and password
if [ -n "$GCLOUD_AUTH" ]
 then
  # Guide here https://cloud.google.com/container-registry/docs/advanced-authentication#gcloud_docker
  sh -c "cat "$HOME"/gcloud-service-key.json | docker login -u _json_key --password-stdin https://$REGISTRY"
elif [ -n "$DOCKER_PASSWORD" ]
 then
  sh -c "cat "$HOME"/docker-login_password.text | docker login --username $DOCKER_USERNAME --password-stdin"
else 
  echo "Not docker authorization creteria provided. Skipping login"
fi


# Build Docker Image Locally with provided Image Name
sh -c "docker build $DOCKER_DIR -t $IMAGE_NAME --target $DOCKER_TARGET" ## pass in the build command from user input, otherwise build in default mode

# If Docker name name space is pecified add to registry
if [ -n "$GCLOUD_AUTH" ]
 then
  REGISTRY_IMAGE="$REGISTRY/$IMAGE_NAME"
else 
  REGISTRY_IMAGE="$NAMESPACE/$IMAGE_NAME"
fi

# Tag image with speciefied tag or latest
sh -c "docker tag $IMAGE_NAME $REGISTRY_IMAGE:$DOCKER_IMAGE_TAG"

# Push image to registry
sh -c "docker push $REGISTRY_IMAGE:$IMAGE_TAG"
