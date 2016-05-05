#!/bin/bash
set -e

# exit if no ami_id or config version specified
[[ $# = 2 ]] || { echo "Usage: $0 AMI_ID CONFIG_VERSION"; exit 1; }

cd ../csd-notes-infrastructure

terraform refresh

echo "
Deploying with args:
image_id = $1
config_version = $2
env = $(terraform output environment)
lc_security_groups = $(terraform output web_sg_id)
load_balancers = $(terraform output elb_name)
availability_zones = $(terraform output availability_zones)
asg_subnets = $(terraform output private_subnets)
"

ansible-playbook ../csd-notes-deploy/ansible/rolling_ami.yml -vv --extra-vars \
"image_id=$1
config_version=$2
env=$(terraform output environment)
lc_security_groups=$(terraform output web_sg_id)
load_balancers=$(terraform output elb_name)
availability_zones=$(terraform output availability_zones)
asg_subnets=$(terraform output private_subnets)"
