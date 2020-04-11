#!/bin/sh

DIR=$(cd $(dirname $0); pwd)
cd ${DIR}

. ./build_param_app_settings.sh

while getopts p:d: OPT
do
    case $OPT in
        # Check if parameters need to be retrieved from specified file or keep default file (build_param.sh)
        p) echo "Retrieving parameters from ${OPTARG}"
           . $OPTARG
           ;;
        # Check if parameters need to be retrieved from specified file or keep default file (build_param.sh)
        d) echo "Delete something: 0) app, 1) app, kube cluster 2) app, kube cluster, rds  3) all"
           DELETE_APP=$OPTARG
           ;;
    esac
done

if [ "${NR_APP_NAME}" = "" ] ; then
    echo 'NR_APP_NAME are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_CF_VPC_STACK}" = "" ] ; then
    echo 'AWS_CF_VPC_STACK are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_CF_VPC_TEMPLATE}" = "" ] ; then
    echo 'AWS_CF_VPC_TEMPLATE are not specified. Check build_param.sh'
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

if [ "${DATA_PLANE}" = "" ] ; then
    echo 'DATA_PLANE are not specified. Check build_param.sh'
    exit 1
fi

if [ "${NODE_TYPE}" = "" ] ; then
    echo 'NODE_TYPE are not specified. Check build_param.sh'
    exit 1
fi

export NR_APP_NAME=${NR_APP_NAME}

echo ${DELETE_APP}

if [ "${DELETE_APP}" != "" ] ; then

    echo "Deleting ConfigMap..."
    cat resources/app_settings/config.yaml | envsubst | kubectl delete -f -
    echo "Deleting Pod..."
    cat resources/app_settings/deployment.yaml | envsubst | kubectl delete -f -
    echo "Deleting Job.."
    cat resources/app_settings/job.yaml | envsubst | kubectl delete -f -
    echo "Deleting Service..."
    cat resources/app_settings/service.yaml | envsubst | kubectl delte -f -

    #TODO Delete rds, cluster, vcp

    exit 0
fi

################ Delete Existing Stacks ########################
aws cloudformation describe-stacks --stack-name ${AWS_CF_VPC_STACK} > /dev/null
IS_VPC_STACK=$?

aws cloudformation describe-stacks --stack-name ${AWS_CF_RDS_STACK} > /dev/null
IS_RDS_STACK=$?

if [ "${AWS_CF_RDS_STACK}" = "0" ] &&  [ "${SKIP_IF_STACK_EXIST}" != "true" ] ; then
    echo "Deleting existing cloudformation stack. ${AWS_CF_RDS_STACK}"
    aws cloudformation delete-stack --stack-name ${AWS_CF_RDS_STACK}
    aws cloudformation wait stack-delete-complete --stack-name ${AWS_CF_RDS_STACK}
    IS_RDS_STACK=1
fi


if [ "${IS_VPC_STACK}" = "0" ] &&  [ "${SKIP_IF_STACK_EXIST}" != "true" ] ; then
    echo "Deleting existing cloudformation stack. ${AWS_CF_VPC_STACK}"
    aws cloudformation delete-stack --stack-name ${AWS_CF_VPC_STACK}
    aws cloudformation wait stack-delete-complete --stack-name ${AWS_CF_VPC_STACK}
    IS_VPC_STACK=1
fi

################ Create VPC ########################
if [ "${IS_VPC_STACK}" != "0" ] ; then
    echo "Creating cloudformation stack for VPC. ${AWS_CF_VPC_STACK}"
    aws cloudformation create-stack --stack-name ${AWS_CF_VPC_STACK} \
        --template-body file://${AWS_CF_VPC_TEMPLATE} \
        --capabilities CAPABILITY_IAM

    echo "Waiting compleation of cloudformation stack. ${AWS_CF_VPC_STACK}"
    aws cloudformation wait stack-create-complete --stack-name ${AWS_CF_VPC_STACK}

    echo "Cloudformation stack has been created. ${AWS_CF_VPC_STACK}"
else
    echo "Cloudformation stack already exists. ${AWS_CF_VPC_STACK}"
fi

OUTPUTS=`aws cloudformation describe-stacks --stack-name ${AWS_CF_VPC_STACK}`
VPC_ID=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "VPC") | .OutputValue'`
PUB_SUBNETS=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "SubnetsPublic") | .OutputValue'`
PRI_SUBNETS=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "SubnetsPrivate") | .OutputValue'`

