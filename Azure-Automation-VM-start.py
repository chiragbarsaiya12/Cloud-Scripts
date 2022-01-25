#For Stopping the VM

$Connection = Get-AutomationConnection -Name AzureRunAsConnection
Add-AzureRMAccount -ServicePrincipal -TenantID $Connection.TenantId -ApplicationID $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint
$VMs = Get-AzureRmVM | Where-Object { $_.tags.AutoStartPriority -ne $null }
$AllVMList = @()
Foreach ($VM in $VMs) {
	$VM = New-Object psobject -Property @{`
		#"Subscriptionid" = $SubID;		
		"ResourceGroupName" = $VM.ResourceGroupName;
		"AutoStartPriority" = $VM.tags.AutoStartPriority;
		"VMName" = $VM.Name}
		$AllVMList += $VM | select ResourceGroupName,VMName,AutoStartPriority
		}



$AllVMListSorted = $AllVMList | Sort-Object -Property AutoStartPriority
Write-Output "$(Get-Date -format s) :: Sorted VM start list"
$AllVMListSorted

##Start VMs block
Write-Output "$(Get-Date -format s) :: Stop VM now"

Foreach ($VM in $AllVMListSorted) {
	Write-Output "$(Get-Date -format s) :: Stop VM: $($VM.VMName) :: $($VM.ResourceGroupName)"
	#Select-AzureRmSubscription -Subscriptionid $VM.Subscriptionid
	Stop-AzureRmVM -Force -ResourceGroupName $VM.ResourceGroupName -Name $VM.VMName
	#Start-Sleep -s 10
}

#--------------------------------------------------------------------------------------------------------------

#for Starting the VM

$Connection = Get-AutomationConnection -Name AzureRunAsConnection
Add-AzureRMAccount -ServicePrincipal -TenantID $Connection.TenantId -ApplicationID $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint
$VMs = Get-AzureRmVM | Where-Object { $_.tags.AutoStartPriority -ne $null }
$AllVMList = @()
Foreach ($VM in $VMs) {
	$VM = New-Object psobject -Property @{`
		#"Subscriptionid" = $SubID;		
		"ResourceGroupName" = $VM.ResourceGroupName;
		"AutoStartPriority" = $VM.tags.AutoStartPriority;
		"VMName" = $VM.Name}
		$AllVMList += $VM | select ResourceGroupName,VMName,AutoStartPriority
		}



$AllVMListSorted = $AllVMList | Sort-Object -Property AutoStartPriority
Write-Output "$(Get-Date -format s) :: Sorted VM start list"
$AllVMListSorted

##Start VMs block
Write-Output "$(Get-Date -format s) :: Start VM now"

Foreach ($VM in $AllVMListSorted) {
	Write-Output "$(Get-Date -format s) :: Start VM: $($VM.VMName) :: $($VM.ResourceGroupName)"
	#Select-AzureRmSubscription -Subscriptionid $VM.Subscriptionid
	Start-AzureRmVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.VMName
	#Start-Sleep -s 10
}
