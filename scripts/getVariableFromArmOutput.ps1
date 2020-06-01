$armOutput = $args[0]
$varName = $args[1]

$var = ConvertFrom-Json "$armOutput"
$value = $var.$varName.value

If([string]::IsNullOrEmpty($value)){            
  throw "value is NULL or EMPTY."
  exit 1
}

Write-Host "##vso[task.setvariable variable=$varName;]$value"
