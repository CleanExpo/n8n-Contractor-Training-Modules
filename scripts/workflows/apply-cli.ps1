# apply-cli.ps1 - Deploy workflow using n8n CLI inside container

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowFile,
    [switch]$Activate
)

Write-Host "=== n8n Workflow Deploy (CLI Method) ===" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $WorkflowFile)) {
    Write-Host "X Workflow file not found: $WorkflowFile" -ForegroundColor Red
    exit 1
}

# Get absolute path
$absolutePath = (Resolve-Path $WorkflowFile).Path
$fileName = Split-Path $WorkflowFile -Leaf

Write-Host "Copying workflow to container..." -ForegroundColor Yellow

# Copy workflow file to container
docker cp "$absolutePath" "n8ncontractortrainingmodules-n8n-1:/tmp/$fileName"

if ($LASTEXITCODE -ne 0) {
    Write-Host "X Failed to copy workflow file to container" -ForegroundColor Red
    exit 1
}

Write-Host "Importing workflow..." -ForegroundColor Yellow

# Import workflow using n8n CLI
$importOutput = docker exec n8ncontractortrainingmodules-n8n-1 n8n import:workflow --input="/tmp/$fileName" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "X Failed to import workflow" -ForegroundColor Red
    Write-Host $importOutput -ForegroundColor Red
    exit 1
}

Write-Host "OK Workflow imported successfully!" -ForegroundColor Green
Write-Host $importOutput

# Extract workflow ID from output if available
$workflowId = $null
if ($importOutput -match "id[:\s]+(\w+)") {
    if ($matches -and $matches.Count -gt 1) {
        $workflowId = $matches[1]
    }
}

# Activate workflow if requested
if ($Activate -and $workflowId) {
    Write-Host ""
    Write-Host "Activating workflow..." -ForegroundColor Yellow

    $activateOutput = docker exec n8ncontractortrainingmodules-n8n-1 n8n update:workflow --id=$workflowId --active=true 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "OK Workflow activated!" -ForegroundColor Green
    } else {
        Write-Host "Warning: Could not activate workflow automatically" -ForegroundColor Yellow
        Write-Host "Please activate it manually in the UI" -ForegroundColor Yellow
    }
}

# Clean up
docker exec n8ncontractortrainingmodules-n8n-1 rm "/tmp/$fileName" 2>$null

Write-Host ""
Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
Write-Host "View your workflow at: http://localhost:5678" -ForegroundColor White