# deploy-blueprint.ps1 - Interactive wizard for deploying workflow blueprints

param(
    [string]$BlueprintPath,
    [switch]$ListOnly
)

Write-Host "==================================" -ForegroundColor Cyan
Write-Host " n8n Blueprint Deployment Wizard  " -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

$blueprintDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "blueprints"

# Function to list all blueprints
function Get-Blueprints {
    $blueprints = @()
    Get-ChildItem -Path $blueprintDir -Filter "*.json" -Recurse | ForEach-Object {
        $relativePath = $_.FullName.Replace("$blueprintDir\", "").Replace("\", "/")
        $category = Split-Path (Split-Path $relativePath) -Leaf
        if ($category -eq "blueprints") { $category = "root" }

        $blueprints += [PSCustomObject]@{
            Name = $_.BaseName
            Category = $category
            Path = $_.FullName
            RelativePath = $relativePath
        }
    }
    return $blueprints
}

# List blueprints if requested
if ($ListOnly) {
    $blueprints = Get-Blueprints
    if ($blueprints.Count -eq 0) {
        Write-Host "No blueprints found in $blueprintDir" -ForegroundColor Yellow
        exit 0
    }

    Write-Host "Available Blueprints:" -ForegroundColor Green
    Write-Host ""
    $blueprints | Group-Object Category | ForEach-Object {
        Write-Host "[$($_.Name)]" -ForegroundColor Cyan
        $_.Group | ForEach-Object {
            Write-Host "  - $($_.Name)" -ForegroundColor White
        }
        Write-Host ""
    }
    exit 0
}

# If blueprint not specified, show interactive menu
if (-not $BlueprintPath) {
    $blueprints = Get-Blueprints

    if ($blueprints.Count -eq 0) {
        Write-Host "No blueprints found!" -ForegroundColor Red
        Write-Host "Add blueprint JSON files to: $blueprintDir" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "Select a blueprint to deploy:" -ForegroundColor Green
    Write-Host ""

    for ($i = 0; $i -lt $blueprints.Count; $i++) {
        $bp = $blueprints[$i]
        Write-Host "$($i + 1). [$($bp.Category)] $($bp.Name)" -ForegroundColor White
    }

    Write-Host ""
    do {
        $selection = Read-Host "Enter number (1-$($blueprints.Count))"
        $index = [int]$selection - 1
    } while ($index -lt 0 -or $index -ge $blueprints.Count)

    $selectedBlueprint = $blueprints[$index]
    $BlueprintPath = $selectedBlueprint.Path

    Write-Host ""
    Write-Host "Selected: $($selectedBlueprint.Name)" -ForegroundColor Green
}

# Verify blueprint exists
if (-not (Test-Path $BlueprintPath)) {
    Write-Host "Blueprint not found: $BlueprintPath" -ForegroundColor Red
    exit 1
}

# Load and display blueprint info
Write-Host ""
Write-Host "Loading blueprint..." -ForegroundColor Yellow
$blueprintJson = Get-Content $BlueprintPath -Raw
$blueprint = $blueprintJson | ConvertFrom-Json

Write-Host ""
Write-Host "Blueprint Details:" -ForegroundColor Cyan
Write-Host "  Name: $($blueprint.name)" -ForegroundColor White
Write-Host "  Nodes: $($blueprint.nodes.Count)" -ForegroundColor White

# Check for required credentials
$credentialNodes = $blueprint.nodes | Where-Object { $_.credentials }
if ($credentialNodes) {
    Write-Host ""
    Write-Host "Required Credentials:" -ForegroundColor Yellow
    $credentialNodes | ForEach-Object {
        $_.credentials.PSObject.Properties | ForEach-Object {
            Write-Host "  - $($_.Name): $($_.Value.name)" -ForegroundColor White
        }
    }
}

# Check for webhook nodes
$webhookNodes = $blueprint.nodes | Where-Object { $_.type -like "*webhook*" }
if ($webhookNodes) {
    Write-Host ""
    Write-Host "Webhook Endpoints:" -ForegroundColor Yellow
    $webhookNodes | ForEach-Object {
        Write-Host "  - $($_.name)" -ForegroundColor White
    }
    Write-Host "  Note: Configure webhook URLs after deployment" -ForegroundColor Gray
}

# Ask for customization
Write-Host ""
$customize = Read-Host "Customize workflow name? (y/N)"
if ($customize -eq "y" -or $customize -eq "Y") {
    $newName = Read-Host "Enter new workflow name"
    if ($newName) {
        $blueprint.name = $newName

        # Save customized version temporarily
        $tempFile = [System.IO.Path]::GetTempFileName()
        $blueprint | ConvertTo-Json -Depth 10 | Out-File $tempFile -Encoding UTF8
        $BlueprintPath = $tempFile
    }
}

# Ask for activation
Write-Host ""
$activate = Read-Host "Activate workflow after deployment? (y/N)"
$activateFlag = ($activate -eq "y" -or $activate -eq "Y")

# Deploy the blueprint
Write-Host ""
Write-Host "Deploying blueprint..." -ForegroundColor Yellow
Write-Host ""

$deployScript = Join-Path (Split-Path $PSScriptRoot) "workflows\apply-cli.ps1"

if ($activateFlag) {
    & $deployScript -WorkflowFile $BlueprintPath -Activate
} else {
    & $deployScript -WorkflowFile $BlueprintPath
}

# Clean up temp file if created
if ($tempFile -and (Test-Path $tempFile)) {
    Remove-Item $tempFile -Force
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Green
Write-Host "  Blueprint deployed successfully! " -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Open http://localhost:5678" -ForegroundColor White
Write-Host "2. Configure any required credentials" -ForegroundColor White
if ($webhookNodes) {
    Write-Host "3. Set up webhook endpoints" -ForegroundColor White
}
if (-not $activateFlag) {
    Write-Host "4. Activate the workflow when ready" -ForegroundColor White
}