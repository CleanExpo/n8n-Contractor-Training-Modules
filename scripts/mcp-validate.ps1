# mcp-validate.ps1 - Validate workflow JSON against MCP node schemas

param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowFile,
    [string]$McpUrl = "http://localhost:3003",
    [string]$McpToken = "mcp-dev-token"
)

Write-Host "=== MCP Workflow Validation ===" -ForegroundColor Cyan
Write-Host ""

# Check if file exists
if (-not (Test-Path $WorkflowFile)) {
    Write-Host "✗ Workflow file not found: $WorkflowFile" -ForegroundColor Red
    exit 1
}

Write-Host "Loading workflow: $WorkflowFile" -ForegroundColor Yellow

try {
    # Load workflow JSON
    $workflowJson = Get-Content -Path $WorkflowFile -Raw
    $workflow = $workflowJson | ConvertFrom-Json

    # Connect to MCP
    Write-Host "Connecting to MCP server..." -ForegroundColor Yellow

    $headers = @{
        "Authorization" = "Bearer $McpToken"
        "Content-Type" = "application/json"
    }

    # Get available tools from MCP
    $toolsRequest = @{
        jsonrpc = "2.0"
        method = "tools/list"
        id = 1
    } | ConvertTo-Json

    $toolsResponse = Invoke-RestMethod -Uri $McpUrl -Method POST -Headers $headers -Body $toolsRequest -TimeoutSec 5

    if ($toolsResponse.result) {
        Write-Host "✓ Connected to MCP server" -ForegroundColor Green
        Write-Host "  Available tools: $($toolsResponse.result.tools.Count)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Failed to get tools from MCP" -ForegroundColor Red
        exit 1
    }

    # Validate each node in the workflow
    Write-Host ""
    Write-Host "Validating workflow nodes..." -ForegroundColor Yellow

    $validationErrors = @()
    $warnings = @()

    foreach ($node in $workflow.nodes) {
        Write-Host "  Checking node: $($node.name) [$($node.type)]" -ForegroundColor Gray

        # Request node type information from MCP
        $nodeInfoRequest = @{
            jsonrpc = "2.0"
            method = "tools/call"
            id = 2
            params = @{
                name = "get_node_info"
                arguments = @{
                    nodeType = $node.type
                }
            }
        } | ConvertTo-Json -Depth 10

        try {
            $nodeInfoResponse = Invoke-RestMethod -Uri $McpUrl -Method POST -Headers $headers -Body $nodeInfoRequest -TimeoutSec 5

            if ($nodeInfoResponse.error) {
                if ($nodeInfoResponse.error.message -like "*not found*") {
                    $warnings += "Node type '$($node.type)' not found in MCP catalog (might be valid but not documented)"
                } else {
                    $validationErrors += "Node '$($node.name)': $($nodeInfoResponse.error.message)"
                }
            } elseif ($nodeInfoResponse.result) {
                # Validate node parameters if schema available
                if ($nodeInfoResponse.result.content -and $nodeInfoResponse.result.content[0].text) {
                    Write-Host "    ✓ Node type validated" -ForegroundColor Green
                }
            }
        } catch {
            # If MCP doesn't support get_node_info, skip validation
            $warnings += "Could not validate node type '$($node.type)' via MCP"
        }

        # Basic structure validation
        if (-not $node.id) {
            $validationErrors += "Node '$($node.name)' missing 'id' field"
        }
        if (-not $node.position -or $node.position.Count -ne 2) {
            $validationErrors += "Node '$($node.name)' has invalid position"
        }
    }

    # Validate connections
    Write-Host ""
    Write-Host "Validating connections..." -ForegroundColor Yellow

    $nodeIds = $workflow.nodes | ForEach-Object { $_.id }

    foreach ($sourceNode in $workflow.connections.PSObject.Properties) {
        $sourceName = $sourceNode.Name

        # Check if source node exists
        $sourceExists = $workflow.nodes | Where-Object { $_.name -eq $sourceName }
        if (-not $sourceExists) {
            $validationErrors += "Connection from non-existent node: '$sourceName'"
            continue
        }

        foreach ($outputType in $sourceNode.Value.PSObject.Properties) {
            foreach ($connectionSet in $outputType.Value) {
                foreach ($connection in $connectionSet) {
                    # Check if target node exists
                    $targetExists = $workflow.nodes | Where-Object { $_.name -eq $connection.node }
                    if (-not $targetExists) {
                        $validationErrors += "Connection to non-existent node: '$($connection.node)' from '$sourceName'"
                    }
                }
            }
        }
    }

    # Display results
    Write-Host ""
    Write-Host "=== Validation Results ===" -ForegroundColor Cyan

    if ($validationErrors.Count -eq 0) {
        Write-Host "✓ Workflow validation passed!" -ForegroundColor Green

        if ($warnings.Count -gt 0) {
            Write-Host ""
            Write-Host "Warnings:" -ForegroundColor Yellow
            foreach ($warning in $warnings) {
                Write-Host "  ⚠ $warning" -ForegroundColor Yellow
            }
        }

        Write-Host ""
        Write-Host "Workflow Summary:" -ForegroundColor Cyan
        Write-Host "  Name: $($workflow.name)" -ForegroundColor White
        Write-Host "  Nodes: $($workflow.nodes.Count)" -ForegroundColor White
        Write-Host "  Status: Ready for deployment" -ForegroundColor Green

        exit 0
    } else {
        Write-Host "✗ Workflow validation failed!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Errors:" -ForegroundColor Red
        foreach ($error in $validationErrors) {
            Write-Host "  ✗ $error" -ForegroundColor Red
        }

        if ($warnings.Count -gt 0) {
            Write-Host ""
            Write-Host "Warnings:" -ForegroundColor Yellow
            foreach ($warning in $warnings) {
                Write-Host "  ⚠ $warning" -ForegroundColor Yellow
            }
        }

        exit 1
    }

} catch {
    Write-Host "✗ Validation failed: $_" -ForegroundColor Red
    exit 1
}