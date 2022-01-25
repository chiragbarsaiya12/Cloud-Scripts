gcloud config set project $gcp_project_name
gcloud compute firewall-rules list --format="csv(
          name,
          network,
          direction,
          priority,
          sourceRanges.list():label=SRC_RANGES,
          destinationRanges.list():label=DEST_RANGES,
          allowed[].map().firewall_rule().list():label=ALLOW,
          denied[].map().firewall_rule().list():label=DENY,
          sourceTags.list():label=SRC_TAGS,
          sourceServiceAccounts.list():label=SRC_SVC_ACCT,
          targetTags.list():label=TARGET_TAGS,
          targetServiceAccounts.list():label=TARGET_SVC_ACCT,
          disabled
      )" >/<home directory path>/Firewall_Tap_non_prod_`date +%Y%m%d`
