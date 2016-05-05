#!/bin/bash
set -e

# exit if no env, ami_id or config version specified
[[ $# = 3 ]] || { echo "Usage: $0 ENV AMI_ID CONFIG_VERSION"; exit 1; }

ENV=$1
AMI_ID=$2
CONFIG_VERSION=$3

cd ../csd-notes-infrastructure

terraform remote config -backend=s3 -backend-config="bucket=csd-notes-terraform"\
  -backend-config="key=${ENV}.tfstate" -backend-config="region=eu-west-1"

terraform remote pull

echo "
Deploying with args:
image_id = ${AMI_ID}
config_version = ${CONFIG_VERSION}
env = $(terraform output environment)
lc_security_groups = $(terraform output web_sg_id)
load_balancers = $(terraform output elb_name)
availability_zones = $(terraform output availability_zones)
asg_subnets = $(terraform output private_subnets)
"

ansible-playbook ../csd-notes-deploy/ansible/rolling_ami.yml -vv --extra-vars \
"image_id=${AMI_ID}
config_version=${CONFIG_VERSION}
env=$(terraform output environment)
lc_security_groups=$(terraform output web_sg_id)
load_balancers=$(terraform output elb_name)
availability_zones=$(terraform output availability_zones)
asg_subnets=$(terraform output private_subnets)"
