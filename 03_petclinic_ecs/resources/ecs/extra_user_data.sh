#!/bin/bash -xe

yum update -y
echo ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"syslog\",\"fluentd\"]>> /etc/ecs/ecs.config

curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/7/x86_64/newrelic-infra.repo
yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'
yum install newrelic-infra -y
echo "license_key: ${NR_LICENSEKEY}" > /etc/newrelic-infra.yml
systemctl restart newrelic-infra

