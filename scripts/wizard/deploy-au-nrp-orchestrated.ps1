# deploy-au-nrp-orchestrated.ps1 - Deploy AU NRP Contractor Onboarding (Orchestrated Version)

param(
    [string]$EnvironmentFile,
    [switch]$UseExistingEnv,
    [switch]$ShowDifferences
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  AU NRP Contractor Onboarding (Orchestrated)  " -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Streamlined workflow with:" -ForegroundColor Green
Write-Host "  ✓ Orchestrated validation" -ForegroundColor White
Write-Host "  ✓ Hemingway-style simplification" -ForegroundColor White
Write-Host "  ✓ AU compliance checking" -ForegroundColor White
Write-Host "  ✓ Automated content generation" -ForegroundColor White
Write-Host ""

if ($ShowDifferences) {
    Write-Host "=== Differences from Standard Version ===" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Standard Version:" -ForegroundColor Cyan
    Write-Host "  • 18 parameters required" -ForegroundColor White
    Write-Host "  • Complex multi-stage processing" -ForegroundColor White
    Write-Host "  • Full quiz and certification system" -ForegroundColor White
    Write-Host "  • Comprehensive logging" -ForegroundColor White
    Write-Host ""
    Write-Host "Orchestrated Version:" -ForegroundColor Cyan
    Write-Host "  • 9 parameters (simplified)" -ForegroundColor White
    Write-Host "  • Streamlined validation pipeline" -ForegroundColor White
    Write-Host "  • Focus on core compliance" -ForegroundColor White
    Write-Host "  • Owners-only access model" -ForegroundColor White
    Write-Host ""
}

# Check for environment file
if ($UseExistingEnv -and (Test-Path ".env")) {
    Write-Host "Using existing .env file" -ForegroundColor Green
    $EnvironmentFile = ".env"
} elseif (-not $EnvironmentFile) {
    Write-Host "=== Environment Configuration ===" -ForegroundColor Yellow
    Write-Host ""

    $setupScript = Join-Path $PSScriptRoot "..\setup-env.ps1"
    if (Test-Path $setupScript) {
        $createNew = Read-Host "Create new environment file? (Y/N) [Y]"
        if (-not $createNew -or $createNew -eq 'Y') {
            Write-Host "Running environment setup..." -ForegroundColor Green
            & $setupScript -Blueprint "au-nrp-orchestrated"
            $EnvironmentFile = ".env"
        }
    }
}

if (-not $EnvironmentFile -or -not (Test-Path $EnvironmentFile)) {
    Write-Host "Environment file required. Please create .env or specify with -EnvironmentFile" -ForegroundColor Red
    exit 1
}

# Load environment variables
Write-Host ""
Write-Host "Loading environment from: $EnvironmentFile" -ForegroundColor Cyan
Get-Content $EnvironmentFile | ForEach-Object {
    if ($_ -match '^([^#][^=]+)=(.+)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        [Environment]::SetEnvironmentVariable($key, $value, [EnvironmentVariableTarget]::Process)
    }
}

# Required parameters for orchestrated version
$requiredParams = @(
    "LLM_TEXT_API_URL",
    "LLM_TEXT_MODEL",
    "LLM_TEXT_CREDENTIAL_ID",
    "GEMINI_IMAGE_API_URL",
    "GEMINI_CREDENTIAL_ID",
    "GOOGLE_DOCS_CREDENTIAL_ID",
    "GOOGLE_DRIVE_CREDENTIAL_ID",
    "DRIVE_FOLDER_MANUALS",
    "DRIVE_FOLDER_ASSETS"
)

# Validate required parameters
Write-Host "Validating parameters..." -ForegroundColor Green
$missing = @()
foreach ($param in $requiredParams) {
    $value = [Environment]::GetEnvironmentVariable($param)
    if (-not $value) {
        $missing += $param
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing required parameters:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "Please update your environment file with these values" -ForegroundColor White
    exit 1
}

# Build parameters for replacement
$params = @{}
foreach ($param in $requiredParams) {
    $params[$param] = [Environment]::GetEnvironmentVariable($param)
}

# Process template
Write-Host ""
Write-Host "Generating workflow from blueprint..." -ForegroundColor Green

$templatePath = Join-Path (Join-Path $PSScriptRoot "..\..") "blueprints\integrations\au-nrp-contractor-onboarding-orchestrated.json"
if (-not (Test-Path $templatePath)) {
    Write-Host "Blueprint not found: $templatePath" -ForegroundColor Red
    exit 1
}

$workflowJson = Get-Content -Raw $templatePath

# Replace placeholders
foreach ($key in $params.Keys) {
    $placeholder = "{{$key}}"
    $workflowJson = $workflowJson -replace [regex]::Escape($placeholder), $params[$key]
}

# Parse and update workflow name if needed
$workflow = $workflowJson | ConvertFrom-Json
$businessName = [Environment]::GetEnvironmentVariable("BUSINESS_NAME")
if ($businessName) {
    $workflow.name = "AU NRP Onboarding (Orchestrated) - $businessName"
}

# Save to temporary file
$tempFile = [System.IO.Path]::GetTempFileName()
$tempFile = [System.IO.Path]::ChangeExtension($tempFile, ".json")
$workflow | ConvertTo-Json -Depth 10 | Out-File $tempFile -Encoding UTF8

Write-Host "Deploying to n8n..." -ForegroundColor Green
Write-Host ""

# Deploy using CLI method
$deployScript = Join-Path $PSScriptRoot "..\workflows\apply-cli.ps1"
if (Test-Path $deployScript) {
    & $deployScript -WorkflowFile $tempFile
} else {
    Write-Host "Deploy script not found: $deployScript" -ForegroundColor Red
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    exit 1
}

# Clean up temp file
Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "     Orchestrated Workflow Deployed!            " -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Key Features Deployed:" -ForegroundColor Cyan
Write-Host "  • Parallel fetching from AU compliance sites" -ForegroundColor White
Write-Host "  • Hemingway 4th-grade simplification" -ForegroundColor White
Write-Host "  • Orchestra validation for AU compliance" -ForegroundColor White
Write-Host "  • Google Docs manual generation" -ForegroundColor White
Write-Host "  • Gemini image generation" -ForegroundColor White
Write-Host "  • Drive asset management" -ForegroundColor White
Write-Host ""

Write-Host "Required Credentials in n8n:" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. LLM API ($($params['LLM_TEXT_CREDENTIAL_ID'])):" -ForegroundColor Yellow
Write-Host "   - Type: Header Auth" -ForegroundColor Gray
Write-Host "   - Configure for your LLM provider" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Gemini API ($($params['GEMINI_CREDENTIAL_ID'])):" -ForegroundColor Yellow
Write-Host "   - Type: Header Auth" -ForegroundColor Gray
Write-Host "   - Configure for Gemini image API" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Google OAuth2 Credentials:" -ForegroundColor Yellow
Write-Host "   - Docs: $($params['GOOGLE_DOCS_CREDENTIAL_ID'])" -ForegroundColor Gray
Write-Host "   - Drive: $($params['GOOGLE_DRIVE_CREDENTIAL_ID'])" -ForegroundColor Gray
Write-Host ""

Write-Host "Google Drive Folders Required:" -ForegroundColor Cyan
Write-Host "  • Manuals: $($params['DRIVE_FOLDER_MANUALS'])" -ForegroundColor White
Write-Host "  • Assets: $($params['DRIVE_FOLDER_ASSETS'])" -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Configure all credentials in n8n UI" -ForegroundColor White
Write-Host "2. Verify Google Drive folder permissions" -ForegroundColor White
Write-Host "3. Test LLM and Gemini API connections" -ForegroundColor White
Write-Host "4. Activate the workflow" -ForegroundColor White
Write-Host "5. Run manual test with Start Trigger" -ForegroundColor White

# Save setup details
$setupDetails = @"
AU NRP Contractor Onboarding (Orchestrated) - Setup Details
==========================================================

Deployed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Environment: $EnvironmentFile

Workflow Features:
- Orchestrated validation pipeline
- Hemingway-style content simplification
- AU-specific compliance checking
- Automated document generation
- Image generation with Gemini

Parameters Used:
- LLM API URL: $($params['LLM_TEXT_API_URL'])
- LLM Model: $($params['LLM_TEXT_MODEL'])
- Gemini API URL: $($params['GEMINI_IMAGE_API_URL'])
- Manuals Folder: $($params['DRIVE_FOLDER_MANUALS'])
- Assets Folder: $($params['DRIVE_FOLDER_ASSETS'])

Orchestra Validation Rules:
- Australian English spelling
- AU-only compliance (no OSHA/imperial)
- Fact checking enabled
- Content validation

Testing Checklist:
[ ] All credentials configured
[ ] Google Drive access verified
[ ] LLM API responding
[ ] Gemini API working
[ ] Workflow activated
[ ] Test run completed
"@

$setupFile = ".\au-nrp-orchestrated-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$setupDetails | Out-File -FilePath $setupFile -Encoding UTF8

Write-Host ""
Write-Host "Setup details saved to: $setupFile" -ForegroundColor Green