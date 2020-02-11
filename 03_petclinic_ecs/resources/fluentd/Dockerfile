FROM fluent/fluentd:v1.9-1

# Use root account to use apk
USER root

# For New Relic Logs
RUN apk add sudo &&  \
    sudo fluent-gem install fluent-plugin-newrelic

ADD fluent.conf.local /fluentd/etc/fluent.conf
ADD entrypoint.sh /bin/

USER fluent
