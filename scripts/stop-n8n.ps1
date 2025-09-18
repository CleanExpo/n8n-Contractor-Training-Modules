# Stop n8n Development Environment
# This script stops the n8n Docker container

Write-Host "Stopping n8n Development Environment..." -ForegroundColor Yellow

# Stop the services
docker-compose down

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ n8n stopped successfully!" -ForegroundColor Green
} else {
    Write-Host "✗ Failed to stop n8n" -ForegroundColor Red
    exit 1
}
