# deploy-github-auto-import.ps1 - Deploy GitHub to n8n auto-import workflow

param(
    [string]$RepositoryUrl,
    [string]$WebhookPath = "github-push",
    [string]$BlueprintsPath = "blueprints/",
    [string]$DefaultBranch = "main",
    [switch]$ShowWebhookSetup
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  GitHub → n8n Auto-Import Workflow Deployment " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This workflow automatically imports blueprint" -ForegroundColor Green
Write-Host "workflows when pushed to your GitHub repository" -ForegroundColor Green
Write-Host ""

# Parse repository URL if provided
$repoOwner = ""
$repoName = ""
if ($RepositoryUrl) {
    if ($RepositoryUrl -match "github\.com[:/]([^/]+)/([^/\.]+)") {
        $repoOwner = $matches[1]
        $repoName = $matches[2]
        Write-Host "Repository: $repoOwner/$repoName" -ForegroundColor White
    }
}

# Collect configuration
if (-not $RepositoryUrl) {
    Write-Host "=== Repository Configuration ===" -ForegroundColor Yellow
    $RepositoryUrl = Read-Host "Enter GitHub repository URL (e.g., https://github.com/owner/repo)"

    if ($RepositoryUrl -match "github\.com[:/]([^/]+)/([^/\.]+)") {
        $repoOwner = $matches[1]
        $repoName = $matches[2]
    } else {
        Write-Host "Invalid repository URL format" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Webhook Configuration ===" -ForegroundColor Yellow

$webhookPath = Read-Host "Webhook path [$WebhookPath]"
if (-not $webhookPath) { $webhookPath = $WebhookPath }

$blueprintsPath = Read-Host "Blueprints folder path in repo [$BlueprintsPath]"
if (-not $blueprintsPath) { $blueprintsPath = $BlueprintsPath }

$defaultBranch = Read-Host "Default branch [$DefaultBranch]"
if (-not $defaultBranch) { $defaultBranch = $DefaultBranch }

Write-Host ""
Write-Host "=== n8n Configuration ===" -ForegroundColor Yellow

$n8nUrl = Read-Host "n8n instance URL [http://localhost:5678]"
if (-not $n8nUrl) { $n8nUrl = "http://localhost:5678" }

Write-Host ""
Write-Host "=== Credential IDs ===" -ForegroundColor Yellow
Write-Host "You'll need to create these in n8n UI:" -ForegroundColor Gray

$githubCredId = Read-Host "GitHub API credential ID [github-api]"
if (-not $githubCredId) { $githubCredId = "github-api" }

$n8nCredId = Read-Host "n8n API credential ID [n8n-api]"
if (-not $n8nCredId) { $n8nCredId = "n8n-api" }

# Build parameters
$params = @{
    "WEBHOOK_PATH" = $webhookPath
    "DEFAULT_BRANCH" = $defaultBranch
    "BLUEPRINTS_PATH" = $blueprintsPath
    "N8N_BASE_URL" = $n8nUrl
    "GITHUB_CREDENTIAL_ID" = $githubCredId
    "N8N_API_CREDENTIAL_ID" = $n8nCredId
}

# Process template
Write-Host ""
Write-Host "Generating workflow..." -ForegroundColor Green

$templatePath = Join-Path $PSScriptRoot "..\..\blueprints\integrations\github-n8n-auto-import.json"
$workflowJson = Get-Content -Raw $templatePath

foreach ($key in $params.Keys) {
    $placeholder = "{{$key}}"
    $workflowJson = $workflowJson -replace [regex]::Escape($placeholder), $params[$key]
}

$workflow = $workflowJson | ConvertFrom-Json
$workflow.name = "GitHub Auto-Import - $repoOwner/$repoName"

# Save and deploy
$tempFile = [System.IO.Path]::GetTempFileName()
$tempFile = [System.IO.Path]::ChangeExtension($tempFile, ".json")
$workflow | ConvertTo-Json -Depth 10 | Out-File $tempFile -Encoding UTF8

Write-Host "Deploying to n8n..." -ForegroundColor Green
$deployScript = Join-Path $PSScriptRoot "..\workflows\apply-cli.ps1"
& $deployScript -WorkflowFile $tempFile

Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

# Calculate webhook URL
$webhookUrl = "$n8nUrl/webhook/$webhookPath"

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "        Deployment Complete!                    " -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Webhook URL:" -ForegroundColor Cyan
Write-Host $webhookUrl -ForegroundColor Yellow
Write-Host ""

if ($ShowWebhookSetup) {
    Write-Host "=== GitHub Webhook Setup Instructions ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Go to: https://github.com/$repoOwner/$repoName/settings/hooks" -ForegroundColor White
    Write-Host "2. Click 'Add webhook'" -ForegroundColor White
    Write-Host "3. Configure:" -ForegroundColor White
    Write-Host "   - Payload URL: $webhookUrl" -ForegroundColor Yellow
    Write-Host "   - Content type: application/json" -ForegroundColor Yellow
    Write-Host "   - Events: Just the push event" -ForegroundColor Yellow
    Write-Host "   - Active: ✓" -ForegroundColor Yellow
    Write-Host "4. Click 'Add webhook'" -ForegroundColor White
    Write-Host ""
}

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Open n8n at $n8nUrl" -ForegroundColor White
Write-Host "2. Create credentials:" -ForegroundColor White
Write-Host "   - GitHub API Token ($githubCredId):" -ForegroundColor Yellow
Write-Host "     • Type: Header Auth" -ForegroundColor Gray
Write-Host "     • Name: Authorization" -ForegroundColor Gray
Write-Host "     • Value: Bearer YOUR_GITHUB_TOKEN" -ForegroundColor Gray
Write-Host "   - n8n API Token ($n8nCredId):" -ForegroundColor Yellow
Write-Host "     • Type: Header Auth" -ForegroundColor Gray
Write-Host "     • Name: X-N8N-API-KEY" -ForegroundColor Gray
Write-Host "     • Value: YOUR_N8N_API_KEY" -ForegroundColor Gray
Write-Host "3. Activate the workflow" -ForegroundColor White
Write-Host "4. Add webhook in GitHub repository settings" -ForegroundColor White
Write-Host ""
Write-Host "How it works:" -ForegroundColor Gray
Write-Host "• Push blueprints to $blueprintsPath in your repo" -ForegroundColor Gray
Write-Host "• GitHub sends webhook to n8n" -ForegroundColor Gray
Write-Host "• n8n automatically imports new/updated workflows" -ForegroundColor Gray

# Create setup instructions file
$setupDoc = @"
GitHub Webhook Configuration for $repoOwner/$repoName
=====================================================

Webhook URL: $webhookUrl

GitHub Repository Settings:
- URL: https://github.com/$repoOwner/$repoName/settings/hooks
- Payload URL: $webhookUrl
- Content type: application/json
- Secret: (optional, add if needed)
- SSL verification: Enable
- Events: Just the push event
- Active: Yes

Required n8n Credentials:

1. GitHub API Token ($githubCredId)
   - Create at: https://github.com/settings/tokens
   - Scopes needed: repo (full control)
   - In n8n: Settings > Credentials > Add Credential > Header Auth
   - Header Name: Authorization
   - Header Value: Bearer YOUR_TOKEN

2. n8n API Key ($n8nCredId)
   - Create in n8n UI: Settings > API
   - In n8n: Settings > Credentials > Add Credential > Header Auth
   - Header Name: X-N8N-API-KEY
   - Header Value: YOUR_API_KEY

Testing:
1. Ensure workflow is active in n8n
2. Push a .json file to $blueprintsPath/ in your repo
3. Check n8n executions for import status
"@

$setupFile = ".\github-webhook-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$setupDoc | Out-File -FilePath $setupFile -Encoding UTF8

Write-Host ""
Write-Host "Setup instructions saved to: $setupFile" -ForegroundColor Green