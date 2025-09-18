# Start n8n Development Environment
# This script starts the n8n Docker container for development

Write-Host "Starting n8n Development Environment..." -ForegroundColor Green

# Check if Docker is running
Write-Host "Checking Docker..." -ForegroundColor Yellow
docker info > $null 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Docker is not running. Please start Docker Desktop first." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Docker is running" -ForegroundColor Green

# Start the services
Write-Host "Starting n8n container..." -ForegroundColor Yellow
docker-compose up -d

# Check if command succeeded
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ n8n started successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access n8n at: http://localhost:5678" -ForegroundColor Cyan
    Write-Host "Username: admin" -ForegroundColor Gray
    Write-Host "Password: please-change-me" -ForegroundColor Gray
    Write-Host ""
    Write-Host "API Token: cli-dev-token" -ForegroundColor Gray
    Write-Host ""
    Write-Host "To stop n8n, run: .\scripts\stop-n8n.ps1" -ForegroundColor Yellow
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ Failed to start n8n" -ForegroundColor Red
    exit 1
}
