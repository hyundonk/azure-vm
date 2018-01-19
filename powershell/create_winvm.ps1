# powershelll script for creating Windows 2016 Datacenter VM 
# Make sure to call login-AzureRmAccount first before running this script.

$rgname="myTestRG"
$vmname="myWinVM"
$Location= "Korea Central"
$vnetname = "myVNet2"
$vnetaddress = "10.100.0.0/16"
$subnetname = "default"
$subnetaddress = "10.100.0.0/24"
$nsgname = "myNsg"
$nicname = "myNIC"
$vmsize = "Standard_DS2_v2"

# login-AzureRmAccount

# Create resource group
$rg = Get-AzureRmResourceGroup -Name $rgname -erroraction 'silentlycontinue'
if($rg){
    $rg
}
else{
    New-AzureRmResourceGroup -Name $rgname -Location $Location
}

# Create VNet if not yet created
$vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $rgname -erroraction 'silentlycontinue'
if($vnet){
    $vnet
}
else{
    $subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnetname -AddressPrefix $subnetaddress
    $vnet = New-AzureRmVirtualNetwork -ResourceGroupName $rgname -Location $Location -Name $vnetname -AddressPrefix $vnetaddress -Subnet $subnetConfig
}

# Create an inbound network security group rule for RDP
$nsg = Get-AzureRmNetworkSecurityGroup -ResourceGroupName $rgname -Name $nsgname -erroraction 'silentlycontinue'
if($nsg){
    $nsg
}
else{
    $nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name NSGRuleRDP  -Protocol Tcp -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389 -Access Allow

    $nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $rgname -Location $Location -Name $nsgname -SecurityRules $nsgRuleRDP
}

# Create "static" Public IP & NIC
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $rgname -Location $Location -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "mypublicdns$(Get-Random)"

$nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName  $rgname -Location $Location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -NetworkSecurityGroupId $nsg.Id

# Ask to input credential
$cred = Get-Credential

$vm = New-AzureRmVMConfig -VMName $vmname -VMSize $vmsize
$vm = Set-AzureRmVMOperatingSystem -VM $vm -Windows -ComputerName $vmname -Credential $cred -ProvisionVMAgent -EnableAutoUpdate

$vm = Set-AzureRmVMSourceImage -VM $vm -PublisherName MicrosoftWindowsServer -Offer WindowsServer -Skus 2016-Datacenter -Version latest

$vm = Set-AzureRmVMOSDisk -VM $vm -Name myOsDisk -DiskSizeInGB 128 -CreateOption FromImage -Caching ReadWrite

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id

New-AzureRmVM -ResourceGroupName $rgname -Location $Location -VM $vm

