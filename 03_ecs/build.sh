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

while getopts p: OPT
do
    case $OPT in
        # Check if parameters need to be retrieved from specified file or keep default file (build_param.sh)
        p) echo "Retrieving parameters from ${OPTARG}"
           . $OPTARG
           ;;
        # Check if browser agent needs to be read from file
        b) echo "Browser agent code will be added to the html"
           AGT_JS="${OPTARG}"
           OVERWRITEAPP=true
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

if [ ! -e ${APP_DIR} ]; then
    echo "There is no folder '${APP_DIR}', so download application forcibly"
    OVERWRITEAPP=true
fi

APP_DIR=app
if $OVERWRITEAPP ; then
    echo "Downloading application"
    rm -rf ${APP_DIR}
    curl -L -o ./app.zip ${APP_URL}
    unzip ./app.zip -d .
    mv ${APP_NAME} ${APP_DIR}
    rm ./app.zip
fi

if [ "${AGT_JS}" != "" ] ; then
    echo "Embeddig Browser Agent"

    # Delete old load snippet
    ${SED} -i -e '2d' ${AGT_JS}

    # Insert latest load snippet
    curl https://js-agent.newrelic.com/nr-loader-spa-current.min.js -w "\n" | gsed -i '1r /dev/stdin' ${AGT_JS}
    
    ${SED} -i "/<body>/r ${AGT_JS}" ${APP_DIR}/src/main/resources/templates/fragments/layout.html
fi

echo "Building application"
cd ${APP_DIR}
./mvnw package
cd ${DIR}

cp app/target/*.jar resources/webap/

export NR_LICENSEKEY=${NR_LICENSEKEY}
export NR_APP_NAME=${NR_APP_NAME}

docker-compose -f resources/docker-compose.yml down
docker-compose -f resources/docker-compose.yml build --no-cache
docker-compose -f resources/docker-compose.yml up -d

export NR_LICENSEKEY=
export NR_APP_NAME=
