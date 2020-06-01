$adbResourceGroup = $args[0]
$dataFactoryName =$args[1]

$AzureDataFactory = Get-AzDataFactoryV2 -ResourceGroupName $adbResourceGroup -Name $dataFactoryName
$AzureDataFactoryManagedIdentity = $AzureDataFactory.Identity.PrincipalId

If([string]::IsNullOrEmpty($AzureDataFactoryManagedIdentity)){            
  throw "AzureDataFactoryManagedIdentity is NULL or EMPTY."
  exit 1
}

Write-Host "##vso[task.setvariable variable=adfObjectId;]$AzureDataFactoryManagedIdentity"
