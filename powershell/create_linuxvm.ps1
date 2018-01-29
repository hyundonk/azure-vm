# powershelll script for creating Ubuntu 16.04-LTS VM 
# Make sure to call login-AzureRmAccount first before running this script.

param (
     [Parameter(Mandatory=$true)][string]$username,
     [string]$publicKeyPath,
     [string]$rgname,
     [string]$location,
     [string]$vnetname,
     [string]$vnetaddress,
     [string]$subnetname,
     [string]$subnetaddress,
     [string]$nsgname,
     [string]$nicname,
     [string]$vmsize,
     [string]$vmname,
     [string]$publisherName,
     [string]$offer,
     [string]$skus,
     [string]$acceleratedNetworking
)

if(!$publicKeyPath){
    echo "publicKeyPath is not given. Using default value($env:USERPROFILE\.ssh\id_rsa.pub)"
    $publicKeyPath = "$env:USERPROFILE\.ssh\id_rsa.pub"
}

if(!$rgname){
    $rgname = "myTestRG"
}

if(!$vmname){
    $vmname = "myLinuxVM"
}

if(!$location){
    $location = "Korea Central"
}

if(!$vnetname){
    $vnetname = "myVNet1"
}

if(!$vnetaddress){
    $vnetaddress = "10.100.0.0/16"
}

if(!$subnetname){
    $subnetname = "default"
}

if(!$subnetaddress){
    $subnetaddress = "10.100.0.0/24"
}

if(!$nsgname){
    $nsgname = "myNSG1"
}

if(!$nicname){
    $nicname = "myNIC1"
}

if(!$vmsize){
    $vmsize = "Standard_DS2_v2"
}

if(!$vmsize){
    $vmsize = "Standard_DS2_v2"
}

if(!$publisherName){
    $publisherName = "Canonical"
#   $publisherName = "OpenLogic"
}

if(!$offer){
    $offer = "UbuntuServer"
#   $offer = "CentOS"
}

if(!$skus){
    $skus = "16.04-LTS"
#   $skus = "7.4"
}

# login-AzureRmAccount

# Create resource group
$rg = Get-AzureRmResourceGroup -Name $rgname -erroraction 'silentlycontinue'
if($rg){
    $rg
}
else{
    New-AzureRmResourceGroup -Name $rgname -Location $location
}

# Create VNet if not yet created
$vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $rgname -erroraction 'silentlycontinue'
if($vnet){
    $vnet
}
else{
    $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetname -AddressPrefix $subnetaddress
    $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgname -Location $location -Name $vnetname -AddressPrefix $vnetaddress -Subnet $subnetConfig
}

# Create an inbound network security group rule for RDP
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgname -Name $nsgname -erroraction 'silentlycontinue'
if($nsg){
    $nsg
}
else{
    $nsgRuleSSH = New-AzureRmNetworkSecurityRuleConfig -Name NSGRuleSSH  -Protocol Tcp -Direction Inbound -Priority 1002 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22 -Access Allow

    $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgname -Location $location -Name $nsgname -SecurityRules $nsgRuleSSH
}

# Create "static" Public IP & NIC
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $rgname -Location $location -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "mypublicdns$(Get-Random)"

if(!$acceleratedNetworkinge){

    $nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName  $rgname -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id 
}
else{
    $nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName  $rgname -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id -EnableAcceleratedNetworking
}

# Define a credential object
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

# Create a virtual machine configuration with public key
$vmConfig = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize | `
Set-AzureRmVMOperatingSystem -Linux -ComputerName $vmname -Credential $cred -DisablePasswordAuthentication | `
Set-AzureRmVMSourceImage -PublisherName $publisherName -Offer $offer -Skus $skus -Version latest | `
Add-AzureRmVMNetworkInterface -Id $nic.Id

# Use ssh public key for authentication
$sshPublicKey = Get-Content $publicKeyPath

Add-AzureRmVMSshPublicKey -VM $vmconfig -KeyData $sshPublicKey -Path "/home/$username/.ssh/authorized_keys"

New-AzureRmVM -ResourceGroupName $rgname -Location $location -VM $vmConfig
