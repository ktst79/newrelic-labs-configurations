#!/bin/sh

DIR=$(cd $(dirname $0); pwd)
cd ${DIR}

. ./build_param_cluster.sh

while getopts p:d OPT
do
    case $OPT in
        # Check if parameters need to be retrieved from specified file or keep default file (build_param.sh)
        p) echo "Retrieving parameters from ${OPTARG}"
           . $OPTARG
           ;;
        # Check if parameters need to be retrieved from specified file or keep default file (build_param.sh)
        d) echo "Delete VPC and Kubernetes"
           DELETE=true
           ;;
    esac
done

if [ "${NR_LICENSEKEY}" = "" ] ; then
    echo 'NR_LICENSEKEY are not specified. Check build_param.sh'
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

if [ "${KUBE_STATE_METRICS_URL}" = "" ] ; then
    echo 'KUBE_STATE_METRICS_URL are not specified. Check build_param.sh'
    exit 1
fi

if [ "${CLUSTER_NAME}" = "" ] ; then
    echo 'CLUSTER_NAME are not specified. Check build_param.sh'
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

export NR_LICENSEKEY=${NR_LICENSEKEY}
export CLUSTER_NAME=${CLUSTER_NAME}


if [ "${DELETE}" = "true" ] ; then
    echo "Uninstalling Kuberenetes Logging"
    helm uninstall kubernetes-logging-${CLUSTER_NAME}

    echo "Deleting link to APM"
    cat resources/newrelic/k8s-metadata-injection-latest.yaml | envsubst | kubectl delete -f -

    echo "Deleting kube-state-metrics"
    kubectl delete -f target/kubernetes/kube-state-metrics/kubernetes

    echo "Deleting newrelic-infrastructure-k8s"
    cat resources/newrelic/newrelic-infrastructure-k8s-latest.yaml | envsubst | kubectl delete -f -

    echo "Deleting nri-kube-events"
    cat resources/newrelic/nri-kube-events-latest.yaml | envsubst | kubectl delete -f -

    echo "Deleting cluster: ${CLUSTER_NAME}"
    eksctl delete cluster --name ${CLUSTER_NAME} --wait
 
    echo "Deleting VPC: ${AWS_CF_VPC_STACK}"
    aws cloudformation delete-stack --stack-name ${AWS_CF_VPC_STACK}
    aws cloudformation wait stack-delete-complete --stack-name ${AWS_CF_VPC_STACK}

    exit 0
fi

################ Delete Existing Stacks ########################
aws cloudformation describe-stacks --stack-name ${AWS_CF_VPC_STACK} > /dev/null
IS_VPC_STACK=$?

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
PUB_SUBNETS=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "SubnetsPublic") | .OutputValue'`
PRI_SUBNETS=`echo "${OUTPUTS}" | jq -r '.Stacks[0].Outputs[] | select(.OutputKey == "SubnetsPrivate") | .OutputValue'`

echo "PUB_SUBNETS: ${PUB_SUBNETS}"
echo "PRI_SUBNETS: ${PRI_SUBNETS}"

################ Create EKS Cluster ########################
eksctl get cluster ${CLUSTER_NAME} > /dev/null
CLUSTER_EXIST=$?

if [ "${CLUSTER_EXIST}" = "0" ] && [ "${SKIP_IF_CLUSTER_EXIST}" != "true" ] ; then
    echo "Deleting cluster: ${CLUSTER_NAME}"
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
    echo "Cluster has been created: ${CLUSTER_NAME}"
else
    echo "Cluster already exists: ${CLUSTER_NAME}"
fi

echo "Enabling New Relic Kubernetes Monitoring"
rm -rf target/kubernetes/
curl -L --create-dirs -o target/kubernetes/kube-state-metrics.zip ${KUBE_STATE_METRICS_URL}
unzip  -q -d target/kubernetes/ -o target/kubernetes/kube-state-metrics.zip
rm target/kubernetes/kube-state-metrics.zip
KUBE_DIR=`ls target/kubernetes/`
kubectl apply -f target/kubernetes/${KUBE_DIR}/kubernetes

kubectl get pods --all-namespaces | grep kube-state-metrics

echo "Creating the daemon set"
CONF_FILE=resources/newrelic/newrelic-infrastructure-k8s-latest.yaml
if [ ! -e ${CONF_FILE} ]; then
    echo "File (${CONF_FILE}) needs to be downloaded in advance and replace place holder like \${CLUSTER_NAME} to use envsubst"
fi
cat ${CONF_FILE} | envsubst | kubectl create -f -
kubectl get daemonsets

echo "Integrating Kuberenetes Event"
CONF_FILE=resources/newrelic/nri-kube-events-latest.yaml
if [ ! -e ${CONF_FILE} ]; then
    echo "File (${CONF_FILE}) needs to be downloaded in advance and replace place holder like \${CLUSTER_NAME} to use envsubst"
fi
cat ${CONF_FILE} | envsubst | kubectl apply -f -

echo "Integrating Kuberenets with APM"
CONF_FILE=resources/newrelic/k8s-metadata-injection-latest.yaml
if [ ! -e ${CONF_FILE} ]; then
    echo "File (${CONF_FILE}) needs to be downloaded in advance and replace place holder like \${CLUSTER_NAME} to use envsubst"
fi
cat ${CONF_FILE} | envsubst | kubectl apply -f -

echo "Enabling Kunbernetes Log Monitoring"
rm -rf target/kubernetes-logging
git clone git@github.com:newrelic/kubernetes-logging.git target/kubernetes-logging
helm install kubernetes-logging-${CLUSTER_NAME} --set licenseKey=${NR_LICENSEKEY} target/kubernetes-logging/helm/newrelic-logging
