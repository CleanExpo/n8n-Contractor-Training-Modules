# apply.ps1 - Deploy workflow JSON files to n8n

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowFile,
    [string]$N8nUrl = "http://localhost:5678",
    [string]$ApiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2MDk1YzQzOS1hYWY5LTQwNDYtYTM4MS0wYzNmN2JhYzNlMDYiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzU4MTk4MDQ4fQ.yMUoTSifG4com_XWti8p1wLtgJFAURptOjhO_Ol0M84",
    [switch]$Activate,
    [switch]$ValidateOnly
)

# Import API helper module
$scriptRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. "$scriptRoot\scripts\n8n-api.ps1" -BaseUrl $N8nUrl -ApiToken $ApiToken

Write-Host "=== n8n Workflow Apply ===" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $WorkflowFile)) {
    Write-Host "X Workflow file not found: $WorkflowFile" -ForegroundColor Red
    exit 1
}

Write-Host "Loading workflow from: $WorkflowFile" -ForegroundColor Yellow

try {
    # Load and parse workflow JSON
    $workflowJson = Get-Content -Path $WorkflowFile -Raw
    $workflow = $workflowJson | ConvertFrom-Json

    # Validate workflow structure
    Write-Host "Validating workflow structure..." -ForegroundColor Yellow

    $validationErrors = @()

    if (-not $workflow.name) {
        $validationErrors += "Missing 'name' field"
    }

    if (-not $workflow.nodes) {
        $validationErrors += "Missing 'nodes' field"
    } elseif ($workflow.nodes.Count -eq 0) {
        $validationErrors += "Workflow has no nodes"
    }

    if (-not $workflow.connections) {
        $validationErrors += "Missing 'connections' field"
    }

    # Validate nodes
    foreach ($node in $workflow.nodes) {
        if (-not $node.name) {
            $validationErrors += "Node missing 'name' field"
        }
        if (-not $node.type) {
            $validationErrors += "Node '$($node.name)' missing 'type' field"
        }
        if (-not $node.position) {
            $validationErrors += "Node '$($node.name)' missing 'position' field"
        }
    }

    if ($validationErrors.Count -gt 0) {
        Write-Host "X Validation failed:" -ForegroundColor Red
        foreach ($error in $validationErrors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
        exit 1
    }

    Write-Host "OK Workflow validation passed" -ForegroundColor Green

    if ($ValidateOnly) {
        Write-Host ""
        Write-Host "Validation complete (-ValidateOnly flag set)" -ForegroundColor Cyan
        exit 0
    }

    # Test API connection
    Write-Host "Testing n8n API connection..." -ForegroundColor Yellow
    if (-not (Test-N8nConnection)) {
        Write-Host "X Cannot connect to n8n API at: $N8nUrl" -ForegroundColor Red
        exit 1
    }

    # Check if workflow already exists
    $existingWorkflows = Get-N8nWorkflows -Name $workflow.name
    $existingWorkflow = $existingWorkflows | Where-Object { $_.name -eq $workflow.name } | Select-Object -First 1

    if ($existingWorkflow) {
        Write-Host "Workflow '$($workflow.name)' already exists (ID: $($existingWorkflow.id))" -ForegroundColor Yellow
        Write-Host "Updating existing workflow..." -ForegroundColor Yellow

        # Preserve the ID for update
        $workflow | Add-Member -NotePropertyName "id" -NotePropertyValue $existingWorkflow.id -Force

        # Set activation state
        if ($Activate) {
            $workflow.active = $true
        } else {
            $workflow.active = $existingWorkflow.active
        }

        $result = Update-N8nWorkflow -Id $existingWorkflow.id -WorkflowData $workflow
        Write-Host "OK Workflow updated successfully" -ForegroundColor Green
    } else {
        Write-Host "Creating new workflow: $($workflow.name)" -ForegroundColor Yellow

        # Remove ID if present (for new workflows)
        if ($workflow.id) {
            $workflow.PSObject.Properties.Remove('id')
        }

        # Set activation state
        if ($Activate) {
            $workflow.active = $true
        }

        $result = New-N8nWorkflow -WorkflowData $workflow
        Write-Host "OK Workflow created successfully (ID: $($result.id))" -ForegroundColor Green
    }

    # Display workflow status
    Write-Host ""
    Write-Host "=== Workflow Details ===" -ForegroundColor Cyan
    Write-Host "Name: $($result.name)" -ForegroundColor White
    Write-Host "ID: $($result.id)" -ForegroundColor White
    $activeColor = if ($result.active) { "Green" } else { "Yellow" }
    Write-Host "Active: $($result.active)" -ForegroundColor $activeColor
    Write-Host "Nodes: $($result.nodes.Count)" -ForegroundColor White
    Write-Host "Created: $($result.createdAt)" -ForegroundColor Gray
    Write-Host "Updated: $($result.updatedAt)" -ForegroundColor Gray

    if ($result.active) {
        Write-Host ""
        Write-Host "OK Workflow is active and ready to run!" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "Note: Workflow is not active. Use -Activate flag to activate it." -ForegroundColor Yellow
    }

} catch {
    Write-Host "X Failed to apply workflow: $_" -ForegroundColor Red
    exit 1
}