# deploy-github-auto-sync.ps1 - Deploy GitHub to n8n auto-sync with upsert capability

param(
    [string]$RepositoryUrl,
    [string]$WebhookPath = "github-sync",
    [string]$BlueprintsPath = "blueprints/",
    [string]$DefaultBranch = "main",
    [switch]$UseImportOnly,
    [switch]$ShowComparison
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  GitHub → n8n Auto-Sync (Upsert) Deployment  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This enhanced workflow:" -ForegroundColor Green
Write-Host "  ✓ Creates new workflows from GitHub" -ForegroundColor White
Write-Host "  ✓ Updates existing workflows by name match" -ForegroundColor White
Write-Host "  ✓ Preserves workflow activation status" -ForegroundColor White
Write-Host "  ✓ Handles multiple files in single push" -ForegroundColor White
Write-Host ""

if ($ShowComparison) {
    Write-Host "=== Import vs Sync Comparison ===" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Auto-Import (Original):" -ForegroundColor Cyan
    Write-Host "  • Always creates new workflows" -ForegroundColor White
    Write-Host "  • Can result in duplicates" -ForegroundColor White
    Write-Host "  • Simple POST operation" -ForegroundColor White
    Write-Host ""
    Write-Host "Auto-Sync (Upsert):" -ForegroundColor Cyan
    Write-Host "  • Updates if name matches" -ForegroundColor White
    Write-Host "  • Creates if new" -ForegroundColor White
    Write-Host "  • Preserves workflow settings" -ForegroundColor White
    Write-Host "  • PUT or POST based on existence" -ForegroundColor White
    Write-Host ""
}

# Parse repository URL
$repoOwner = ""
$repoName = ""
if ($RepositoryUrl) {
    if ($RepositoryUrl -match "github\.com[:/]([^/]+)/([^/\.]+)") {
        $repoOwner = $matches[1]
        $repoName = $matches[2]
        Write-Host "Repository: $repoOwner/$repoName" -ForegroundColor White
    }
} else {
    Write-Host "=== Repository Configuration ===" -ForegroundColor Yellow
    $RepositoryUrl = Read-Host "Enter GitHub repository URL"

    if ($RepositoryUrl -match "github\.com[:/]([^/]+)/([^/\.]+)") {
        $repoOwner = $matches[1]
        $repoName = $matches[2]
    } else {
        Write-Host "Invalid repository URL format" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Sync Configuration ===" -ForegroundColor Yellow

$webhookPath = Read-Host "Webhook path [$WebhookPath]"
if (-not $webhookPath) { $webhookPath = $WebhookPath }

$blueprintsPath = Read-Host "Blueprints folder path [$BlueprintsPath]"
if (-not $blueprintsPath) { $blueprintsPath = $BlueprintsPath }

$defaultBranch = Read-Host "Default branch [$DefaultBranch]"
if (-not $defaultBranch) { $defaultBranch = $DefaultBranch }

Write-Host ""
Write-Host "=== n8n Configuration ===" -ForegroundColor Yellow

$n8nUrl = Read-Host "n8n instance URL [http://localhost:5678]"
if (-not $n8nUrl) { $n8nUrl = "http://localhost:5678" }

Write-Host ""
Write-Host "=== Credentials ===" -ForegroundColor Yellow
Write-Host "Create these in n8n UI (Settings → Credentials):" -ForegroundColor Gray

$githubCredId = Read-Host "GitHub API credential ID [github-api]"
if (-not $githubCredId) { $githubCredId = "github-api" }

$n8nCredId = Read-Host "n8n API credential ID [n8n-api]"
if (-not $n8nCredId) { $n8nCredId = "n8n-api" }

# Choose which blueprint to use
$blueprintId = if ($UseImportOnly) {
    "github-n8n-auto-import"
} else {
    "github-n8n-auto-sync-upsert"
}

Write-Host ""
Write-Host "Using blueprint: $blueprintId" -ForegroundColor Cyan

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
Write-Host "Generating workflow..." -ForegroundColor Green

$templateFile = if ($UseImportOnly) {
    "github-n8n-auto-import.json"
} else {
    "github-n8n-auto-sync-upsert.json"
}

$templatePath = Join-Path $PSScriptRoot "..\..\blueprints\integrations\$templateFile"
$workflowJson = Get-Content -Raw $templatePath

foreach ($key in $params.Keys) {
    $placeholder = "{{$key}}"
    $workflowJson = $workflowJson -replace [regex]::Escape($placeholder), $params[$key]
}

$workflow = $workflowJson | ConvertFrom-Json
$workflow.name = "GitHub Sync - $repoOwner/$repoName"

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
Write-Host "          Sync Workflow Deployed!              " -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Webhook URL:" -ForegroundColor Cyan
Write-Host $webhookUrl -ForegroundColor Yellow
Write-Host ""

# Create GitHub webhook setup instructions
$webhookInstructions = @"
GitHub Webhook Configuration
=============================

Repository: $repoOwner/$repoName
Webhook URL: $webhookUrl

Steps:
1. Go to: https://github.com/$repoOwner/$repoName/settings/hooks
2. Click 'Add webhook'
3. Configure:
   - Payload URL: $webhookUrl
   - Content type: application/json
   - Events: Just the push event
   - Active: ✓
4. Save webhook

Sync Behavior:
- Push to $blueprintsPath → Auto-sync to n8n
- New workflows → Created in n8n
- Existing workflows → Updated (matched by name)
- Activation status → Preserved on updates

Required Credentials in n8n:

1. GitHub API ($githubCredId)
   - Type: Header Auth
   - Name: Authorization
   - Value: Bearer YOUR_GITHUB_TOKEN

2. n8n API ($n8nCredId)
   - Type: Header Auth
   - Name: X-N8N-API-KEY
   - Value: YOUR_N8N_API_KEY

Testing:
1. Create/modify a workflow in $blueprintsPath
2. Commit and push to GitHub
3. Check n8n for updated workflow
"@

$setupFile = ".\github-sync-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$webhookInstructions | Out-File -FilePath $setupFile -Encoding UTF8

Write-Host "Setup instructions saved to: $setupFile" -ForegroundColor Green
Write-Host ""

Write-Host "Key Features:" -ForegroundColor Cyan
if (-not $UseImportOnly) {
    Write-Host "  • Smart Matching: Updates workflows with same name" -ForegroundColor White
    Write-Host "  • Preserves Settings: Keeps activation status" -ForegroundColor White
    Write-Host "  • No Duplicates: Won't create multiple versions" -ForegroundColor White
} else {
    Write-Host "  • Simple Import: Always creates new workflows" -ForegroundColor White
    Write-Host "  • Fast Processing: Direct POST operation" -ForegroundColor White
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Configure credentials in n8n" -ForegroundColor White
Write-Host "2. Activate the workflow" -ForegroundColor White
Write-Host "3. Add GitHub webhook" -ForegroundColor White
Write-Host "4. Test with a push to $blueprintsPath" -ForegroundColor White