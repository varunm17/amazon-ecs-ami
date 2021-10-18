#!/usr/bin/env bash
set -eio pipefail

usage() {
    echo "Usage:"
    echo "  $0 AGENT_VERSION"
}

readonly agent_version="$1"
if [ -z "$agent_version" ]; then
    echo "ERROR: Agent version is required."
    usage
    exit 1
fi
# this can be any region, as we use it to grab the latest AL2 AMI name so it should be the same across regions.
readonly region="us-west-2"

set -x

# get the latest source AMI names
ami_id_x86=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-x86_64-ebs --query 'Parameters[0].[Value]' --output text)
ami_name_x86=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_x86" --query 'Images[0].Name' --output text)
ami_id_arm=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn2-ami-minimal-hvm-arm64-ebs --query 'Parameters[0].[Value]' --output text)
ami_name_arm=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_arm" --query 'Images[0].Name' --output text)
ami_id_al1=$(aws ssm get-parameters --region "$region" --names /aws/service/ami-amazon-linux-latest/amzn-ami-minimal-hvm-x86_64-ebs --query 'Parameters[0].[Value]' --output text)
ami_name_al1=$(aws ec2 describe-images --region "$region" --owner amazon --image-id "$ami_id_al1" --query 'Images[0].Name' --output text)
readonly ami_name_arm ami_name_x86 ami_name_al1

cat >|release.auto.pkrvars.hcl <<EOF
ami_version        = "$(date --utc +%Y%m%d)"
source_ami_al2     = "$ami_name_x86"
source_ami_al2arm  = "$ami_name_arm"
ecs_agent_version  = "$agent_version"
ecs_init_rev       = "1"
docker_version     = "20.10.7"
containerd_version = "1.4.6"
source_ami_al1     = "$ami_name_al1"
EOF