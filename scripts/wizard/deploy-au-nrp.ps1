# deploy-au-nrp.ps1 - Quick deployment script for AU NRP Contractor Onboarding workflow

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " AU NRP Contractor Onboarding Deployment " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This workflow creates:" -ForegroundColor Green
Write-Host "  - Training manuals with AU compliance" -ForegroundColor White
Write-Host "  - Assessment quizzes" -ForegroundColor White
Write-Host "  - Educational images via Gemini" -ForegroundColor White
Write-Host "  - Version tracking in Google Sheets" -ForegroundColor White
Write-Host ""

# Collect business information
Write-Host "=== Business Configuration ===" -ForegroundColor Yellow
$businessName = Read-Host "Enter your business name"
$primaryState = Read-Host "Enter primary state (NSW/VIC/QLD/SA/WA/TAS/NT/ACT) [NSW]"
if (!$primaryState) { $primaryState = "NSW" }

$passingScore = Read-Host "Enter passing score percentage [80]"
if (!$passingScore) { $passingScore = "80" }

Write-Host ""
Write-Host "=== Google Drive Setup ===" -ForegroundColor Yellow
Write-Host "You'll need folder IDs from Google Drive URLs" -ForegroundColor Gray
Write-Host "Example: https://drive.google.com/drive/folders/[FOLDER_ID_HERE]" -ForegroundColor DarkGray
Write-Host ""

$driveManuals = Read-Host "Folder ID for Training Manuals"
$driveAssets = Read-Host "Folder ID for Images/Assets"
$driveAssess = Read-Host "Folder ID for Assessments"
$driveCerts = Read-Host "Folder ID for Certificates"

Write-Host ""
$sheetId = Read-Host "Google Sheet ID for version logging"

Write-Host ""
Write-Host "=== AI Configuration ===" -ForegroundColor Yellow
$llmUrl = Read-Host "LLM API URL (e.g., OpenAI endpoint)"
$llmModel = Read-Host "LLM Model [gpt-4]"
if (!$llmModel) { $llmModel = "gpt-4" }

$geminiUrl = Read-Host "Gemini Image API URL"

Write-Host ""
Write-Host "=== Style Preferences ===" -ForegroundColor Yellow
$imageStyle = Read-Host "Image style (professional/cartoon/diagram/infographic) [professional]"
if (!$imageStyle) { $imageStyle = "professional" }

$ttsVoice = Read-Host "TTS Voice [en-AU-Standard-A]"
if (!$ttsVoice) { $ttsVoice = "en-AU-Standard-A" }

$videoMode = Read-Host "Video mode (slides/animated/talking-head) [slides]"
if (!$videoMode) { $videoMode = "slides" }

Write-Host ""
Write-Host "=== Credential IDs ===" -ForegroundColor Yellow
Write-Host "Enter the n8n credential IDs (you'll create these in n8n UI)" -ForegroundColor Gray
$llmCredId = Read-Host "LLM API Credential ID [llm-api]"
if (!$llmCredId) { $llmCredId = "llm-api" }

$geminiCredId = Read-Host "Gemini API Credential ID [gemini-api]"
if (!$geminiCredId) { $geminiCredId = "gemini-api" }

$googleDocsCredId = Read-Host "Google Docs Credential ID [google-docs]"
if (!$googleDocsCredId) { $googleDocsCredId = "google-docs" }

$googleDriveCredId = Read-Host "Google Drive Credential ID [google-drive]"
if (!$googleDriveCredId) { $googleDriveCredId = "google-drive" }

$googleSheetsCredId = Read-Host "Google Sheets Credential ID [google-sheets]"
if (!$googleSheetsCredId) { $googleSheetsCredId = "google-sheets" }

# Build parameters
$params = @{
    "BUSINESS_NAME" = $businessName
    "PRIMARY_STATE" = $primaryState
    "PASSING_SCORE" = $passingScore
    "DRIVE_FOLDER_MANUALS" = $driveManuals
    "DRIVE_FOLDER_ASSETS" = $driveAssets
    "DRIVE_FOLDER_ASSESS" = $driveAssess
    "DRIVE_FOLDER_CERTS" = $driveCerts
    "SHEET_VERSION_LOG_ID" = $sheetId
    "IMAGE_STYLE" = $imageStyle
    "TTS_VOICE" = $ttsVoice
    "VIDEO_MODE" = $videoMode
    "LLM_TEXT_API_URL" = $llmUrl
    "LLM_TEXT_MODEL" = $llmModel
    "LLM_TEXT_CREDENTIAL_ID" = $llmCredId
    "GEMINI_IMAGE_API_URL" = $geminiUrl
    "GEMINI_CREDENTIAL_ID" = $geminiCredId
    "GOOGLE_DOCS_CREDENTIAL_ID" = $googleDocsCredId
    "GOOGLE_DRIVE_CREDENTIAL_ID" = $googleDriveCredId
    "GOOGLE_SHEETS_CREDENTIAL_ID" = $googleSheetsCredId
}

# Load and process template
Write-Host ""
Write-Host "Generating workflow..." -ForegroundColor Green

$templatePath = Join-Path $PSScriptRoot "..\..\blueprints\integrations\au-nrp-contractor-onboarding.json"
$workflowJson = Get-Content -Raw $templatePath

foreach ($key in $params.Keys) {
    $placeholder = "{{$key}}"
    $workflowJson = $workflowJson -replace [regex]::Escape($placeholder), $params[$key]
}

$workflow = $workflowJson | ConvertFrom-Json
$workflow.name = "AU NRP Onboarding - $businessName"

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
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Open n8n at http://localhost:5678" -ForegroundColor White
Write-Host "2. Configure the following credentials:" -ForegroundColor White
Write-Host "   - HTTP Basic Auth for LLM API ($llmCredId)" -ForegroundColor Yellow
Write-Host "   - HTTP Basic Auth for Gemini API ($geminiCredId)" -ForegroundColor Yellow
Write-Host "   - Google OAuth2 for Docs ($googleDocsCredId)" -ForegroundColor Yellow
Write-Host "   - Google OAuth2 for Drive ($googleDriveCredId)" -ForegroundColor Yellow
Write-Host "   - Google OAuth2 for Sheets ($googleSheetsCredId)" -ForegroundColor Yellow
Write-Host "3. Activate the workflow" -ForegroundColor White
Write-Host "4. Click 'Execute Workflow' to run manually" -ForegroundColor White
Write-Host ""
Write-Host "The workflow will generate:" -ForegroundColor Gray
Write-Host "  - Training manual in Google Docs" -ForegroundColor Gray
Write-Host "  - Educational images in Drive" -ForegroundColor Gray
Write-Host "  - Version log in Sheets" -ForegroundColor Gray