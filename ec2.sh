#!/bin/bash
#
# お手軽 EC2 起動・停止
#
# - 第一引数は start か stop
# - タグ名 (typename) からインスタンスを起動
#

# 引数チェック (数のみ)
# - https://bioinfo-dojo.net/2018/02/21/shellscript_args/#toc2
if [ $# != 2 ]; then
    echo >&2 "ERROR: Args count error."
    exit 1
fi

COMMAND=$1  # start, stop
TYPENAME=$2

INSTANCE_ID=$(aws ec2 describe-instances --filter "Name=tag:typename,Values=$TYPENAME" --query "Reservations[].Instances[].InstanceId" --output text)
if [ $? -ne 0 ]; then
    echo >&2 "ERROR: aws ec2 describe-instances error."
    exit 1
fi
echo $INSTANCE_ID

case "$COMMAND" in
    "start" )
        aws ec2 start-instances --instance-ids $INSTANCE_ID
        ;;
    "stop" )
        aws ec2 stop-instances --instance-ids $INSTANCE_ID
        ;;   
    * )
        echo >&2 "ERROR: Command is not start or stop."
        exit 1
        ;;
esac

if [ $? -ne 0 ]; then
    echo >&2 "ERROR: aws ec2 start|stop-instances error."
    exit 1
fi
