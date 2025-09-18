param(
  [string]$BlueprintId = "github-to-sheets"
)

$bpIndexPath = Join-Path $PSScriptRoot "..\..\blueprints\manifest.json"
if (!(Test-Path $bpIndexPath)) { throw "Blueprint index not found: $bpIndexPath" }

$index = Get-Content -Raw $bpIndexPath | ConvertFrom-Json
$bp = $index.blueprints | Where-Object { $_.id -eq $BlueprintId }
if (!$bp) { throw "Blueprint '$BlueprintId' not found in index." }

Write-Host "Selected blueprint: $($bp.name)" -ForegroundColor Cyan
Write-Host "Description: $($bp.description)" -ForegroundColor Gray
Write-Host "Params required: $($bp.params -join ', ')" -ForegroundColor Yellow

if ($bp.credentials.Count -gt 0) {
    Write-Host "Credentials needed: $($bp.credentials -join ', ')" -ForegroundColor Magenta
}

Write-Host ""
Write-Host "Next step: Collecting parameter values..." -ForegroundColor Green

# Collect parameters
$params = @{}
$templatePath = Join-Path $PSScriptRoot "..\..\blueprints\$($bp.workflow)"

if (!(Test-Path $templatePath)) {
    throw "Template file not found: $templatePath"
}

# Load template to get parameter metadata
$template = Get-Content -Raw $templatePath | ConvertFrom-Json

Write-Host ""
foreach ($paramName in $bp.params) {
    $paramMeta = $null
    if ($template.meta -and $template.meta.parameters) {
        $paramMeta = $template.meta.parameters.$paramName
    }

    if ($paramMeta -and $paramMeta.description) {
        Write-Host "$paramName - $($paramMeta.description)" -ForegroundColor Yellow
        if ($paramMeta.example) {
            Write-Host "  Example: $($paramMeta.example)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host $paramName -ForegroundColor Yellow
    }

    $prompt = "Enter value"
    if ($paramMeta -and $paramMeta.default) {
        $prompt += " [$($paramMeta.default)]"
    }

    $value = Read-Host $prompt
    if (!$value -and $paramMeta -and $paramMeta.default) {
        $value = $paramMeta.default
    }

    if (!$value -and $paramMeta -and $paramMeta.required) {
        throw "Required parameter '$paramName' cannot be empty"
    }

    $params[$paramName] = $value
}

# Process template with parameters
Write-Host ""
Write-Host "Generating workflow from template..." -ForegroundColor Green
$workflowJson = Get-Content -Raw $templatePath

foreach ($key in $params.Keys) {
    $placeholder = "{{$key}}"
    $workflowJson = $workflowJson -replace [regex]::Escape($placeholder), $params[$key]
}

# Parse and customize workflow
$workflow = $workflowJson | ConvertFrom-Json

Write-Host ""
$defaultName = $workflow.name
$customName = Read-Host "Custom workflow name (Enter to use default: '$defaultName')"
if ($customName) {
    $workflow.name = $customName
}

# Save to temp file
$tempFile = [System.IO.Path]::GetTempFileName()
$tempFile = [System.IO.Path]::ChangeExtension($tempFile, ".json")
$workflow | ConvertTo-Json -Depth 10 | Out-File $tempFile -Encoding UTF8

Write-Host ""
Write-Host "Deploying workflow to n8n..." -ForegroundColor Green

# Deploy using CLI
$deployScript = Join-Path $PSScriptRoot "..\workflows\apply-cli.ps1"
& $deployScript -WorkflowFile $tempFile

# Clean up
Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "Blueprint deployed successfully!" -ForegroundColor Green
Write-Host "Workflow: $($workflow.name)" -ForegroundColor White

if ($params.ContainsKey("WEBHOOK_PATH")) {
    Write-Host ""
    Write-Host "Webhook endpoint will be available at:" -ForegroundColor Cyan
    Write-Host "http://localhost:5678/webhook/$($params['WEBHOOK_PATH'])" -ForegroundColor Yellow
}

if ($bp.credentials.Count -gt 0) {
    Write-Host ""
    Write-Host "Remember to configure credentials in n8n UI:" -ForegroundColor Magenta
    foreach ($cred in $bp.credentials) {
        Write-Host "  - $cred"
    }
}