Start-Transcript -Path <transcript path>
#path for the file containing list of VM's
$VMFile = Get-Content "<file containing list of virtual machine>"

ForEach ($file in $VMFile)

{

$vmName = $file | %{ $_.Split(',')[0]; }
$NewVMSize = $file | %{ $_.Split(',')[1]; }

#FInding Associated RG
$VMDetails = Get-AzVM -Name $vmName
$resourceGroup = $VMDetails.ResourceGroupName
$vm = Get-AzVM -ResourceGroupName $resourceGroup -VMName $vmName

Stop-AzVM -ResourceGroupName $resourceGroup -Name $vmName -Force
#Updating with New size of VM
$vm.HardwareProfile.VmSize = $NewVMSize
Update-AzVM -VM $vm -ResourceGroupName $resourceGroup

#Restarting the VM
Write-Output "Please wait while we restart the server"
Start-AzVM -ResourceGroupName $resourceGroup -Name $vmName

}

#Verification on Changes

Write-Output "All Servers has been resized now, We will verify the changes, if not as expected, please check on Portal"
sleep 5
ForEach ($file in $VMFile)

{

$vmName = $file | %{ $_.Split(',')[0]; }

$VMDetails = Get-AzVM -Name $vmName
$resourceGroup = $VMDetails.ResourceGroupName
Write-Output "------------------------------------------------------------------------------------------"
Write-Output "Please find the status and VM Size for " $vmName
Write-Output "------------------------"
$VMStats = (Get-AzVM -Name $vmName -ResourceGroupName $resourceGroup -Status).Statuses
($VMStats | Where Code -Like 'PowerState/*')[0].DisplayStatus
Write-Output "------------------------"
$Sizecheck = Get-AzVM -Name $vmName
$Sizecheck.HardwareProfile
$NewSize = $Sizecheck.HardwareProfile
Add-Content "<path for output file>" -Value "Processing  $vmName : $NewSize"
}Stop-Transcript