OUTPUTS=`aws ec2 describe-vpcs --filters Name=vpc-id,Values=${VPC_ID}`
VPC_CIDR=`echo "${OUTPUTS}" | jq -r '.Vpcs[0] | .CidrBlock'`

echo "VPC: ${VPC_ID}"
echo "VPC CIDR: ${VPC_CIDR}"
echo "PUB_SUBNETS: ${PUB_SUBNETS}"
echo "PRI_SUBNETS: ${PRI_SUBNETS}"

export VPC_ID=${VPC_ID}
export PUB_SUBNETS=${PUB_SUBNETS}
export PRI_SUBNETS=${PRI_SUBNETS}
export SECURITYGROUPID=${SECURITYGROUPID}

################ Create RDS and Security Group ########################
export DB_NAME=${DB_NAME}
export DB_PORT=${DB_PORT}
export DB_USER=${DB_USER}
export DB_PASS=${DB_PASS}

if [ "${IS_RDS_STACK}" != "0" ] ; then
    echo "Creating cloudformation stack for VPC. ${AWS_CF_RDS_STACK}"
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
DB_HOST=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "DBDNSName") | .OutputValue'`

echo "DB_SECURITYGROUP_ID: ${DB_SECURITYGROUP_ID}"
echo "DB_HOST: ${DB_HOST}"

export DB_SECURITYGROUP_ID=${DB_SECURITYGROUP_ID}
export DB_HOST=${DB_HOST}

################ Create EKS Cluster ########################
CLUSTER_NAME=${NR_APP_NAME}
eksctl get cluster ${CLUSTER_NAME} > /dev/null
CLUSTER_EXIST=$?

if [ "${CLUSTER_EXIST}" = "0" ] && [ "${SKIP_IF_CLUSTER_EXIST}" != "true" ] ; then
    eksctl delete cluster --name ${CLUSTER_NAME} --wait
    CLUSTER_EXIST=1
fi

if [ "${CLUSTER_EXIST}" != "0" ] ; then
    if [ "${DATA_PLANE}" = "ec2" ] ; then
        eksctl create cluster \
            --name ${CLUSTER_NAME} \
            --version 1.15 \
            --node-type ${NODE_TYPE} \
            --vpc-private-subnets ${PRI_SUBNETS} \
            --vpc-public-subnets ${PUB_SUBNETS} \
            --managed
    else
        eksctl create cluster \
            --name ${CLUSTER_NAME} \
            --version 1.15 \
            --vpc-private-subnets ${PRI_SUBNETS} \
            --vpc-public-subnets ${PUB_SUBNETS} \
            --fargate
    fi
fi
OUTPUTS=`aws eks describe-cluster --name ${CLUSTER_NAME}`
echo $OUTPTUS
#VPC_ID=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "VpcId") | .OutputValue'`
#PUB_SUBNET_A_ID=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "PubSubnetAId") | .OutputValue'`
#PUB_SUBNET_C_ID=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "PubSubnetCId") | .OutputValue'`
#PRI_SUBNET_A_ID=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "PriSubnetAId") | .OutputValue'`
#PRI_SUBNET_C_ID=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "PriSubnetCId") | .OutputValue'`

#exit 0

########## Building Images ################


AWS_REGION=`aws configure get region`
AWS_ACCOUNT_ID=`aws sts get-caller-identity --query 'Account' --output text`

export AWS_REGION=${AWS_REGION}
export AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}

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
    docker tag ${REPOSITORY_NAME}:latest ${REPOSITORY_URI}:latest

    echo "Registering container image...: ${REPOSITORY_URI}"
    docker push ${REPOSITORY_URI}:latest
done

REPOSITORY_URI_PATH=`echo "${REPOSITORY_URI}" | cut -d "/" -f1`
REPOSITORY_URI_PATH="${REPOSITORY_URI_PATH}/"
export REPOSITORY_URI_PATH=${REPOSITORY_URI_PATH}

echo "Applying ConfigMap..."
cat resources/app_settings/config.yaml | envsubst | kubectl apply -f -
echo "Applying Pod..."
cat resources/app_settings/deployment.yaml | envsubst | kubectl apply -f -
echo "Applying Job.."
cat resources/app_settings/job.yaml | envsubst | kubectl apply -f -
echo "Applying Service..."
cat resources/app_settings/service.yaml | envsubst | kubectl apply -f -
