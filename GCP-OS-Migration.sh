#!/bin/bash
#Author: Chirag Barsaiya
Script Ver: 1
echo "This Script is for Performing RHEL Migration 7.6 to 8.1"
echo "--------------------------------------------------------------------"
echo "Changing Project to POC Project"
echo "--------------------------------------------------------------------"
gcloud config set project $poc_project
echo $'\e[1;32m' "Enter the Instance Name : "
read instance
echo $'\e[1;32m' "Enter the Zone Name e.g us-central1-a, us-east4-c etc : "
read zone1
region="$(gcloud compute instances describe $instance --zone $zone1 |egrep "(subnetwork:)"|awk -F"regions/" '{print $2}'|awk -F"/" '{print $1}')"
disk=$(gcloud compute instances describe $instance --zone $zone1 | grep boot | awk '{print $2}')
gcloud compute disks snapshot $disk --project=tpr-poc --snapshot-names=$disk-poc --zone=$zone1 --storage-location=$region >snapshotpoc.txt
disktype=$(gcloud compute disks describe $disk --zone $zone1 | grep type | awk '{ print $2 }' | awk ' BEGIN { FS="/" } { print $11 }' | tail -1)


echo "--------------------------------------------------------------------"
echo "Chaning the Project to Non-prod"
echo "--------------------------------------------------------------------"
gcloud config set project $non_prod_project
cat snapshotpoc.txt
IFS=$'\n'; for SNAPSHOTNAME in $(awk '{print $0}' snapshotpoc.txt);
do
gcloud compute disks create $SNAPSHOTNAME --source-snapshot https://www.googleapis.com/compute/alpha/projects/$poc_project/global/snapshots/$SNAPSHOTNAME --zone us-central1-c --type=$disktype;
done

vm=$(echo $instance | sed s/tmp-//g)

echo "--------------------------------------------------------------------"
echo "Stopping the $vm"
echo "--------------------------------------------------------------------"

gcloud compute instances stop $vm --zone us-central1-a;

echo "--------------------------------------------------------------------"
echo "Creating the snapshot the old boot disk $disk1"
echo "--------------------------------------------------------------------"
disk1=$(gcloud compute instances describe $vm --zone us-central1-a | grep boot | awk '{print $2}')
gcloud compute disks snapshot $disk1 --snapshot-names=$disk-$date --zone=us-central1-a

echo "--------------------------------------------------------------------"
echo "Detaching the old boot disk $disk1"
echo "--------------------------------------------------------------------"
gcloud compute instances detach-disk $vm --disk=$disk1 --zone us-central1-a
echo $ddisk1 >>DetachedDiskList-`date +%Y%m%d`.txt

echo "--------------------------------------------------------------------"
echo "Attaching the new boot disk $SNAPSHOTNAME created from snapshot of $instance"
echo "--------------------------------------------------------------------"
gcloud compute instances attach-disk $vm --disk=$SNAPSHOTNAME --zone us-central1-a --device-name=$vm

echo "--------------------------------------------------------------------"
echo "Powering On the $vm"
echo "--------------------------------------------------------------------"
gcloud compute instances start $vm --zone us-central1-a;
