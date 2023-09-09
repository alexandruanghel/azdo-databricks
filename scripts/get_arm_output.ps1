<#
Extracts a variable from the json ARM output.
It uses simple positional arguments.
Returns the variable value in the Azure Pipelines format (using the same variable name).
#>
Param(
    [Parameter(Mandatory = $True, Position = 1)] [string] $armOutputJson,
    [Parameter(Mandatory = $True, Position = 2)] [string] $varName
)

$armOutput = ConvertFrom-Json "$armOutputJson"
$value = $armOutput.$varName.value

If ( [string]::IsNullOrEmpty($value))
{
    throw "Variable value is NULL or EMPTY: " + $armOutputJson
    exit 1
}

Write-Host "##vso[task.setvariable variable=$varName;]$value"
