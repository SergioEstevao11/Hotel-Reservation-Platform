#!/bin/bash

set -euo pipefail

# editable parameters
export AWS_REGION=eu-west-1
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export ECR_REPO_NAME=hotel-reservation-platform
export ECR_URI="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
export BUILD_PATH="$(pwd)/app"


aws ecr get-login-password | \
  docker login --username AWS --password-stdin "${ECR_URI}"

docker build -t "${ECR_REPO_NAME}:latest" "$BUILD_PATH"
docker tag "${ECR_REPO_NAME}:latest" "${ECR_URI}/${ECR_REPO_NAME}:latest"
docker push "${ECR_URI}/${ECR_REPO_NAME}:latest"

echo "Image successfully pushed to: ${ECR_URI}/${ECR_REPO_NAME}:latest"
