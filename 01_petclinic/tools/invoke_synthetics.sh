#!/bin/bash

ADMIN_USER_KEY=$1
QUERY_KEY=$2
ACCOUNT_ID=$3
MONITOR_NAME=$4
RETRY=10
INTERVAL=10

UNAME=`uname`
if type "gdate" > /dev/null 2>&1; then
    DATE_CMD=gdate
elif [ "${UNAME}" = "Darwin" ] ; then
    echo "Need GNU date for Mac"
    exit 1
else
    echo "If you use Mac, please install gnu-sed first"
    DATE_CMD=date
fi
SINCE=$($DATE_CMD +%s%3N)
NRQL="SELECT result FROM SyntheticCheck SINCE ${SINCE} WHERE monitorName = '${MONITOR_NAME}' limit 1"

echo "Getting Synthetics Monitor Information"
MONITOR=$(curl -s -X GET -H "X-Api-Key:${ADMIN_USER_KEY}" \
     -H "Content-Type: application/json" https://synthetics.newrelic.com/synthetics/api/v3/monitors/ | \
     jq '[.monitors[] | select(.name == "'${MONITOR_NAME}'") | {id,status}] | .[0]')

ID=$(jq -r '.id' <<< $MONITOR)
STATUS=$(jq -r '.status' <<< $MONITOR)

echo "Synthetics Monitor: ${MONITOR_NAME}, ${ID}, ${STATUS}"

if [ "${STATUS}" = "DISABLED" ]; then
    echo "Enabling Synthetic Monitor: ${MONITOR_NAME}, ${ID}"
    curl -s -X PATCH -H "X-Api-Key:${ADMIN_USER_KEY}" \
       -H "Content-Type: application/json" https://synthetics.newrelic.com/synthetics/api/v3/monitors/${ID} \
       -d '{ "status" : "enabled" }'
else
    echo "Synthetic Monitor is already enabled: ${MONITOR_NAME}, ${ID}"
fi

#URLEncode
ENC_NRQL=$(echo "$NRQL" | nkf -WwMQ | sed 's/=$//g' | tr = % | tr -d '\n')
for i in `seq 1 ${RETRY}`
do
    RESULT=$(curl -s -H "Accept: application/json" \
        -H "X-Query-Key: ${QUERY_KEY}" \
        "https://insights-api.newrelic.com/v1/accounts/${ACCOUNT_ID}/query?nrql=${ENC_NRQL}" | \
        jq -r '.results[0].events[0].result')

    if [ "$RESULT" != "null" ]; then
        echo "Synthetic Check has finished with status ${RESULT}"
        break
    fi

    echo "Synthetic Check seems not finished (${RESULT}). Will check again after ${INTERVAL} sec"
    sleep ${INTERVAL}
done

echo "Disabling Synthetic Monitor: ${MONITOR_NAME}, ${ID}"
curl -s \
    -X PATCH -H "X-Api-Key:${ADMIN_USER_KEY}" \
    -H "Content-Type: application/json" https://synthetics.newrelic.com/synthetics/api/v3/monitors/${ID} \
    -d '{ "status" : "disabled" }'

if [ "${RESULT}" = "SUCCESS" ]; then
    echo "Synthetics Check has completed successfully"
    STATUS_CODE=0
else
    echo "Synthetics Check failed"
    STATUS_CODE=1
fi

exit $STATUS_CODE

