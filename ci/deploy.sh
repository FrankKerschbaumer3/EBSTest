#!/bin/bash

NAME=testingenv
EB_BUCKET=elasticbeanstalk-us-east-1-${AWS_ACCOUNT_ID}
VERSION=$(git rev-parse docker-v2)
ZIP=$VERSION.zip

aws configure set default.region us-east-1

# Authenticate against our Docker registry
$(aws ecr get-login --no-include-email)

# Build and push the image
docker build -t $NAME:$VERSION .
docker tag $NAME:$VERSION ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/$NAME:$VERSION
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.us-east-1.amazonaws.com/$NAME:$VERSION

cp ci/Dockerrun.aws.json.template Dockerrun.aws.json

# Replace the <AWS_ACCOUNT_ID> with the real ID
sed -i='' "s/<AWS_ACCOUNT_ID>/$AWS_ACCOUNT_ID/" Dockerrun.aws.json
# Replace the <NAME> with the real name
sed -i='' "s/<NAME>/$NAME/" Dockerrun.aws.json
# Replace the <TAG> with the real version number
sed -i='' "s/<TAG>/$VERSION/" Dockerrun.aws.json

# Zip up the Dockerrun file (feel free to zip up an .ebextensions directory with it)
zip -r $ZIP Dockerrun.aws.json

aws s3 cp $ZIP s3://$EB_BUCKET/$ZIP

#Delete files
rm -f $ZIP Dockerrun.aws.json Dockerrun.aws.json=

# Create a new application version with the zipped up Dockerrun file
aws elasticbeanstalk create-application-version --application-name $NAME \
    --version-label $VERSION --source-bundle S3Bucket=$EB_BUCKET,S3Key=$ZIP

# Update the environment to use the new application version
aws elasticbeanstalk update-environment --environment-name $NAME-env \
      --version-label $VERSION

deploystart=$(date +%s)
timeout=120 # Seconds to wait before error. If it's taking awhile - your boxes probably are too small.
threshhold=$((deploystart + timeout))
while true; do
    # Check for timeout
    timenow=$(date +%s)
    if [[ "$timenow" > "$threshhold" ]]; then
        echo "Timeout - $timeout seconds elapsed"
        exit 1
    fi

    # See what's deployed
    current_version=`aws elasticbeanstalk describe-environments --application-name "$NAME" --environment-name "$NAME" --query "Environments[*].VersionLabel" --output text`

    status=`aws elasticbeanstalk describe-environments --application-name "$NAME" --environment-name "$NAME" --query "Environments[*].Status" --output text`

    if [ "$current_version" != "$VERSION" ]; then
        echo "Tag not updated (currently $version). Waiting."
        sleep 10
        continue
    fi
    if [ "$status" != "Ready" ]; then
        echo "System not Ready -it's $status. Waiting."
        sleep 10
        continue
    fi
    break
done