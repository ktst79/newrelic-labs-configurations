#!/bin/sh

DIR=$(cd $(dirname $0); pwd)
cd ${DIR}

UNAME=`uname`
if type "gsed" > /dev/null 2>&1; then
    SED=gsed
elif [ "${UNAME}" = "Darwin" ] ; then
    echo "Need GNU sed for Mac"
    exit 1
else
    echo "If you use Mac, please install gnu-sed first"
    SED=sed
fi

. ./build_param.sh

while getopts p:o OPT
do
    case $OPT in
        # Check if parameters need to be retrieved from specified file or keep default file (build_param.sh)
        p) echo "Retrieving parameters from ${OPTARG}"
           . $OPTARG
           ;;
        # Check if download application and overwrite
        o) echo "Download brand-new application and replace old one with new one"
           OVERWRITEAPP=true
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

if [ "${APP_URL}" = "" ] ; then
    echo 'APP_URL are not specified. Check build_param.sh'
    exit 1
fi

if [ "${APP_NAME}" = "" ] ; then
    echo 'APP_NAME are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_KEY_NAME}" = "" ] ; then
    echo 'AWS_KEY_NAME are not specified. Check build_param.sh'
    exit 1
fi

if [ ! -e ${APP_DIR} ]; then
    echo "There is no folder '${APP_DIR}', so download application forcibly"
    OVERWRITEAPP=true
fi

if [ "${ENV}" = "" ] ; then
    echo 'ENV are not specified. Check build_param.sh'
    exit 1
fi

if [ "${CLUSTER_INSTANCE_TYPE}" = "" ] ; then
    echo 'CLUSTER_INSTANCE_TYPE are not specified. Check build_param.sh'
    exit 1
fi

if [ "${CLUSTER_INSTANCE_NUM}" = "" ] ; then
    echo 'CLUSTER_INSTANCE_NUM are not specified. Check build_param.sh'
    exit 1
fi

APP_DIR=app
if [ "${OVERWRITEAPP}" = "true" ] ; then
    echo "Downloading application"
    rm -rf ${APP_DIR}
    curl -L -o ./app.zip ${APP_URL}
    unzip ./app.zip -d .
    mv ${APP_NAME} ${APP_DIR}
    rm ./app.zip

    echo "Embeddig Browser Agent Header"
    AGT_HEADER='  <div th:remove="tag" th:utext="${T(com.newrelic.api.agent.NewRelic).getBrowserTimingHeader()}"></div>'
    ${SED} -i "/<body>/a ${AGT_HEADER}" ${APP_DIR}/src/main/resources/templates/fragments/layout.html

    echo "Embeddig Browser Agent Footer"
    AGT_FOOTER='  <div th:utext="${T(com.newrelic.api.agent.NewRelic).getBrowserTimingFooter()}"></div>'
    ${SED} -i "/<\/body>/i ${AGT_FOOTER}" ${APP_DIR}/src/main/resources/templates/fragments/layout.html

    echo "Adding dependency to pom.xml for logback w/ New Relic"
    POM_FRAGMENT=./resources/newrelic_log/pom_fragment.xml
    ${SED} -n -i -e "/^\s\s<\/dependencies>/r ${POM_FRAGMENT}" -e 1x -e '2,${x;p}' -e '${x;p}' ${APP_DIR}/pom.xml
fi

cp -f resources/newrelic_log/logback.xml app/src/main/resources
cp -f resources/newrelic_log/logback-test.xml app/src/test/resources

echo "Building application"
cd ${APP_DIR}
# To avoid including logback-test.xml under src/test/resources, do test and package seperately
./mvnw test
./mvnw clean
./mvnw package -Dmaven.test.skip=true
cd ${DIR}

