#!/bin/bash

NR_LICENSEKEY=

NR_APP_NAME=

AWS_KEY_NAME=
AWS_S3_PATH=s3://
AWS_AMIROLE_S3ACCESS=

AWS_CF_STACK=nrlabs-01-petclinic
AWS_CF_TEMPLATE=./resources/cloudformation/cloudformation.yaml 
AWS_AP_AMIID=ami-068a6cefc24c301d2
AWS_AP_INSTANCETYPE=t2.micro

APP_NAME=spring-petclinic-master
APP_URL=https://github.com/spring-projects/spring-petclinic/archive/master.zip

FORCE_TO_DELETE_STACK=enable