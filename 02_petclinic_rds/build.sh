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

OVERWRITEAPP=false
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

if [ "${AWS_KEY_NAME}" = "" ] ; then
    echo 'AWS_KEY_NAME are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_S3_PATH}" = "" ] ; then
    echo 'AWS_S3_PATH are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_AMIROLE_S3ACCESS}" = "" ] ; then
    echo 'AWS_AMIROLE_S3ACCESS are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_CF_STACK}" = "" ] ; then
    echo 'AWS_CF_STACK are not specified. Check build_param.sh'
    exit 1
fi

if [ "${AWS_CF_TEMPLATE}" = "" ] ; then
    echo 'AWS_CF_TEMPLATE are not specified. Check build_param.sh'
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

if [ ! -e ${APP_DIR} ]; then
    echo "There is no folder '${APP_DIR}', so download application forcibly"
    OVERWRITEAPP=true
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
fi

echo "Building application"
cd ${APP_DIR}
./mvnw package
cd ${DIR}

JAR_FILE_PATH=`ls ${APP_DIR}/target/*.jar`
JAR_FILE=`echo ${JAR_FILE_PATH##*/}`

echo "Uploading application archive to S3. ${AWS_S3_PATH}/${JAR_FILE}"
aws s3 cp ${APP_DIR}/target/$JAR_FILE $AWS_S3_PATH/

if [ "${FORCE_TO_DELETE_STACK}" = "enable" ] ; then
    echo "Deleting existing cloudformation stack. ${AWS_CF_STACK}"
    aws cloudformation delete-stack --stack-name $AWS_CF_STACK
    aws cloudformation wait stack-delete-complete --stack-name $AWS_CF_STACK
fi

echo "Creating cloudformation stack. ${AWS_CF_STACK}"
aws cloudformation create-stack --stack-name $AWS_CF_STACK \
    --template-body file://$AWS_CF_TEMPLATE \
    --parameters ParameterKey=KeyNameParam,ParameterValue=$AWS_KEY_NAME \
    ParameterKey=ApplicationJarParam,ParameterValue=$AWS_S3_PATH/$JAR_FILE \
    ParameterKey=ManagedS3AccessIAMRoleParam,ParameterValue=$AWS_AMIROLE_S3ACCESS \
    ParameterKey=NRLicParam,ParameterValue=$NR_LICENSEKEY \
    ParameterKey=ApplicationNameParam,ParameterValue=$NR_APP_NAME \
    --capabilities CAPABILITY_IAM

echo "Waiting compleation of cloudformation stack. ${AWS_CF_STACK}"
aws cloudformation wait stack-create-complete --stack-name $AWS_CF_STACK

echo "Cloudformation stack has been created. ${AWS_CF_STACK}"
aws cloudformation describe-stacks --stack-name $AWS_CF_STACK
