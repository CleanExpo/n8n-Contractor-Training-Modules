# smoke.ps1 - Health check script for n8n and n8n-mcp services

param(
    [string]$N8nUrl = "http://localhost:5678",
    [string]$McpUrl = "http://localhost:3003",
    [string]$ApiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2MDk1YzQzOS1hYWY5LTQwNDYtYTM4MS0wYzNmN2JhYzNlMDYiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzU4MTk4MDQ4fQ.yMUoTSifG4com_XWti8p1wLtgJFAURptOjhO_Ol0M84",
    [string]$McpToken = "mcp-dev-token"
)

Write-Host "=== n8n-MCP Integration Smoke Test ===" -ForegroundColor Cyan
Write-Host ""

$exitCode = 0

# Test 1: n8n service health
Write-Host "[1/4] Checking n8n service..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$N8nUrl/healthz" -Method GET -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✓ n8n service is healthy" -ForegroundColor Green
    } else {
        Write-Host "  ✗ n8n service returned status: $($response.StatusCode)" -ForegroundColor Red
        $exitCode = 1
    }
} catch {
    Write-Host "  ✗ n8n service is not accessible: $_" -ForegroundColor Red
    $exitCode = 1
}

# Test 2: n8n API authentication
Write-Host "[2/4] Checking n8n API authentication..." -ForegroundColor Yellow
try {
    $headers = @{
        "X-N8N-API-KEY" = $ApiToken
    }
    $response = Invoke-RestMethod -Uri "$N8nUrl/api/v1/workflows" -Method GET -Headers $headers -TimeoutSec 5
    Write-Host "  ✓ n8n API authentication successful" -ForegroundColor Green
    Write-Host "    Found $($response.data.Count) workflows" -ForegroundColor Gray
} catch {
    Write-Host "  ✗ n8n API authentication failed: $_" -ForegroundColor Red
    $exitCode = 1
}

# Test 3: MCP service health
Write-Host "[3/4] Checking MCP service..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$McpUrl/health" -Method GET -UseBasicParsing -TimeoutSec 5
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✓ MCP service is healthy" -ForegroundColor Green
    } else {
        Write-Host "  ✗ MCP service returned status: $($response.StatusCode)" -ForegroundColor Red
        $exitCode = 1
    }
} catch {
    Write-Host "  ✗ MCP service is not accessible: $_" -ForegroundColor Red
    $exitCode = 1
}

# Test 4: MCP API connectivity
Write-Host "[4/4] Checking MCP API connectivity..." -ForegroundColor Yellow
try {
    $headers = @{
        "Authorization" = "Bearer $McpToken"
        "Content-Type" = "application/json"
    }
    $body = @{
        jsonrpc = "2.0"
        method = "tools/list"
        id = 1
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$McpUrl" -Method POST -Headers $headers -Body $body -TimeoutSec 5
    if ($response.result) {
        Write-Host "  ✓ MCP API connectivity successful" -ForegroundColor Green
        Write-Host "    Available tools: $($response.result.tools.Count)" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ MCP API returned unexpected response" -ForegroundColor Red
        $exitCode = 1
    }
} catch {
    Write-Host "  ✗ MCP API connectivity failed: $_" -ForegroundColor Red
    $exitCode = 1
}

Write-Host ""
Write-Host "=== Smoke Test Summary ===" -ForegroundColor Cyan
if ($exitCode -eq 0) {
    Write-Host "All tests passed! ✓" -ForegroundColor Green
} else {
    Write-Host "Some tests failed! ✗" -ForegroundColor Red
    Write-Host "Please check your Docker containers are running:" -ForegroundColor Yellow
    Write-Host "  docker-compose ps" -ForegroundColor Gray
}

exit $exitCode