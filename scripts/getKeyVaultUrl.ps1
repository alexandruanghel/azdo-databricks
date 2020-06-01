$keyVaultName = $args[0]

$AzureKeyVault = Get-AzKeyVault -VaultName $keyVaultName
$VaultUri = $AzureKeyVault.VaultUri

If([string]::IsNullOrEmpty($VaultUri)){            
  throw "VaultUri is NULL or EMPTY."
  exit 1
}

Write-Host "##vso[task.setvariable variable=keyVaultUrl;]$VaultUri"
