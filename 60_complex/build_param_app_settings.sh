#!/bin/bash

NR_LICENSEKEY=

NR_APP_NAME=

VR=1.0

# Kubernetes Cluster
AWS_CF_VPC_STACK=nrlabs-60-complex-vpc

CLUSTER_NAME=nrlabs-60-complex

# App Settings
AWS_CF_RDS_STACK=nrlabs-60-complex-app-settings-rds
AWS_CF_RDS_TEMPLATE=./resources/cf/cf_rds.yaml 
SKIP_IF_STACK_EXIST=true

DB_NAME=db
DB_USER=user
DB_PASS=password
DB_PORT=3306

