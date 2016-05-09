#!/bin/bash
set -e

# exit if no env, ami_id or config version specified
[[ $# = 3 ]] || { echo "Usage: $0 ENV AMI_ID CONFIG_VERSION"; exit 1; }

ENV=$1
IMAGE_ID=$2
CONFIG_VERSION=$3

cd ../csd-notes-infrastructure

# always delete local tfstate files before doing anything else, because
# terraform blindly pushes any local state to remote storage as a first step
# rm ./*.tfstate*
# rm ./.terraform/*.tfstate*

terraform remote config -backend=s3 -backend-config="bucket=csd-notes-terraform"\
  -backend-config="key=${ENV}.tfstate" -backend-config="region=eu-west-1"

terraform remote pull

LC_SECURITY_GROUPS=$(terraform output web_sg_id)
LOAD_BALANCERS=$(terraform output elb_name)
AVAILABILITY_ZONES=$(terraform output availability_zones)
ASG_SUBNETS=$(terraform output private_subnets)

cd ../csd-notes-deploy

echo "
Deploying with args:
image_id = ${IMAGE_ID}
config_version = ${CONFIG_VERSION}
env = ${ENV}
lc_security_groups = ${LC_SECURITY_GROUPS}
load_balancers = ${LOAD_BALANCERS}
availability_zones = ${AVAILABILITY_ZONES}
asg_subnets = ${ASG_SUBNETS}
"

EC2_INI_PATH=ec2.ini ansible-playbook -i ec2.py ansible/site.yml \
--extra-vars \
"image_id=${IMAGE_ID}
config_version=${CONFIG_VERSION}
env=${ENV}
lc_security_groups=${LC_SECURITY_GROUPS}
load_balancers=${LOAD_BALANCERS}
availability_zones=${AVAILABILITY_ZONES}
asg_subnets=${ASG_SUBNETS}
