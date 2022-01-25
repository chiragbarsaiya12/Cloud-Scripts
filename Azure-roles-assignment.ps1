Start-Transcript -Path <Transcript path>

$RG = Read-Host " Please Enter the ResourceGroupName"

$adgroupname = Read-Host " Please Enter the AD Group Name"
$adgroup = (Get-AzADGroup -SearchString $adgroupname).Id

$appname = Read-Host " Please Enter the Service Principal Name"
$app = (Get-AzADServicePrincipal -SearchString $appname).Id

$roles = Get-Content "<roles list>"

ForEach ($roles in $roles)

{

New-AzRoleAssignment -ObjectId $adgroup `
-RoleDefinitionName "$roles" `
-ResourceGroupName "$RG"


New-AzRoleAssignment -ObjectId $app `
-RoleDefinitionName "$roles" `
-ResourceGroupName "$RG"

}Stop-Transcript
