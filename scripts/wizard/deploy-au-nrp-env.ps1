# deploy-au-nrp-env.ps1 - Deploy AU NRP workflow using environment variables

param(
    [string]$EnvFile = ".env",
    [string]$BusinessName,
    [switch]$UseDefaults
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " AU NRP Deployment (Environment Config)  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Load environment variables
function Load-EnvFile {
    param([string]$Path)

    $env = @{}
    if (Test-Path $Path) {
        Get-Content $Path | Where-Object { $_ -match '^\s*([^#][^=]+)=(.*)$' } | ForEach-Object {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim()
            $env[$key] = $value
        }
    }
    return $env
}

# Check for .env file
if (-not (Test-Path $EnvFile)) {
    Write-Host "❌ Environment file not found: $EnvFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please run: .\scripts\setup-env.ps1 -Interactive" -ForegroundColor Yellow
    exit 1
}

Write-Host "Loading configuration from $EnvFile..." -ForegroundColor Green
$env = Load-EnvFile -Path $EnvFile

# Validate required environment variables
$required = @(
    "LLM_TEXT_API_URL",
    "LLM_TEXT_MODEL",
    "GEMINI_IMAGE_API_URL"
)

$missing = @()
foreach ($key in $required) {
    if (-not $env[$key] -or $env[$key] -eq "") {
        $missing += $key
    }
}

if ($missing.Count -gt 0) {
    Write-Host "❌ Missing required environment variables:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    Write-Host ""
    Write-Host "Please run: .\scripts\setup-env.ps1 -Interactive" -ForegroundColor Yellow
    exit 1
}

# Get business-specific values
if ($UseDefaults) {
    $businessName = if ($env.DEFAULT_BUSINESS_NAME) { $env.DEFAULT_BUSINESS_NAME } else { "Default Business" }
    $primaryState = if ($env.DEFAULT_PRIMARY_STATE) { $env.DEFAULT_PRIMARY_STATE } else { "NSW" }
    $passingScore = if ($env.DEFAULT_PASSING_SCORE) { $env.DEFAULT_PASSING_SCORE } else { "80" }
    $imageStyle = if ($env.DEFAULT_IMAGE_STYLE) { $env.DEFAULT_IMAGE_STYLE } else { "professional" }
    $ttsVoice = if ($env.DEFAULT_TTS_VOICE) { $env.DEFAULT_TTS_VOICE } else { "en-AU-Standard-A" }
    $videoMode = if ($env.DEFAULT_VIDEO_MODE) { $env.DEFAULT_VIDEO_MODE } else { "slides" }
} else {
    if (-not $BusinessName) {
        $BusinessName = Read-Host "Enter business name [$($env.DEFAULT_BUSINESS_NAME)]"
        if (-not $BusinessName -and $env.DEFAULT_BUSINESS_NAME) {
            $BusinessName = $env.DEFAULT_BUSINESS_NAME
        }
    }

    $primaryState = Read-Host "Enter primary state [$($env.DEFAULT_PRIMARY_STATE)]"
    if (-not $primaryState) { $primaryState = $env.DEFAULT_PRIMARY_STATE }

    $passingScore = Read-Host "Enter passing score [$($env.DEFAULT_PASSING_SCORE)]"
    if (-not $passingScore) { $passingScore = $env.DEFAULT_PASSING_SCORE }

    $imageStyle = Read-Host "Image style [$($env.DEFAULT_IMAGE_STYLE)]"
    if (-not $imageStyle) { $imageStyle = $env.DEFAULT_IMAGE_STYLE }

    $ttsVoice = Read-Host "TTS Voice [$($env.DEFAULT_TTS_VOICE)]"
    if (-not $ttsVoice) { $ttsVoice = $env.DEFAULT_TTS_VOICE }

    $videoMode = Read-Host "Video mode [$($env.DEFAULT_VIDEO_MODE)]"
    if (-not $videoMode) { $videoMode = $env.DEFAULT_VIDEO_MODE }
}

# Get or prompt for Google Drive folders
if (-not $env.DRIVE_FOLDER_MANUALS) {
    Write-Host ""
    Write-Host "Google Drive folder IDs not found in environment" -ForegroundColor Yellow
    $env.DRIVE_FOLDER_MANUALS = Read-Host "Folder ID for Manuals"
    $env.DRIVE_FOLDER_ASSETS = Read-Host "Folder ID for Assets"
    $env.DRIVE_FOLDER_ASSESS = Read-Host "Folder ID for Assessments"
    $env.DRIVE_FOLDER_CERTS = Read-Host "Folder ID for Certificates"
}

if (-not $env.SHEET_VERSION_LOG_ID) {
    $env.SHEET_VERSION_LOG_ID = Read-Host "Google Sheet ID for version log"
}

# Set credential IDs (use defaults if not in env)
$llmCredId = if ($env.LLM_TEXT_CREDENTIAL_ID) { $env.LLM_TEXT_CREDENTIAL_ID } else { "llm-api-auth" }
$geminiCredId = if ($env.GEMINI_CREDENTIAL_ID) { $env.GEMINI_CREDENTIAL_ID } else { "gemini-api-auth" }
$googleDocsCredId = if ($env.GOOGLE_DOCS_CREDENTIAL_ID) { $env.GOOGLE_DOCS_CREDENTIAL_ID } else { "google-docs-oauth" }
$googleDriveCredId = if ($env.GOOGLE_DRIVE_CREDENTIAL_ID) { $env.GOOGLE_DRIVE_CREDENTIAL_ID } else { "google-drive-oauth" }
$googleSheetsCredId = if ($env.GOOGLE_SHEETS_CREDENTIAL_ID) { $env.GOOGLE_SHEETS_CREDENTIAL_ID } else { "google-sheets-oauth" }

# Build parameters from environment
$params = @{
    "BUSINESS_NAME" = $BusinessName
    "PRIMARY_STATE" = $primaryState
    "PASSING_SCORE" = $passingScore
    "DRIVE_FOLDER_MANUALS" = $env.DRIVE_FOLDER_MANUALS
    "DRIVE_FOLDER_ASSETS" = $env.DRIVE_FOLDER_ASSETS
    "DRIVE_FOLDER_ASSESS" = $env.DRIVE_FOLDER_ASSESS
    "DRIVE_FOLDER_CERTS" = $env.DRIVE_FOLDER_CERTS
    "SHEET_VERSION_LOG_ID" = $env.SHEET_VERSION_LOG_ID
    "IMAGE_STYLE" = $imageStyle
    "TTS_VOICE" = $ttsVoice
    "VIDEO_MODE" = $videoMode
    "LLM_TEXT_API_URL" = $env.LLM_TEXT_API_URL
    "LLM_TEXT_MODEL" = $env.LLM_TEXT_MODEL
    "LLM_TEXT_CREDENTIAL_ID" = $llmCredId
    "GEMINI_IMAGE_API_URL" = $env.GEMINI_IMAGE_API_URL
    "GEMINI_CREDENTIAL_ID" = $geminiCredId
    "GOOGLE_DOCS_CREDENTIAL_ID" = $googleDocsCredId
    "GOOGLE_DRIVE_CREDENTIAL_ID" = $googleDriveCredId
    "GOOGLE_SHEETS_CREDENTIAL_ID" = $googleSheetsCredId
}

Write-Host ""
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "  Business: $BusinessName" -ForegroundColor White
Write-Host "  State: $primaryState" -ForegroundColor White
Write-Host "  LLM: $($env.LLM_TEXT_MODEL) @ $($env.LLM_TEXT_API_URL)" -ForegroundColor White
Write-Host "  Image Style: $imageStyle" -ForegroundColor White
Write-Host ""

# Process template
Write-Host "Generating workflow..." -ForegroundColor Green

$templatePath = Join-Path $PSScriptRoot "..\..\blueprints\integrations\au-nrp-contractor-onboarding.json"
$workflowJson = Get-Content -Raw $templatePath

foreach ($key in $params.Keys) {
    $placeholder = "{{$key}}"
    $workflowJson = $workflowJson -replace [regex]::Escape($placeholder), $params[$key]
}

$workflow = $workflowJson | ConvertFrom-Json
$workflow.name = "AU NRP Onboarding - $BusinessName"

# Save and deploy
$tempFile = [System.IO.Path]::GetTempFileName()
$tempFile = [System.IO.Path]::ChangeExtension($tempFile, ".json")
$workflow | ConvertTo-Json -Depth 10 | Out-File $tempFile -Encoding UTF8

Write-Host "Deploying to n8n..." -ForegroundColor Green
$deployScript = Join-Path $PSScriptRoot "..\workflows\apply-cli.ps1"
& $deployScript -WorkflowFile $tempFile

Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host "   Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

# Create credentials configuration script
$credScript = @"
# Credential Configuration for n8n
# Run these in n8n UI under Settings > Credentials

## 1. HTTP Basic Auth: $llmCredId
Username: $($env.LLM_TEXT_USERNAME)
Password: [Use from .env: LLM_TEXT_PASSWORD]

## 2. HTTP Basic Auth: $geminiCredId
Username: $($env.GEMINI_USERNAME)
Password: [Use from .env: GEMINI_PASSWORD]

## 3. Google OAuth2: $googleDocsCredId, $googleDriveCredId, $googleSheetsCredId
Client ID: $($env.GOOGLE_CLIENT_ID)
Client Secret: [Use from .env: GOOGLE_CLIENT_SECRET]
"@

$credScriptPath = ".\credential-config-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$credScript | Out-File -FilePath $credScriptPath -Encoding UTF8

Write-Host "Credential configuration saved to: $credScriptPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Open n8n at http://localhost:5678" -ForegroundColor White
Write-Host "2. Create credentials using info in $credScriptPath" -ForegroundColor White
Write-Host "3. Activate the workflow" -ForegroundColor White
Write-Host "4. Test with 'Execute Workflow'" -ForegroundColor White