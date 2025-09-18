# Start n8n Development Environment with MCP Support
# This script starts the n8n and n8n-mcp Docker containers for development

Write-Host "Starting n8n Development Environment with MCP..." -ForegroundColor Green

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
docker info > $null 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Docker is running" -ForegroundColor Green

# Start the services
Write-Host "Starting n8n and n8n-mcp containers..." -ForegroundColor Yellow
docker-compose up -d

# Check if command succeeded
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ n8n and n8n-mcp started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=== n8n Access ===" -ForegroundColor Cyan
    Write-Host "URL: http://localhost:5678" -ForegroundColor Cyan
    Write-Host "Username: admin" -ForegroundColor Gray
    Write-Host "Password: please-change-me" -ForegroundColor Gray
    Write-Host "API Token: cli-dev-token" -ForegroundColor Gray
    Write-Host ""
    Write-Host "=== n8n-MCP Access ===" -ForegroundColor Magenta
    Write-Host "HTTP URL: http://localhost:3003" -ForegroundColor Magenta
    Write-Host "Health Check: http://localhost:3003/health" -ForegroundColor Gray
    Write-Host "Mode: HTTP (for Claude Desktop integration)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To stop services, run: .\scripts\stop-n8n.ps1" -ForegroundColor Yellow
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to start services" -ForegroundColor Red
    exit 1
}
