
# exit to prevent full runs when accidentally clicking "Run Script"
exit


# lots of different versions of azure command line floating around...
# use this one: https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest

# following examples here: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm
# requires az --version to be 2.0.30 or greater.

# https://docs.microsoft.com/en-us/cli/azure/vm?view=azure-cli-latest#az-vm-create
# using cloud init: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/using-cloud-init

# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-virtual-network

##########
# set params
##########

$subId = "5893168b-6ec8-462d-b595-3516adb763cc"
$rgName = "dev-dfp-try-eus2-01-rg"

$vmImage = "UbuntuLTS" # try Canonical:UbuntuServer:18.04-LTS:18.04.201901220  https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
$vmBaseName = "statefulModel"
$vmAdminName = "azureuser"
$location = "eastus2"
$vmSize = "Standard_A2_v2"
$adminUsername = "azureuser"

$ipName = "statefulModelPublicIPAddress"
$vnetName = "statefulModelVnet"
$vnetPrefix = "10.0.0.0/16"
$frontendSubnetName = "statefulModelFrontendSubnet"
$frontendSubnetPrefix = "10.0.1.0/24"
$backendSubnetName = "statefulModelBackendSubnet"
$backendSubnetPrefix = "10.0.2.0/24"

$nsgName = "statefulModelNsg"
$nsgSshRuleName = "statefulModelSshRule"




##########
# set up infrastructure
##########

#$context = Get-AzSubscription -SubscriptionId $subId
#Set-AzContext $context
#
#$rg = Get-AzResourceGroup -name $rgName

az login
az account set --subscription $subId
#az group list


# need to create a vnet and subnet...


#$agSubnetConfig = New-AzVirtualNetworkSubnetConfig `
#  -Name $frontendSubnetName `
#  -AddressPrefix $frontendPrefix
#$backendSubnetConfig = New-AzVirtualNetworkSubnetConfig `
#  -Name $backendSubnetName `
#  -AddressPrefix $backendPrefix
#$vnet = New-AzVirtualNetwork `
#  -ResourceGroupName $rg.ResourceGroupName `
#  -Location $location `
#  -Name $vnetName `
#  -AddressPrefix $vnetPrefix `
#  -Subnet $agSubnetConfig, $backendSubnetConfig
#$pubIp = New-AzPublicIpAddress `
#  -ResourceGroupName $rg.ResourceGroupName `
#  -Location $location `
#  -Name $ipName `
#  -AllocationMethod Static

# CAUTION: subnets that are auto-created will have the default (?) Network Security Group

az network nsg create `
    --resource-group $rgName `
    --name $nsgName

az network nsg rule create `
    --resource-group $rgName `
    --nsg-name $nsgName `
    --name $nsgSshRuleName `
    --priority 1000 `
    --source-address-prefixes "*" `
    --source-port-ranges "*" `
    --destination-address-prefixes "*" `
    --destination-port-ranges 22 `
    --access Allow `
    --protocol Tcp `
    --description "Allow ssh on port 22."

az network vnet create `
    --resource-group $rgName `
    --name $vnetName `
    --address-prefix $vnetPrefix

az network vnet subnet create `
    --resource-group $rgName `
    --vnet-name $vnetName `
    --name $frontendSubnetName `
    --address-prefix $frontendSubnetPrefix `
    --network-security-group $nsgName

az network vnet subnet create `
    --resource-group $rgName `
    --vnet-name $vnetName `
    --name $backendSubnetName `
    --address-prefix $backendSubnetPrefix `
    --network-security-group $nsgName

az network public-ip create `
    --resource-group $rgName `
    --name $ipName `
    --allocation-method static

az network public-ip create `
    --resource-group $rgName `
    --name "${ipName}02" `
    --allocation-method static


##########
# create vms
##########

# creates a disk?
# creates a network security group?
# creates a NIC?
az vm create `
    --resource-group $rgName `
    --name "${vmBaseName}11" `
    --vnet-name $vnetName `
    --subnet $frontendSubnetName `
    --nsg $nsgName `
    --public-ip-address "${ipName}" `
    --image $vmImage `
    --size $vmSize `
    --admin-username $adminUsername `
    --custom-data "C:\GitRepos\serve-stateful-model\cloud-init.txt" `
    --generate-ssh-keys # not sure where these are stored...


    C:\GitRepos\serve-stateful-model\cloud-init.txt
