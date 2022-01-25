#!/bin/bash
#Author: Chirag Barsaiya
#Script Ver: 1.3
((
echo $'\e[1;32m'This Script is for Performing RHEL Migration 7.6 to 8.1$'\e[0m'
echo  $'\e[1;31m'Project value is hardcoded, should be changed prior to running $'\e[0m'

#Concidering POC project will be used for building RHEL 8.2 Servers, hardcoded project to $poc_project

echo "--------------------------------------------------------------------"
echo $'\e[1;33m'Changing the Project to POC Project$'\e[0m'
echo "--------------------------------------------------------------------"
gcloud config set project $poc_project

#Looking for the Hostname input from user for RHEL 8.2 Instance

echo $'\e[1;33m'Enter the 8.2 RHEL Instance Name :$'\e[0m' $'\e[1;32m''(e.g tmp-hostname)'$'\e[0m'
read instance

echo "--------------------------------------------------------------------"
echo $'\e[1;33m'checking the status of $'\e[0m' $'\e[1;32m'$instance....$'\e[0m'
echo "--------------------------------------------------------------------"

#kept If condition to check the status of instance before proceeding, expected status should be terminated(powered0ff)

status=$(gcloud compute instances describe $instance --zone us-central1-c | grep status | awk '{print $2}')
 
if [ $status == "TERMINATED" ]

then
{
		#fetching boot disk details of rhel 8.2 instance, to take the snapshot

		disk=$(gcloud compute instances describe $instance --zone us-central1-c | grep -i source | awk '{ print $2 }' | awk ' BEGIN { FS="/" } { print $11 }')
		echo "--------------------------------------------------------------------"
		echo $'\e[1;32m'$instance,$'\e[0m' $'\e[1;33m'is Powered off, proceeding with taking the snapshot of boot disk:$'\e[0m' $'\e[1;32m'$disk $'\e[0m'
		echo "--------------------------------------------------------------------"
		
		#storing a variable with snapshot name to use while creating the disk to swap with rhel 7.2 vm boot disk.
		
		snapshotpoc=$(echo $disk-poc-`date +%H%M%S`)
		echo "--------------------------------------------------------------------"
		echo $'\e[1;33m'Creating Snapshot named $'\e[0m' $'\e[1;32m'$snapshotpoc....$'\e[0m'
		echo "--------------------------------------------------------------------"
		gcloud compute disks snapshot $disk --project=$poc_project --snapshot-names=$snapshotpoc --zone=us-central1-c --storage-location=us-central1
		
		echo "--------------------------------------------------------------------"
		echo  $'\e[1;33m'New Snapshot created named: $'\e[0m' $'\e[1;32m'$snapshotpoc $'\e[0m'
		echo "--------------------------------------------------------------------"

		vm=$(echo $instance | sed s/tmp-//g)


		#Again Project value is hardcoded, should be changed prior to running, currently kept it for $dev_project
		echo "--------------------------------------------------------------------"
		echo $'\e[1;33m'Changing the Project to $dev_project$'\e[0m'
		echo "--------------------------------------------------------------------"
		gcloud config set project $dev_project

		echo "--------------------------------------------------------------------"
		echo $'\e[1;33m'Creating CMEK Disk from the snapshot$'\e[0m' $'\e[1;32m'$snapshotpoc $'\e[0m'
		echo "--------------------------------------------------------------------"
		
		#looking for the zone details from user to find the VM in project
		
		echo $'\e[1;33m'Enter the Zone Name e.g us-central1-a, us-east4-c etc for 7.6 RHEL server$'\e[0m' $'\e[1;32m'$vm: $'\e[0m'
		read zone1
		
		#finding cmek value to encrypt new disk with same key.
		
		echo "--------------------------------------------------------------------"
		echo $'\e[1;33m'Finding CMEK Keys for$'\e[0m' $'\e[1;32m'$vm $'\e[0m'
		echo "--------------------------------------------------------------------"
		cmek_key="$(gcloud compute instances describe $vm --zone $zone1 | grep kmsKeyName | head -1 | awk '{print $2}')"
		
		echo "--------------------------------------------------------------------"
		echo $'\e[1;33m'CMEK attached to this VM is$'\e[0m' $'\e[1;32m'$cmek_key $'\e[0m' $'\e[1;33m'will be reusing the same to encrypt new disk$'\e[0m'
		echo "--------------------------------------------------------------------"
		echo "--------------------------------------------------------------------"
		echo $'\e[1;33m'checking the status of $'\e[0m' $'\e[1;32m'$vm....$'\e[0m'
		echo "--------------------------------------------------------------------"
		status=$(gcloud compute instances describe $vm --zone $zone1 | grep status | awk '{print $2}')
		 
		if [ $status == "TERMINATED" ]
		 
		then
		{

				
				disk1=$(gcloud compute instances describe $vm --zone $zone1 | grep -i source | awk '{ print $2 }' | awk ' BEGIN { FS="/" } { print $11 }' | head -1)
				echo "--------------------------------------------------------------------"
				echo $'\e[1;33m'Creating the snapshot for the old boot disk $'\e[0m' $'\e[1;32m'$disk1....$'\e[0m'
				echo "--------------------------------------------------------------------"
				disk2=$(echo $disk1-poc-`date +%H%M%S`)
				gcloud compute disks snapshot $disk1 --snapshot-names=$disk2 --zone=$zone1
				
				#creating the disk snapshot before swaping, although we are just detaching the disk but taking the latest snapshot as well.
				
				echo "--------------------------------------------------------------------"
				echo $'\e[1;33m'Snapshot created for $vm:$'\e[0m' $'\e[1;32m'$disk2 $'\e[0m'
				echo "--------------------------------------------------------------------"

				echo "--------------------------------------------------------------------"
				echo $'\e[1;33m'Creating new disk for $vm from snapshot$'\e[0m' $'\e[1;32m'$snapshotpoc....$'\e[0m'
				echo "--------------------------------------------------------------------"

				disktype=$(gcloud compute disks describe $disk1 --zone $zone1 | grep type | awk '{ print $2 }' | awk ' BEGIN { FS="/" } { print $11 }' | tail -1)
				disksize=$(gcloud compute disks describe $disk1 --zone=$zone1 | grep -i sizeGb | awk '{print $2}' | cut -d "'" -f 2)
				gcloud compute disks create $snapshotpoc --source-snapshot https://www.googleapis.com/compute/alpha/projects/$poc_project/global/snapshots/$snapshotpoc --zone $zone1 --type=$disktype --kms-key=$cmek_key --size=$disksize;

				echo "--------------------------------------------------------------------"
				echo $'\e[1;33m'Disk created for $vm:$'\e[0m' $'\e[1;32m'$snapshotpoc $'\e[0m'
				echo "--------------------------------------------------------------------"
				
				#In this below section, 1st detaching the old disk and attaching the new disk created.
				
				echo "--------------------------------------------------------------------"
				echo $'\e[1;33m'Detaching the old boot disk:$'\e[0m' $'\e[1;32m'$disk1 $'\e[0m'
				echo "--------------------------------------------------------------------"
				gcloud compute instances detach-disk $vm --disk=$disk1 --zone $zone1
				echo $disk1 >>DetachedDiskList-`date +%Y%m%d`.txt
				
				echo "--------------------------------------------------------------------"
				echo $'\e[1;33m'Attaching the new boot disk$'\e[0m' $'\e[1;32m'$snapshotpoc $'\e[0m' $'\e[1;33m'created from snapshot of $'\e[0m' $'\e[1;32m'$instance $'\e[0m'
				echo "--------------------------------------------------------------------"
				gcloud compute instances attach-disk $vm --disk=$snapshotpoc --zone $zone1 --device-name=$vm --boot

				#This section is for resource policies, for all boot disks, there are recource policies attached according to project, reusing the #same.
				
				echo "--------------------------------------------------------------------"
				echo $'\e[1;33m'Adding Resource Policies/Snapshot Schedule to the new disk:$'\e[0m' $'\e[1;32m'$snapshotpoc,$'\e[0m' $'\e[1;33m'and removing from the old disk:$'\e[0m' $'\e[1;32m'$disk1 $'\e[0m'
				echo "--------------------------------------------------------------------"
				resourcepolicies=$(gcloud compute disks describe $disk1 --zone $zone1 | grep resourcePolicies  | awk ' BEGIN { FS="/" } { print $11 }' | tail -1)
				gcloud compute disks add-resource-policies $snapshotpoc --resource-policies $resourcepolicies --zone $zone1
				gcloud compute disks remove-resource-policies $disk1 --zone $zone1 --resource-policies $resourcepolicies

		}
		else
		{
				echo $'\e[1;31m'$vm is not yet Powered-off, please check$'\e[0m'
				exit;
		}
		fi

		}

else
{
		echo $'\e[1;31m'$instance is not yet Powered-off, please check$'\e[0m';
		exit;
}
fi
#collecting all logs and saving it future analysis of change.
echo $'\e[1;33m'Logs for all action done in this script are logged in:$'\e[0m' $'\e[1;32m'./mig_logs_`date +%d-%m-%Y-%I-%M`.txt$'\e[0m'
) 2>&1) | tee -a mig_logs_`date +%d-%m-%Y-%I-%M`.txt
