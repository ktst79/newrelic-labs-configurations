#!/bin/bash

NR_LICENSEKEY=

# Kubernetes Cluster
AWS_CF_VPC_STACK=nrlabs-60-complex-vpc
AWS_CF_VPC_TEMPLATE=./resources/cf/cf_eks_vpc.yaml 

SKIP_IF_VPC_EXIST=true
SKIP_IF_CLUSTER_EXIST=true

KUBE_STATE_METRICS_URL=https://github.com/kubernetes/kube-state-metrics/archive/v1.7.2.zip
CLUSTER_NAME=nrlabs-60-complex

DATA_PLANE=ec2
#DATA_PLANE=fargate
NODE_TYPE=t2.small
