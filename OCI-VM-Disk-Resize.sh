#!/bin/bash

cid=$location_oci_id
ad=kWvg:CA-TORONTO-1-AD-1
backup=$backup_oci_id

cat instances.txt | while read instance 
do

oci bv volume create --availability-domain $ad  --compartment-id $cid --display-name $instance'-block1' --backup-policy-id $backup --size-in-gbs 100

oci bv volume list --compartment-id $cid --output table --query "data  [?\"display-name\" == '$instance-block1'].{VolumeID:id}" >volume

VOLID=$(grep -i ocid1.volume* volume | awk '{print $2}')

echo $VOLID

oci compute instance list --compartment-id $cid --output table --query "data  [?\"display-name\" == '$instance'].{OCID:id}" >ociid

OCID=$(grep -i ocid1.instance* ociid | awk '{print $2}')

echo $OCID

sleep 10

oci compute volume-attachment attach-paravirtualized-volume --volume-id $VOLID  --instance-id $OCID

done
