# n8n-api.ps1 - Core API helper functions for n8n workflow management

param(
    [string]$BaseUrl = "http://localhost:5678",
    [string]$ApiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2MDk1YzQzOS1hYWY5LTQwNDYtYTM4MS0wYzNmN2JhYzNlMDYiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzU4MTk4MDQ4fQ.yMUoTSifG4com_XWti8p1wLtgJFAURptOjhO_Ol0M84"
)

# Configuration
$script:N8nBaseUrl = $BaseUrl
$script:N8nApiToken = $ApiToken
$script:ApiVersion = "v1"

function Get-N8nHeaders {
    return @{
        "X-N8N-API-KEY" = $script:N8nApiToken
        "Content-Type" = "application/json"
        "Accept" = "application/json"
    }
}

function Invoke-N8nApi {
    param(
        [string]$Endpoint,
        [string]$Method = "GET",
        [object]$Body = $null,
        [hashtable]$AdditionalHeaders = @{}
    )

    $uri = "$script:N8nBaseUrl/api/$script:ApiVersion/$Endpoint"
    $headers = Get-N8nHeaders
    foreach ($key in $AdditionalHeaders.Keys) {
        $headers[$key] = $AdditionalHeaders[$key]
    }

    $params = @{
        Uri = $uri
        Method = $Method
        Headers = $headers
    }

    if ($Body) {
        if ($Body -is [string]) {
            $params.Body = $Body
        } else {
            $params.Body = $Body | ConvertTo-Json -Depth 10
        }
    }

    try {
        $response = Invoke-RestMethod @params
        return $response
    } catch {
        Write-Error "API Request Failed: $_"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Error "Response: $responseBody"
        }
        throw
    }
}

# Workflow Functions
function Get-N8nWorkflows {
    param(
        [switch]$Active,
        [string]$Name
    )

    $endpoint = "workflows"
    $workflows = Invoke-N8nApi -Endpoint $endpoint

    if ($Active) {
        $workflows = $workflows.data | Where-Object { $_.active -eq $true }
    }

    if ($Name) {
        $workflows = $workflows.data | Where-Object { $_.name -like "*$Name*" }
    }

    return $workflows
}

function Get-N8nWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    return Invoke-N8nApi -Endpoint "workflows/$Id"
}

function New-N8nWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        [object]$WorkflowData
    )

    # Ensure required fields
    if (-not $WorkflowData.name) {
        $WorkflowData.name = "New Workflow"
    }
    if (-not $WorkflowData.nodes) {
        $WorkflowData.nodes = @()
    }
    if (-not $WorkflowData.connections) {
        $WorkflowData.connections = @{}
    }

    return Invoke-N8nApi -Endpoint "workflows" -Method POST -Body $WorkflowData
}

function Update-N8nWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [object]$WorkflowData
    )

    return Invoke-N8nApi -Endpoint "workflows/$Id" -Method PUT -Body $WorkflowData
}

function Remove-N8nWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    return Invoke-N8nApi -Endpoint "workflows/$Id" -Method DELETE
}

function Start-N8nWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [switch]$Activate
    )

    if ($Activate) {
        $body = @{ active = $true }
        return Invoke-N8nApi -Endpoint "workflows/$Id" -Method PATCH -Body $body
    } else {
        return Invoke-N8nApi -Endpoint "workflows/$Id/activate" -Method POST
    }
}

function Stop-N8nWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    $body = @{ active = $false }
    return Invoke-N8nApi -Endpoint "workflows/$Id" -Method PATCH -Body $body
}

# Execution Functions
function Get-N8nExecutions {
    param(
        [string]$WorkflowId,
        [int]$Limit = 10
    )

    $endpoint = "executions"
    if ($WorkflowId) {
        $endpoint += "?workflowId=$WorkflowId&limit=$Limit"
    } else {
        $endpoint += "?limit=$Limit"
    }

    return Invoke-N8nApi -Endpoint $endpoint
}

function Get-N8nExecution {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    return Invoke-N8nApi -Endpoint "executions/$Id"
}

function Start-N8nExecution {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        [object]$Data = @{}
    )

    $body = @{
        workflowData = @{ id = $WorkflowId }
        data = $Data
    }

    return Invoke-N8nApi -Endpoint "workflows/$WorkflowId/run" -Method POST -Body $body
}

# Credential Functions
function Get-N8nCredentials {
    return Invoke-N8nApi -Endpoint "credentials"
}

function Get-N8nCredentialTypes {
    return Invoke-N8nApi -Endpoint "credential-types"
}

# Node Functions
function Get-N8nNodeTypes {
    return Invoke-N8nApi -Endpoint "node-types"
}

function Get-N8nNodeType {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type
    )

    $encodedType = [System.Web.HttpUtility]::UrlEncode($Type)
    return Invoke-N8nApi -Endpoint "node-types/$encodedType"
}

# Utility Functions
function Test-N8nConnection {
    try {
        $workflows = Get-N8nWorkflows
        Write-Host "Connected to n8n API" -ForegroundColor Green
        Write-Host "  Found $($workflows.Count) workflows" -ForegroundColor Gray
        return $true
    } catch {
        Write-Host "Failed to connect to n8n API" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        return $false
    }
}

function Export-N8nWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $workflow = Get-N8nWorkflow -Id $Id
    $workflow | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
    Write-Host "Exported workflow to: $Path" -ForegroundColor Green
}

function Import-N8nWorkflow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [switch]$Activate
    )

    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }

    $workflowJson = Get-Content -Path $Path -Raw
    $workflowData = $workflowJson | ConvertFrom-Json

    # Remove ID to create new workflow
    if ($workflowData.id) {
        $workflowData.PSObject.Properties.Remove('id')
    }

    if ($Activate) {
        $workflowData.active = $true
    }

    $result = New-N8nWorkflow -WorkflowData $workflowData
    Write-Host "Imported workflow: $($result.name) (ID: $($result.id))" -ForegroundColor Green
    return $result
}

# Functions are available through dot sourcing