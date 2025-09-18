# manifest-deploy.ps1 - Deploy blueprints using manifest definitions

param(
    [string]$BlueprintId,
    [hashtable]$Parameters,
    [switch]$ListBlueprints,
    [switch]$Interactive
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  Manifest-Based Blueprint Deployer  " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$blueprintDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "blueprints"
$manifestPath = Join-Path $blueprintDir "manifest.json"

# Load manifest
if (-not (Test-Path $manifestPath)) {
    Write-Host "Manifest not found at: $manifestPath" -ForegroundColor Red
    exit 1
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

# List blueprints if requested
if ($ListBlueprints) {
    Write-Host "Available Blueprints (v$($manifest.version)):" -ForegroundColor Green
    Write-Host ""

    $manifest.blueprints | ForEach-Object {
        Write-Host "[$($_.id)]" -ForegroundColor Cyan
        Write-Host "  Name: $($_.name)" -ForegroundColor White
        Write-Host "  Description: $($_.description)" -ForegroundColor Gray
        Write-Host "  Parameters: $($_.params -join ', ')" -ForegroundColor Gray
        if ($_.credentials.Count -gt 0) {
            Write-Host "  Required Credentials: $($_.credentials -join ', ')" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    exit 0
}

# Interactive mode
if ($Interactive -or -not $BlueprintId) {
    Write-Host "Select a blueprint:" -ForegroundColor Green
    Write-Host ""

    for ($i = 0; $i -lt $manifest.blueprints.Count; $i++) {
        $bp = $manifest.blueprints[$i]
        Write-Host "$($i + 1). $($bp.name)" -ForegroundColor White
        Write-Host "    $($bp.description)" -ForegroundColor Gray
    }

    Write-Host ""
    do {
        $selection = Read-Host "Enter number (1-$($manifest.blueprints.Count))"
        $index = [int]$selection - 1
    } while ($index -lt 0 -or $index -ge $manifest.blueprints.Count)

    $blueprint = $manifest.blueprints[$index]
} else {
    # Find blueprint by ID
    $blueprint = $manifest.blueprints | Where-Object { $_.id -eq $BlueprintId } | Select-Object -First 1
    if (-not $blueprint) {
        Write-Host "Blueprint '$BlueprintId' not found!" -ForegroundColor Red
        Write-Host "Use -ListBlueprints to see available options" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "Selected: $($blueprint.name)" -ForegroundColor Green
Write-Host ""

# Load the workflow template
$workflowPath = Join-Path $blueprintDir $blueprint.workflow
if (-not (Test-Path $workflowPath)) {
    Write-Host "Workflow file not found: $workflowPath" -ForegroundColor Red
    exit 1
}

$workflowJson = Get-Content $workflowPath -Raw
$workflow = $workflowJson | ConvertFrom-Json

# Collect parameters
if (-not $Parameters) {
    $Parameters = @{}
}

Write-Host "Configure Parameters:" -ForegroundColor Cyan
Write-Host ""

foreach ($param in $blueprint.params) {
    if (-not $Parameters.ContainsKey($param)) {
        # Check if metadata exists for this parameter
        $paramMeta = $null
        if ($workflow.meta -and $workflow.meta.parameters) {
            $paramMeta = $workflow.meta.parameters.$param
        }

        if ($paramMeta) {
            Write-Host "$param`:" -ForegroundColor Yellow
            if ($paramMeta.description) {
                Write-Host "  $($paramMeta.description)" -ForegroundColor Gray
            }
            if ($paramMeta.example) {
                Write-Host "  Example: $($paramMeta.example)" -ForegroundColor DarkGray
            }

            $prompt = "  Enter value"
            if ($paramMeta.default) {
                $prompt += " [$($paramMeta.default)]"
            }
            $value = Read-Host $prompt

            if (-not $value -and $paramMeta.default) {
                $value = $paramMeta.default
            }
        } else {
            $value = Read-Host "Enter value for $param"
        }

        $Parameters[$param] = $value
    }
}

# Replace parameters in workflow
$workflowString = $workflowJson
foreach ($param in $Parameters.Keys) {
    $placeholder = "{{$param}}"
    $value = $Parameters[$param]
    $workflowString = $workflowString -replace [regex]::Escape($placeholder), $value
}

# Parse back to validate
try {
    $workflow = $workflowString | ConvertFrom-Json
} catch {
    Write-Host "Error processing workflow template: $_" -ForegroundColor Red
    exit 1
}

# Update workflow name if desired
Write-Host ""
$customName = Read-Host "Custom workflow name (or press Enter for default)"
if ($customName) {
    $workflow.name = $customName
}

# Save processed workflow
$tempFile = [System.IO.Path]::GetTempFileName()
$tempFile = [System.IO.Path]::ChangeExtension($tempFile, ".json")
$workflow | ConvertTo-Json -Depth 10 | Out-File $tempFile -Encoding UTF8

Write-Host ""
Write-Host "Deploying workflow..." -ForegroundColor Yellow

# Check for required credentials
if ($blueprint.credentials.Count -gt 0) {
    Write-Host ""
    Write-Host "Required Credentials:" -ForegroundColor Yellow
    $blueprint.credentials | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Note: Configure these in n8n after deployment" -ForegroundColor Gray
}

# Deploy the workflow
$deployScript = Join-Path (Split-Path $PSScriptRoot) "workflows\apply-cli.ps1"

Write-Host ""
$activate = Read-Host "Activate workflow after deployment? (y/N)"

if ($activate -eq "y" -or $activate -eq "Y") {
    & $deployScript -WorkflowFile $tempFile -Activate
} else {
    & $deployScript -WorkflowFile $tempFile
}

# Clean up
Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "   Blueprint Deployed Successfully!  " -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "Blueprint: $($blueprint.name)" -ForegroundColor White
Write-Host "Workflow: $($workflow.name)" -ForegroundColor White

if ($blueprint.credentials.Count -gt 0) {
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Open http://localhost:5678" -ForegroundColor White
    Write-Host "2. Configure required credentials" -ForegroundColor White
    Write-Host "3. Test the workflow" -ForegroundColor White
}

# Show webhook URL if applicable
if ($Parameters.ContainsKey("WEBHOOK_PATH")) {
    Write-Host ""
    Write-Host "Webhook URL:" -ForegroundColor Cyan
    Write-Host "http://localhost:5678/webhook/$($Parameters['WEBHOOK_PATH'])" -ForegroundColor Yellow
    Write-Host "(Production URL will be different)" -ForegroundColor Gray
}