
# exit to prevent full runs on accidentally clicking "Run Script"
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

# dfp dev
#$subId = "5893168b-6ec8-462d-b595-3516adb763cc"
#$rgName = "dev-dfp-try-eus2-01-rg"

# dfp int
#$subId = "bda494f3-04c5-47db-97b5-590c78b003a5"
#$rgName = "dfptry-compute-eastus2-int-rg"

# ato sandbox
$subId = "1f4c6f4d-ff85-46a8-93da-0080f4b66543"
$rgName = "chrodger-dev00"

$vmImage = "UbuntuLTS" # try Canonical:UbuntuServer:18.04-LTS:18.04.201901220  https://docs.microsoft.com/en-us/azure/virtual-machines/linux/cli-ps-findimage
$vmBaseName = "statefulModel"
$location = "westus2"
#$vmSize = "Standard_A2_v2"
#$vmSize = "Standard_A4_v2"
$vmSize = "Standard_DS3_v2"
$adminUsername = "azureuser"
$cloudInitPath = "C:\Users\chrodger\OneDrive - Microsoft\stateful-model\cloud-init.txt"

$ipName = "statefulModelPublicIPAddress"
$vnetName = "statefulModelVnet"
$vnetPrefix = "10.0.0.0/16"
$frontendSubnetName = "statefulModelFrontendSubnet"
$frontendSubnetPrefix = "10.0.1.0/24"
$backendSubnetName = "statefulModelBackendSubnet"
$backendSubnetPrefix = "10.0.2.0/24"

$nsgName = "statefulModelNsg"
$nsgSshRuleName = "statefulModelSshRule"
$appRuleName = "statefulModelAppRule"

$scaleSetName = "statefulModelScaleSet"
$loadBalancerRuleName = "statefulModelLBAllowAppTraffic"

$scaleSetPublicIpName = "statefulModelScaleSetPublicIp"
$scaleSetLoadBalancerName = "statefulModelScaleSetLoadBalancer"
$scaleSetBackendPoolName = "statefulModelBackendPool"
$scaleSetFrontendPoolName = "statefulModelFrontendPool"

$appPort = "8034"




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
    --name $nsgName `
    --location $location


# There is some service in my resource group that is auto-detecting and blocking SSH on 22.
# I've put a command in cloud-init.txt that will set the SSH port to 8022 and restart the sshd service.
#az network nsg rule create `
#    --resource-group $rgName `
#    --nsg-name $nsgName `
#    --name $nsgSshRuleName `
#    --priority 1000 `
#    --source-address-prefixes "*" `
#    --source-port-ranges "*" `
#    --destination-address-prefixes "*" `
#    --destination-port-ranges 8022 `
#    --access Allow `
#    --protocol Tcp `
#    --description "Allow ssh on port 8022."
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

# allow traffic through to the app
az network nsg rule create `
    --resource-group $rgName `
    --nsg-name $nsgName `
    --name $appRuleName `
    --priority 1001 `
    --source-address-prefixes "*" `
    --source-port-ranges "*" `
    --destination-address-prefixes "*" `
    --destination-port-ranges 8034 `
    --access Allow `
    --protocol Tcp `
    --description "Allow traffic through to the app."

az network vnet create `
    --resource-group $rgName `
    --name $vnetName `
    --address-prefix $vnetPrefix `
    --location $location

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
    --name ${ipName}00 `
    --allocation-method static

az network public-ip create `
    --resource-group $rgName `
    --name "${ipName}01" `
    --allocation-method static

az network public-ip create `
    --resource-group $rgName `
    --name "${ipName}02" `
    --allocation-method static


##########
# create single vm (use for benchmarking?)
##########

# creates a disk?
# creates a network security group?
# creates a NIC?
az vm create `
    --resource-group $rgName `
    --name "${vmBaseName}01" `
    --vnet-name $vnetName `
    --subnet $frontendSubnetName `
    --nsg $nsgName `
    --public-ip-address "${ipName}01" `
    --image $vmImage `
    --size $vmSize `
    --admin-username $adminUsername `
    --custom-data $cloudInitPath `
    --generate-ssh-keys # this is using a public/private key pair that lives in ~/.ssh (git bash)

    
##########
# create vm scale set
##########

# create a load balancer?

# create the vms
az vmss create `
  --resource-group $rgName `
  --name $scaleSetName `
  --image $vmImage `
  --upgrade-policy-mode automatic `
  --custom-data $cloudInitPath `
  --admin-username $adminUsername `
  --instance-count 2 `
  --vm-sku $vmSize `
  --vnet-name $vnetName `
  --subnet $frontendSubnetName `
  --public-ip-address $scaleSetPublicIpName `
  --load-balancer $scaleSetLoadBalancerName `
  --backend-pool-name $scaleSetFrontendPoolName `
  --generate-ssh-keys
  # network security group? - no NSG?
  # ip address? - made its own... will set my own name later
  # load balancer? - created a load balancer... will set my own name later
  # backend-pool? - created a backend pool ("statefulModelScaleSetLBBEPool"), but it is not listed in resource group as a resource... can also set my own name for this


az network lb rule create `
  --resource-group $rgName `
  --name $loadBalancerRuleName `
  --lb-name $scaleSetLoadBalancerName `
  --frontend-port $appPort `
  --backend-pool-name $scaleSetFrontendPoolName `
  --backend-port $appPort `
  --protocol tcp

  #--frontend-ip-name "statefulModelScaleSetLBPublicIP" ` # this was required in the docs, but gives an error when run? possible version mismatch...


#az network lb show `
#    --resource-group $rgName `
#    --name "statefulModelScaleSetLB" 
