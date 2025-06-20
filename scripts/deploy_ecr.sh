#!/bin/bash

set -e

#editable parameters
REGION="eu-west-1"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REPO_NAME="hotel-reservation-platform"
IMAGE_TAG="latest"
PLATFORM="linux/amd64"

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

docker buildx build \
  --platform "$PLATFORM" \
  -t "${REPO_NAME}:${IMAGE_TAG}" \
  -f ./app/docker/Dockerfile app/ \
  --load

ECR_URI="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}"
docker tag "${REPO_NAME}:${IMAGE_TAG}" "${ECR_URI}"
docker push "${ECR_URI}"

echo "Successfully pushed image to ECR: ${ECR_URI}"
