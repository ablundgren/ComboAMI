#!/bin/bash

# This script will pull up to two IPs from each availabilty zone that the
# autoscaling group to which the instance it is run from is part. 
# It must be run from a node with ec2 and autoscaling describe* capabilty.
# it may also run if the default creditials are specified and valid, though
# that has not been tested.
#
# The resulting string will contain a list of IPv4 addresses separated by 
# spaces.
#
# There is no error handling this this script it will not stop on 
# failures, or return a failed result. 
#
# The aws-cli must be installed and in the default path.
# the AWS_DEFAULT_REGION must be configured or set with an ENV var.
# If an HTTP HTTPS proxy are required, the ENV var must be set.
# If using a proxy, the NO_PROXY ENV var must also be set.


EC2_INSTANCE_ID=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`


ASG=`aws ec2 describe-tags --filters "Name=resource-id,Values=${EC2_INSTANCE_ID}" "Name=key,Values=aws:autoscaling:groupName" | grep Value | tr -s [:blank:] | cut -f4 -d\"`

#echo $ASG

AZONES=`aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name ${ASG} | xargs | grep -o "AvailabilityZones: \[.*\]," | cut -f 1 -d \] | cut -f 2 -d \[ | tr -d \,  | xargs`

#echo $AZONES

INSTANCE_IDS="`aws ec2 describe-tags --filters \"Name=value,Values=${ASG}\"  | grep ResourceId | cut -f4 -d\\" | sort -u | xargs`"

INSTANCE_IDS_ARG=`echo ${INSTANCE_IDS} | tr " " ,`


for AZ in ${AZONES}
do
#  echo "looking for ${AZ}"
  LOOP=`aws ec2 describe-instances  --filters "Name=availability-zone,Values=${AZ}" "Name=instance-id,Values=${INSTANCE_IDS_ARG}" | grep PrivateIpAddress | tr -d , | tr -s [:blank:] | cut -f 4 -d \\" | grep -v ^$ | sort -u `
#  echo loop=${LOOP}
  TWO_MAX=`echo ${LOOP} | cut -f 1-2 -d " "`
#  echo twomax=${TWO_MAX}
  INSTANCE_IPS="${INSTANCE_IPS} ${TWO_MAX}"
done
#echo
echo ${INSTANCE_IPS}
