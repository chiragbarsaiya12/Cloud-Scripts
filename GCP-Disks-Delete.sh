#!/bin/bash
((
date=$(date '+%m/%d/%y-%H:%M')
zone1=$zone
IFS=$'\n'; for disk in $(awk '{print $0}' disks.txt);
do

		AttachmentStatus=$(gcloud compute disks describe $disk --zone $zone1 | grep instances )
		AttachedInstance=$(gcloud compute disks describe $disk --zone $zone1 | grep instances  | awk ' BEGIN { FS="/" } { print $11 }')
		if [ -z "$AttachmentStatus" ]
		then
		gcloud compute disks delete $disk --zone $zone1 --quiet
		echo $'\e[1;32m' "$disk deleted now at $date" 
		else
		echo $'\e[1;32m' "$disk is attached to $AttachedInstance, please check"
		fi
		
done

) 2>&1) | tee -a cmek_logs_`date +%d-%m-%Y-%I-%M`.txt
