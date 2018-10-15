#!/usr/bin/env bash

# Builds, tags, and uploads Docker Images to ECR. Must be run local to the Dockerfile being built.
# Uses Build-Time Arguments to bake in environment configuration to the Image before deployment
#
# If the --service-name and --cluster-name fields are passed in then this script will force a
# re-deployment of the service. This is achieved by using the `latest` tag which is what the Task
# Definition is currently set to.
#
# Author: Matthew Edge - Levvel, LLC

printUsage() {
    echo "$0"
    echo " "
    echo "options:"
    echo "-h, --help     Show brief help"
    echo "--account-id   AWS Account ID of the running user"
    echo "--repo         ECR Repository name to upload Docker image to"
    echo "--tag          Tag to assign to Docker image"
    echo "--service-name Optional: Name of the ECS Service to redeploy. Must be used with --cluster-name"
    echo "--cluster-name Optional: Name of the ECS Cluster. Must be used with --service-name"
    echo "--region       AWS Region resources reside in"
    echo "--env          Environment being deployed to (linked to config being loaded in app)"
    echo "--version      App Version being deployed (for debug)"
    echo "--branch       App Branch being deployed"
    echo "--profile      Optional: profile to log in to ECR with"
}

# errIfMissing "$VAR", "ERROR_MESSAGE"
errIfMissing() {
    if [ -z "$1" ]; then
        echo "$2"
        exit 1
    fi
}

# Parse flags
while test $# -gt 0; do
    case "$1" in
        -h|--help)
            printUsage
            exit 0
        ;;
        --account-id)
            shift
            export AWS_ACCOUNT_ID=`echo $1`
            shift
        ;;
        --repo)
            shift
            export REPO_NAME=`echo $1`
            shift
        ;;
        --service-name)
            shift
            export SERVICE_NAME=`echo $1`
            shift
        ;;
        --cluster-name)
            shift
            export CLUSTER_NAME=`echo $1`
            shift
        ;;
        --tag)
            shift
            export IMAGE_TAG=`echo $1`
            shift
        ;;
        --region)
            shift
            export AWS_REGION=`echo $1`
            shift
        ;;
        --env)
            shift
            export APP_ENV=`echo $1`
            shift
        ;;
        --version)
            shift
            export APP_VERSION=`echo $1`
            shift
        ;;
        --branch)
            shift
            export APP_BRANCH=`echo $1`
            shift
        ;;
        --profile)
            shift
            export PROFILE=`echo $1`
            shift
        ;;
        *)
            echo "Invalid option $1"
            printUsage
            exit 1
    esac
done

# Validate required params
errIfMissing "${AWS_ACCOUNT_ID}" "AWS Account ID (--account-id) is null/empty"
errIfMissing "${AWS_REGION}" "AWS Region (--region) is null/empty"
errIfMissing "${REPO_NAME}" "ECR Repository (--repo) is null/empty"
errIfMissing "${IMAGE_TAG}" "Image Tag (--tag) is null/empty"

# Actual work being done
echo "ECR login"
if [ ! -z "${PROFILE}" ]; then
    $(aws ecr get-login --no-include-email --region ${AWS_REGION} --profile ${PROFILE})
else
    $(aws ecr get-login --no-include-email --region ${AWS_REGION})
fi

# Note: Requires IAM Policy ecr:UploadImage
echo "Building image ${IMAGE_TAG} for env ${APP_ENV}"
docker build -t ${REPO_NAME}:${IMAGE_TAG} .

echo "Creating tag ${IMAGE_TAG}"
docker tag ${REPO_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}
docker tag ${REPO_NAME}:${IMAGE_TAG} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:latest

echo "Publishing to ECR"
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:${IMAGE_TAG}
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}:latest