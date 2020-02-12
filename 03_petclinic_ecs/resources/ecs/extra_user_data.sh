#!/bin/bash -xe

yum update -y
echo ECS_AVAILABLE_LOGGING_DRIVERS=[\"json-file\",\"syslog\",\"fluentd\"]>> /etc/ecs/ecs.config

