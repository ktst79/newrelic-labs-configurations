FROM openjdk:8-alpine

LABEL maintainer="Demo <demo@exapmple.com>"

ARG NR_LICENSEKEY
ARG NR_APP_NAME

RUN echo "Now building..." && \
    mkdir /opt/petclinic && \
    mkdir /opt/newrelic

ADD *.jar /opt/petclinic

RUN apk update && \
    apk add sudo && \
    apk add curl && \
    apk add sed && \
    curl -o /opt/newrelic/newrelic.jar https://download.newrelic.com/newrelic/java-agent/newrelic-agent/current/newrelic.jar && \
    curl -o /opt/newrelic/newrelic.yml https://download.newrelic.com/newrelic/java-agent/newrelic-agent/current/newrelic.yml && \
    sed -i -e "s/app_name: My Application$/app_name: ${NR_APP_NAME}/" /opt/newrelic/newrelic.yml && \
    sed -i -e "s/<%= license_key %>/${NR_LICENSEKEY}/" /opt/newrelic/newrelic.yml

CMD java -javaagent:/opt/newrelic/newrelic.jar -jar \
    -Dspring.profiles.active=mysql \
    -Dspring.datasource.url=${DBURL} \
    -Dspring.datasource.username=${DBUSER} \
    -Dspring.datasource.password=${DBPASS} \
    -Dnewrelic.config.distributed_tracing.enabled=true \
    /opt/petclinic/*.jar

