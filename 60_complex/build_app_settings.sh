#!/bin/sh

DIR=$(cd $(dirname $0); pwd)
cd ${DIR}

. ./build_param_app_settings.sh

while getopts p:d: OPT
do
    echo $?
    case $OPT in
        # Check if parameters need to be retrieved from specified file or keep default file (build_param.sh)
        p) echo "Retrieving parameters from ${OPTARG}"
            . $OPTARG
            ;;
        # Check if parameters need to be retrieved from specified file or keep default file (build_param.sh). 0) App only, 1) App + RDS
        d) echo "Delete resources. 0) App only, 1) App + RDS: ${OPTARG}"
            DELETE=$OPTARG
            ;;
    esac
done

if [ "${NR_LICENSEKEY}" = "" ] ; then
    echo 'NR_LICENSEKEY are not specified. Check build_param.sh'
    exit 1
fi

if [ "${NR_APP_NAME}" = "" ] ; then
    echo 'NR_APP_NAME are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_CF_VPC_STACK}" = "" ] ; then
    echo 'AWS_CF_VPC_STACK are not specified. Check build_param.sh'
    exit 1
fi

if [ "${CLUSTER_NAME}" = "" ] ; then
    echo 'CLUSTER_NAME are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_CF_RDS_STACK}" = "" ] ; then
    echo 'AWS_CF_RDS_STACK are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_CF_RDS_TEMPLATE}" = "" ] ; then
    echo 'AWS_CF_RDS_TEMPLATE are not specified. Check build_param.sh'
    exit 1
fi

if [ "${DB_NAME}" = "" ] ; then
    echo 'DB_NAME are not specified. Check build_param.sh'
    exit 1
fi

if [ "${DB_USER}" = "" ] ; then
    echo 'DB_USER are not specified. Check build_param.sh'
    exit 1
fi

if [ "${DB_PASS}" = "" ] ; then
    echo 'DB_PASS are not specified. Check build_param.sh'
    exit 1
fi

if [ "${DB_PORT}" = "" ] ; then
    echo 'DB_PORT are not specified. Check build_param.sh'
    exit 1
fi

# Followings are needed to be environment variable to pass yaml
export NR_LICENSEKEY=${NR_LICENSEKEY}
export NR_APP_NAME=${NR_APP_NAME}
export CLUSTER_NAME=${CLUSTER_NAME}
export VR=${VR}
export DB_NAME=${DB_NAME}
export DB_PORT=${DB_PORT}
export DB_USER=${DB_USER}
export DB_PASS=${DB_PASS}

if [ "${DELETE}" != "" ] ; then
    if [ "${DELETE}" = "0" ] || [ "${DELETE}" = "1" ] ; then
        echo "Deleting app_settings..."
        cat resources/app_settings/app_settings.yaml | envsubst | kubectl delete -f -
    fi

    if [ "${DELETE}" = "1" ] ; then
        echo "Deleting existing cloudformation stack. ${AWS_CF_RDS_STACK}"
        aws cloudformation delete-stack --stack-name ${AWS_CF_RDS_STACK}
        aws cloudformation wait stack-delete-complete --stack-name ${AWS_CF_RDS_STACK}
    fi

    exit 0
fi

################ Retrieve VPC Information ######################
OUTPUTS=`aws cloudformation describe-stacks --stack-name ${AWS_CF_VPC_STACK}`
if  [ "$?" != "0" ] ; then
    echo "There is no stack, create stack first: ${AWS_CF_VPC_STACK}"
    exit 0
fi
VPC_ID=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "VPC") | .OutputValue'`
PUB_SUBNETS=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "SubnetsPublic") | .OutputValue'`
PRI_SUBNETS=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "SubnetsPrivate") | .OutputValue'`

OUTPUTS=`aws ec2 describe-vpcs --filters Name=vpc-id,Values=${VPC_ID}`
VPC_CIDR=`echo "${OUTPUTS}" | jq -r '.Vpcs[0] | .CidrBlock'`

echo "VPC: ${VPC_ID}"
echo "VPC CIDR: ${VPC_CIDR}"
echo "PUB_SUBNETS: ${PUB_SUBNETS}"
echo "PRI_SUBNETS: ${PRI_SUBNETS}"

