#!/bin/bash

NR_LICENSEKEY=

NR_APP_NAME=

AWS_CF_VPC_STACK=nrlabs-60-complex-vpc
AWS_CF_VPC_TEMPLATE=./resources/cf/cf_eks_vpc.yaml 

AWS_CF_RDS_STACK=nrlabs-60-complex-app-settings-rds
AWS_CF_RDS_TEMPLATE=./resources/cf/cf_rds.yaml 

SKIP_IF_STACK_EXIST=true
SKIP_IF_CLUSTER_EXIST=true

KUBE_STATE_METRICS_URL=https://github.com/kubernetes/kube-state-metrics/archive/v1.7.2.zip

DATA_PLANE=ec2
#DATA_PLANE=fargate
NODE_TYPE=t2.small

DB_NAME=db
DB_USER=user
DB_PASS=password
DB_PORT=3306

