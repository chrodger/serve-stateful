
# exit to prevent accidental running of entire script
exit

#. $PSScriptRoot\common.ps1


# Create a multi-master Azure Cosmos Account for Cassandra API with a keyspace with shared  
# throughput, and a table with dedicated throughput with last writer wins conflict resolution policy
$resourceGroupName = "dev-dfp-try-eus2-01-rg"
$location = "eastus2"
$accountName = "statefulmodelcosmosaccount" # must be lower case.
$keyspaceName = "keyspace1"
$keyspaceResourceName = $accountName + "/cassandra/" + $keyspaceName


# Create account
$locations = @(
    @{ "locationName"="East US 2"; "failoverPriority"=0 },
    @{ "locationName"="West US 2"; "failoverPriority"=1 }
)

$consistencyPolicy = @{
    "defaultConsistencyLevel"="BoundedStaleness";
    "maxIntervalInSeconds"=300;
    "maxStalenessPrefix"=100000
}

$accountProperties = @{
    "capabilities"= @( @{ "name"="EnableCassandra" } );
    "databaseAccountOfferType"="Standard";
    "locations"=$locations;
    "consistencyPolicy"=$consistencyPolicy;
    "enableMultipleWriteLocations"="true"
}

New-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName -Location $location `
    -Kind "GlobalDocumentDB" -Name $accountName -PropertyObject $accountProperties


# Create keyspace with shared throughput
$keyspaceProperties = @{
    "resource"=@{ "id"=$keyspaceName };
    "options"=@{ "Throughput"= 400 }
}
New-AzResource -ResourceType "Microsoft.DocumentDb/databaseAccounts/apis/keyspaces" `
    -ApiVersion "2015-04-08" -ResourceGroupName $resourceGroupName `
    -Name $keyspaceResourceName -PropertyObject $keyspaceProperties
