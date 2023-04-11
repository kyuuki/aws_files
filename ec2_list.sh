#!/bin/bash
#
# EC2 一覧
#

aws ec2 describe-instances --query "Reservations[].Instances[].{InstanceId:InstanceId,Name:Tags[?Key=='Name']|[0].Value,PublicIP:PublicIpAddress,Status:State.Name}" --output table
if [ $? -ne 0 ]; then
    echo >&2 "ERROR: aws ec2 describe-instances error."
    exit 1
fi
