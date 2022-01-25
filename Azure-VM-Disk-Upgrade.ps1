
$rgName = '<Resource Group Name>'

#path for the file containing list of VM's
$VMFile = Get-Content "<file containing VM list>"

ForEach ($vmName in $VMFile)

{

	$storageType = 'Premium_LRS'
	# $size = 'Standard_DS2_v2'

	# Stopping the VM
	Stop-AzVM -ResourceGroupName $rgName -Name $vmName -Force

	$vm = Get-AzVM -Name $vmName -resourceGroupName $rgName

	# Change the VM size to a size that supports Premium storage
	# $size = $vm.HardwareProfile.VmSize
	# Update-AzVM -VM $vm -ResourceGroupName $rgName

	# Get all disks in the resource group of the VM
	$vmDisks = Get-AzDisk -ResourceGroupName $rgName 

	# For disks that belong to the selected VM, convert to Premium storage
	foreach ($disk in $vmDisks)
	{
		if ($disk.ManagedBy -eq $vm.Id)
		{
			$disk.Sku = [Microsoft.Azure.Management.Compute.Models.DiskSku]::new($storageType)
			$disk | Update-AzDisk
		}
	}

	Start-AzVM -ResourceGroupName $rgName -Name $vmName
	
}
