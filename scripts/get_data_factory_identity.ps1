<#
Retrieves the Azure Object ID of a Data Factory Managed Identity.
It uses simple positional arguments.
Returns the service principal client id as a variable called adfPrincipalId in the Azure Pipelines format.
Returns the service principal object id as a variable called adfObjectId in the Azure Pipelines format.
#>
Param(
  [Parameter(Mandatory=$True,Position=1)] [string] $resourceGroup,
  [Parameter(Mandatory=$True,Position=2)] [string] $dataFactoryName
)

# Get the Object ID of the Azure Data Factory Managed Identity (Identity.PrincipalId returns the Object ID)
$AzureDataFactory = Get-AzDataFactoryV2 -ResourceGroupName $resourceGroup -Name $dataFactoryName
$AzureDataFactoryObjectId = $AzureDataFactory.Identity.PrincipalId

If([string]::IsNullOrEmpty($AzureDataFactoryObjectId)){
  throw "AzureDataFactoryObjectId is NULL or EMPTY: " + $AzureDataFactory.DataFactoryId
  exit 1
}

# Get the Application ID from the Object ID
$AzureDataFactoryPrincipal = Get-AzADServicePrincipal -ObjectId $AzureDataFactoryObjectId
$AzureDataFactoryPrincipalId = $AzureDataFactoryPrincipal.AppId

If([string]::IsNullOrEmpty($AzureDataFactoryPrincipalId)){
  throw "AzureDataFactoryPrincipalId is NULL or EMPTY, Object ID: " + $AzureDataFactoryObjectId
  exit 1
}

Write-Host "##vso[task.setvariable variable=adfPrincipalId;]$AzureDataFactoryPrincipalId"
Write-Host "##vso[task.setvariable variable=adfObjectId;]$AzureDataFactoryObjectId"
