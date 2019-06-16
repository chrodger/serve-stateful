
# following load balancer example here: https://docs.microsoft.com/en-us/azure/application-gateway/quick-create-powershell
# also, deploying from git repo: https://docs.microsoft.com/en-us/azure/app-service/scripts/powershell-deploy-local-git?toc=%2fpowershell%2fmodule%2ftoc.json
# https://docs.microsoft.com/en-us/azure/app-service/containers/quickstart-python
# https://docs.microsoft.com/en-us/azure/app-service/samples-powershell

# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/sizes

# az vm run command: https://docs.microsoft.com/en-us/cli/azure/vm/run-command?view=azure-cli-latest#az-vm-run-command-invoke
# limitations of azure linux vm startup command: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/run-command

# AG: application gateway

# switch to linux vms? they have another scaling walkthrough...
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-manage-vm

$context = get-azsubscription -SubscriptionId 5893168b-6ec8-462d-b595-3516adb763cc
set-azcontext $context

$agSubnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name statefulModelAGSubnet `
  -AddressPrefix 10.0.1.0/24
$backendSubnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name statefulModelBackendSubnet `
  -AddressPrefix 10.0.2.0/24
New-AzVirtualNetwork `
  -ResourceGroupName dev-dfp-try-eus2-01-rg `
  -Location eastus2 `
  -Name statefulModelVNet `
  -AddressPrefix 10.0.0.0/16 `
  -Subnet $agSubnetConfig, $backendSubnetConfig
New-AzPublicIpAddress `
  -ResourceGroupName dev-dfp-try-eus2-01-rg `
  -Location eastus2 `
  -Name statefulModelAGPublicIPAddress `
  -AllocationMethod Dynamic

$rg = Get-AzResourceGroup -name dev-dfp-try-eus2-01-rg
$sp = Get-AzAppServicePlan -name ASP-devdfptryeus201rg-95d2
$wa = Get-AzWebApp -ResourceGroupName dev-dfp-try-eus2-01-rg -Name stateful-model-00 

#$PropertiesObject = @{
#    repoUrl="https://github.com/chrodger/serve-stateful-model";
#    branch="master";
#    isManualIntegration="true";
#}
##Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName $rg -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName $webappname/web -ApiVersion 2015-08-01 -Force
#Set-AzResource -PropertyObject $PropertiesObject -ResourceGroupName dev-dfp-try-eus2-01-rg -ResourceType Microsoft.Web/sites/sourcecontrols -ResourceName stateful-model-00/web -ApiVersion 2015-08-01 -Force

$vnet   = Get-AzVirtualNetwork -ResourceGroupName dev-dfp-try-eus2-01-rg -Name statefulModelVNet
$subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name statefulModelBackendSubnet
$cred = Get-Credential

  $nic = New-AzNetworkInterface `
    -Name statefulModlNic00 `
    -ResourceGroupName dev-dfp-try-eus2-01-rg `
    -Location eastus2 `
    -SubnetId $subnet.Id
  $vm = New-AzVMConfig `
    -VMName statefulModelVM00 `
    -VMSize Standard_A2_v2
  Set-AzVMOperatingSystem `
    -VM $vm `
    -Linux `
    -ComputerName statefulModelVMName00$i `
    -Credential $cred
  Set-AzVMSourceImage `
    -VM $vm `
    -PublisherName MicrosoftWindowsServer `
    -Offer WindowsServer `
    -Skus 2016-Datacenter `
    -Version latest
  Add-AzVMNetworkInterface `
    -VM $vm `
    -Id $nic.Id
  Set-AzVMBootDiagnostic `
    -VM $vm `
    -Disable
  New-AzVM -ResourceGroupName myResourceGroupAG -Location EastUS -VM $vm
  Set-AzVMExtension `
    -ResourceGroupName myResourceGroupAG `
    -ExtensionName IIS `
    -VMName myVM$i `
    -Publisher Microsoft.Compute `
    -ExtensionType CustomScriptExtension `
    -TypeHandlerVersion 1.4 `
    -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
    -Location EastUS





