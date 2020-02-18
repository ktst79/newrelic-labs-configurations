#!/bin/bash

NR_LICENSEKEY=

NR_APP_NAME=

AWS_KEY_NAME=

APP_NAME=spring-petclinic-master
APP_URL=https://github.com/spring-projects/spring-petclinic/archive/master.zip

ENV=ecs_ec2
#ENV=ecs_fargate
#ENV=local

CLUSTER_INSTANCE_TYPE=t2.small
CLUSTER_INSTANCE_NUM=1
CLUSTER_LAUNCH_USERDATA=./resources/ecs/extra_user_data.sh

FORCE_TO_DELETE_STACK=enable
