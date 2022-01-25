#For Stopping the VM

$Connection = Get-AutomationConnection -Name AzureRunAsConnection
Add-AzureRMAccount -ServicePrincipal -TenantID $Connection.TenantId -ApplicationID $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint

$VMs = Get-AzureRmVM | Where-Object { $_.tags.AutoStopPriority -ne $null }

$AllVMList = @()
Foreach ($VM in $VMs) {
	$VM = New-Object psobject -Property @{`
		#"Subscriptionid" = $SubID;		
		"ResourceGroupName" = $VM.ResourceGroupName;
        	"PowerState" = $VM.PowerState
		"AutoStopPriority" = $VM.tags.AutoStopPriority;
		"VMName" = $VM.Name}
		$AllVMList += $VM | select ResourceGroupName,VMName,AutoStopPriority
		}



$AllVMListSorted = $AllVMList | Sort-Object -Property AutoStopPriority
Write-Output "$(Get-Date -format s) :: Sorted VM start list"
$AllVMListSorted

##Start VMs block
Write-Output "$(Get-Date -format s) :: Stop VM now"

Foreach ($VM in $AllVMListSorted) {
	Write-Output "$(Get-Date -format s) :: Stop VM: $($VM.VMName) :: $($VM.ResourceGroupName) :: $($VM.PowerState)"
    #Select-AzureRmSubscription -Subscriptionid $VM.Subscriptionid
	Stop-AzureRmVM -Force -ResourceGroupName $VM.ResourceGroupName -Name $VM.VMName
    if($VM.PowerState -ne "deallocated")
        { Start-Sleep -s 5 }
    # 1 / $i--
}