################ Delete Existing Stacks ########################
aws cloudformation describe-stacks --stack-name ${AWS_CF_RDS_STACK} > /dev/null
IS_RDS_STACK=$?
if [ "${IS_RDS_STACK}" = "0" ] &&  [ "${SKIP_IF_STACK_EXIST}" != "true" ] ; then
    echo "Deleting existing cloudformation stack. ${AWS_CF_RDS_STACK}"
    aws cloudformation delete-stack --stack-name ${AWS_CF_RDS_STACK}
    aws cloudformation wait stack-delete-complete --stack-name ${AWS_CF_RDS_STACK}
    IS_RDS_STACK=1
fi

################ Create RDS and Security Group ########################
if [ "${IS_RDS_STACK}" != "0" ] ; then
    echo "Creating cloudformation stack for RDS. ${AWS_CF_RDS_STACK}"
    PRI_SUBNETS_ESCAPED=`echo ${PRI_SUBNETS} | sed -e s/,/\\\\\\\\,/g`

    aws cloudformation create-stack --stack-name ${AWS_CF_RDS_STACK} \
        --template-body file://${AWS_CF_RDS_TEMPLATE} \
        --parameters ParameterKey=VpcId,ParameterValue=${VPC_ID} \
        ParameterKey=VpcCidr,ParameterValue=${VPC_CIDR} \
        ParameterKey=Subnets,ParameterValue=${PRI_SUBNETS_ESCAPED} \
        ParameterKey=DBNameParam,ParameterValue=${DB_NAME} \
        ParameterKey=DBPortParam,ParameterValue=${DB_PORT} \
        ParameterKey=DBMasterUserNameParam,ParameterValue=${DB_USER} \
        ParameterKey=DBPasswordParam,ParameterValue=${DB_PASS} \
        --capabilities CAPABILITY_IAM

    echo "Waiting compleation of cloudformation stack. ${AWS_CF_RDS_STACK}"
    aws cloudformation wait stack-create-complete --stack-name ${AWS_CF_RDS_STACK}

    echo "Cloudformation stack has been created. ${AWS_CF_RDS_STACK}"
else
    echo "Cloudformation stack already exists. ${AWS_CF_RDS_STACK}"
fi

OUTPUTS=`aws cloudformation describe-stacks --stack-name ${AWS_CF_RDS_STACK}`
DB_SECURITYGROUP_ID=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "DBSecurityGroup") | .OutputValue'`
export DB_HOST=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "DBDNSName") | .OutputValue'`

echo "DB_SECURITYGROUP_ID: ${DB_SECURITYGROUP_ID}"
echo "DB_HOST: ${DB_HOST}"

########## Building Images ################
export AWS_REGION=`aws configure get region`
export AWS_ACCOUNT_ID=`aws sts get-caller-identity --query 'Account' --output text`

echo "Logging in AWS..."
$(aws ecr get-login --no-include-email --region ${AWS_REGION})

echo "Build docker images..."
export REPOSITORY_URI_PATH=
DOCKER_COMPOSE_FILE=docker-compose-app_settings.yml
docker-compose -f ${DOCKER_COMPOSE_FILE} build

for container in `cat ${DOCKER_COMPOSE_FILE} | envsubst | yq -r '.services[] | select(has("build")).container_name' `
do
    REPOSITORY_NAME=${container}
    echo "Searching existing repository: ${REPOSITORY_NAME}"
    REPOSITORY_URI=`aws ecr describe-repositories --repository-name ${REPOSITORY_NAME} | jq -r '.repositories[0].repositoryUri'`
    if [ "${REPOSITORY_URI}" = "" ] ; then
        echo "Creating repository ${REPOSITORY_NAME}..."
        REPOSITORY_URI=`aws ecr create-repository --repository-name ${REPOSITORY_NAME} | jq -r '.repository.repositoryUri'`
    fi

    echo "Add tag for the image...: ${REPOSITORY_URI}"
    docker tag ${REPOSITORY_NAME}:${VR} ${REPOSITORY_URI}:${VR}

    echo "Registering container image...: ${REPOSITORY_URI}"
    docker push ${REPOSITORY_URI}:${VR}
done

REPOSITORY_URI_PATH=`echo "${REPOSITORY_URI}" | cut -d "/" -f1`
export REPOSITORY_URI_PATH="${REPOSITORY_URI_PATH}/"

echo "Deploying app_settings"
cat resources/app_settings/app_settings.yaml | envsubst | kubectl apply -f -