cp app/target/*.jar resources/webap/

${SED} s/\${NR_LICENSEKEY}/${NR_LICENSEKEY}/ resources/fluentd/fluent.conf > resources/fluentd/fluent.conf.local

export NR_LICENSEKEY=${NR_LICENSEKEY}
export NR_APP_NAME=${NR_APP_NAME}

export MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
export MYSQL_DATABASE=${MYSQL_DATABASE}
export MYSQL_USER=${MYSQL_USER}
export MYSQL_PASSWORD=${MYSQL_PASSWORD}

if [ "${ENV}" = "ecs_ec2" ] ; then
    echo "Deploying on AWS ECS..."
    CLUSTER_NAME=${NR_APP_NAME}-cluster
    CLUSTER_LAUNCH_TYPE='EC2'

    # Get AWS Region and Account ID
    AWS_REGION=`aws configure get region`
    AWS_ACCOUNT_ID=`aws sts get-caller-identity --query 'Account' --output text`

    export AWS_REGION=${AWS_REGION}
    export AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}

    ecs-cli ps -c ${CLUSTER_NAME}
    if [ $? = 1 ] ; then
        # Create cluster if not exists
        echo "Creating ECS Cluster...: ${CLUSTER_NAME}"
        ecs-cli configure -c ${CLUSTER_NAME} -r ${AWS_REGION}
    else
        echo "ECS Cluster already exists: ${CLUSTER_NAME}"
    fi

    if [ "${FORCE_TO_DELETE_STACK}" = "enable" ] ; then
        echo "Stopping existing cluster instance. ${CLUSTER_NAME}"
        ecs-cli down --cluster ${CLUSTER_NAME} -f
    fi

    echo "Launching ECS cluster instance ...: ${CLUSTER_NAME}"
    LAUNCH_INSTANCE_CMD="ecs-cli up --keypair ${AWS_KEY_NAME} --capability-iam --size ${CLUSTER_INSTANCE_NUM} --instance-type ${CLUSTER_INSTANCE_TYPE} --launch-type ${CLUSTER_LAUNCH_TYPE} --cluster ${CLUSTER_NAME}"
    if [ "${CLUSTER_LAUNCH_USERDATA}" != "" ] ; then
        LAUNCH_INSTANCE_CMD="${LAUNCH_INSTANCE_CMD} --extra-user-data ${CLUSTER_LAUNCH_USERDATA}"
    fi

    ${LAUNCH_INSTANCE_CMD}

    if [ $? = 1 ] ; then
        # If cluster instance already exists
        echo "Cluster instance already running: ${CLUSTER_NAME}"
    fi

    # Waiting for EC2 instance is ready
    while [ "$(aws ecs describe-clusters --cluster=${CLUSTER_NAME} | sed -n 's/^.*\"registeredContainerInstancesCount\"\: \(.*\),.*$/\1/p')" -lt 1 ]; do
        sleep 10
        echo "rechecking cluster status..."
    done

    echo "Logging in AWS..."
    $(aws ecr get-login --no-include-email --region ${AWS_REGION})

    echo "Build docker images..."
    export REPOSITORY_URI_PATH=
    docker-compose -f docker-compose-ecs.yml build

    for container in `yq -r '.services[] | select(has("build")).container_name' docker-compose-ecs.yml`
    do
        REPOSITORY_NAME=${NR_APP_NAME}-${container}
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

    echo "Launching ECS..."
    ecs-cli compose -f docker-compose-ecs.yml down
    ecs-cli compose -f docker-compose-ecs.yml up
elif [ "${ENV}" = "ecs_fargate" ] ; then
    echo "Deploying on AWS ECS..."
    CLUSTER_NAME=${NR_APP_NAME}-cluster
    CLUSTER_LAUNCH_TYPE='FARGATE'

    # Get AWS Region and Account ID
    AWS_REGION=`aws configure get region`
    AWS_ACCOUNT_ID=`aws sts get-caller-identity --query 'Account' --output text`

    export AWS_REGION=${AWS_REGION}
    export AWS_ACCOUNT_ID=${AWS_ACCOUNT_ID}

    ecs-cli ps -c ${CLUSTER_NAME}
    if [ $? = 1 ] ; then
        # Create cluster if not exists
        echo "Creating ECS Cluster...: ${CLUSTER_NAME}"
        ecs-cli configure -c ${CLUSTER_NAME} -r ${AWS_REGION}
    else
        echo "ECS Cluster already exists: ${CLUSTER_NAME}"
    fi

    if [ "${FORCE_TO_DELETE_STACK}" = "enable" ] ; then
        echo "Stopping existing cluster instance. ${CLUSTER_NAME}"
        ecs-cli down --cluster ${CLUSTER_NAME} -f
    fi

    echo "Launching ECS cluster instance ...: ${CLUSTER_NAME}"
    LAUNCH_INSTANCE_CMD="ecs-cli up --launch-type ${CLUSTER_LAUNCH_TYPE} --cluster ${CLUSTER_NAME}"

    ${LAUNCH_INSTANCE_CMD}

    if [ $? = 1 ] ; then
        # If cluster instance already exists
        echo "Cluster instance already running: ${CLUSTER_NAME}"
    fi

    echo "Logging in AWS..."
    $(aws ecr get-login --no-include-email --region ${AWS_REGION})

    echo "Build docker images..."
    export REPOSITORY_URI_PATH=
    docker-compose -f docker-compose-ecs.yml build

    for container in `yq -r '.services[] | select(has("build")).container_name' docker-compose-ecs.yml`
    do
        REPOSITORY_NAME=${NR_APP_NAME}-${container}
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

    echo "Launching ECS..."
    ecs-cli compose -f docker-compose-ecs.yml down
    ecs-cli compose -f docker-compose-ecs.yml up
else
    echo "Launching Container on local Docker."
    docker-compose -f ./docker-compose.yml down
    docker-compose -f ./docker-compose.yml build --no-cache
    docker-compose -f ./docker-compose.yml up -d
fi
