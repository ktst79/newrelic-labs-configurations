#!/bin/bash

NR_LICENSEKEY=

NR_APP_NAME=

AWS_KEY_NAME=

AWS_CF_STACK=nrlabs-03-petclinic-ecs
AWS_CF_TEMPLATE=./resources/cloudformation/cloudformation.yaml 

APP_NAME=spring-petclinic-main
APP_URL=https://github.com/spring-projects/spring-petclinic/archive/main.zip

ENV=ecs_ec2
#ENV=ecs_fargate
#ENV=local

CLUSTER_INSTANCE_TYPE=t2.small
CLUSTER_INSTANCE_NUM=1
CLUSTER_LAUNCH_USERDATA=./resources/ecs/extra_user_data.sh

FORCE_TO_DELETE_STACK=enable

MYSQL_ROOT_PASSWORD=
MYSQL_DATABASE=
MYSQL_USER=
MYSQL_PASSWORD=
