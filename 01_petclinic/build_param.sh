#!/bin/bash

NR_LICENSEKEY=

NR_APP_NAME=

AWS_KEY_NAME=
AWS_S3_PATH=s3://
AWS_AMIROLE_S3ACCESS=

AWS_CF_STACK=nrlabs-01-petclinic
AWS_CF_TEMPLATE=./resources/cloudformation/cloudformation.yaml 

APP_NAME=spring-petclinic-main
APP_URL=https://github.com/spring-projects/spring-petclinic/archive/main.zip

FORCE_TO_DELETE_STACK=enable