# setup-env.ps1 - Environment configuration helper for AU NRP Onboarding

param(
    [switch]$Interactive,
    [string]$EnvFile = ".env",
    [switch]$Validate
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "   AU NRP Environment Configuration      " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Function to read existing .env file
function Read-EnvFile {
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

# Function to write .env file
function Write-EnvFile {
    param(
        [hashtable]$Config,
        [string]$Path
    )

    $content = @"
# AU NRP Contractor Onboarding Configuration
# Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# LLM Service
LLM_TEXT_API_URL=$($Config.LLM_TEXT_API_URL)
LLM_TEXT_MODEL=$($Config.LLM_TEXT_MODEL)
LLM_TEXT_USERNAME=$($Config.LLM_TEXT_USERNAME)
LLM_TEXT_PASSWORD=$($Config.LLM_TEXT_PASSWORD)

# Gemini Image API
GEMINI_IMAGE_API_URL=$($Config.GEMINI_IMAGE_API_URL)
GEMINI_USERNAME=$($Config.GEMINI_USERNAME)
GEMINI_PASSWORD=$($Config.GEMINI_PASSWORD)

# Google OAuth2
GOOGLE_CLIENT_ID=$($Config.GOOGLE_CLIENT_ID)
GOOGLE_CLIENT_SECRET=$($Config.GOOGLE_CLIENT_SECRET)
GOOGLE_REFRESH_TOKEN=$($Config.GOOGLE_REFRESH_TOKEN)
GOOGLE_REDIRECT_URI=$($Config.GOOGLE_REDIRECT_URI)

# Google Resources
GOOGLE_DRIVE_CREDENTIAL_ID=$($Config.GOOGLE_DRIVE_CREDENTIAL_ID)
GOOGLE_DOCS_CREDENTIAL_ID=$($Config.GOOGLE_DOCS_CREDENTIAL_ID)
GOOGLE_SHEETS_CREDENTIAL_ID=$($Config.GOOGLE_SHEETS_CREDENTIAL_ID)

# Folder IDs
DRIVE_FOLDER_MANUALS=$($Config.DRIVE_FOLDER_MANUALS)
DRIVE_FOLDER_ASSETS=$($Config.DRIVE_FOLDER_ASSETS)
DRIVE_FOLDER_ASSESS=$($Config.DRIVE_FOLDER_ASSESS)
DRIVE_FOLDER_CERTS=$($Config.DRIVE_FOLDER_CERTS)
SHEET_VERSION_LOG_ID=$($Config.SHEET_VERSION_LOG_ID)

# n8n
N8N_API_KEY=$($Config.N8N_API_KEY)
N8N_WEBHOOK_URL=$($Config.N8N_WEBHOOK_URL)

# Defaults
DEFAULT_BUSINESS_NAME=$($Config.DEFAULT_BUSINESS_NAME)
DEFAULT_PRIMARY_STATE=$($Config.DEFAULT_PRIMARY_STATE)
DEFAULT_PASSING_SCORE=$($Config.DEFAULT_PASSING_SCORE)
DEFAULT_IMAGE_STYLE=$($Config.DEFAULT_IMAGE_STYLE)
DEFAULT_TTS_VOICE=$($Config.DEFAULT_TTS_VOICE)
DEFAULT_VIDEO_MODE=$($Config.DEFAULT_VIDEO_MODE)
"@

    $content | Out-File -FilePath $Path -Encoding UTF8
}

# Validation mode
if ($Validate) {
    Write-Host "Validating environment configuration..." -ForegroundColor Yellow
    $config = Read-EnvFile -Path $EnvFile

    $required = @(
        "LLM_TEXT_API_URL",
        "LLM_TEXT_MODEL",
        "GEMINI_IMAGE_API_URL",
        "N8N_API_KEY"
    )

    $missing = @()
    foreach ($key in $required) {
        if (-not $config[$key] -or $config[$key] -eq "") {
            $missing += $key
        }
    }

    if ($missing.Count -gt 0) {
        Write-Host "❌ Missing required configuration:" -ForegroundColor Red
        $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        exit 1
    } else {
        Write-Host "✅ All required configuration present" -ForegroundColor Green
    }

    # Test connectivity
    Write-Host ""
    Write-Host "Testing connections..." -ForegroundColor Yellow

    # Test LLM API
    if ($config.LLM_TEXT_API_URL) {
        try {
            $response = Invoke-WebRequest -Uri $config.LLM_TEXT_API_URL -Method HEAD -TimeoutSec 5
            Write-Host "✅ LLM API reachable" -ForegroundColor Green
        } catch {
            Write-Host "⚠️  LLM API not reachable: $_" -ForegroundColor Yellow
        }
    }

    exit 0
}

# Check if .env exists
if (Test-Path $EnvFile) {
    Write-Host "Found existing .env file" -ForegroundColor Green
    $config = Read-EnvFile -Path $EnvFile
} else {
    Write-Host "No .env file found, creating new configuration" -ForegroundColor Yellow

    # Copy from example if exists
    if (Test-Path ".env.example") {
        Copy-Item ".env.example" $EnvFile
        Write-Host "Created .env from .env.example" -ForegroundColor Green
        $config = Read-EnvFile -Path $EnvFile
    } else {
        $config = @{}
    }
}

# Interactive setup
if ($Interactive) {
    Write-Host ""
    Write-Host "=== LLM Configuration ===" -ForegroundColor Yellow

    $llmUrl = Read-Host "LLM API URL [$($config.LLM_TEXT_API_URL)]"
    if ($llmUrl) { $config.LLM_TEXT_API_URL = $llmUrl }

    $llmModel = Read-Host "LLM Model [$($config.LLM_TEXT_MODEL)]"
    if ($llmModel) { $config.LLM_TEXT_MODEL = $llmModel }

    $llmUser = Read-Host "LLM Username [$($config.LLM_TEXT_USERNAME)]"
    if ($llmUser) { $config.LLM_TEXT_USERNAME = $llmUser }

    $llmPass = Read-Host "LLM Password" -AsSecureString
    if ($llmPass.Length -gt 0) {
        $config.LLM_TEXT_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($llmPass))
    }

    Write-Host ""
    Write-Host "=== Gemini Configuration ===" -ForegroundColor Yellow

    $geminiUrl = Read-Host "Gemini API URL [$($config.GEMINI_IMAGE_API_URL)]"
    if ($geminiUrl) { $config.GEMINI_IMAGE_API_URL = $geminiUrl }

    $geminiUser = Read-Host "Gemini Username [$($config.GEMINI_USERNAME)]"
    if ($geminiUser) { $config.GEMINI_USERNAME = $geminiUser }

    $geminiPass = Read-Host "Gemini Password" -AsSecureString
    if ($geminiPass.Length -gt 0) {
        $config.GEMINI_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($geminiPass))
    }

    Write-Host ""
    Write-Host "=== Google OAuth2 Configuration ===" -ForegroundColor Yellow
    Write-Host "Get these from: https://console.cloud.google.com" -ForegroundColor Gray

    $googleClientId = Read-Host "Google Client ID [$($config.GOOGLE_CLIENT_ID)]"
    if ($googleClientId) { $config.GOOGLE_CLIENT_ID = $googleClientId }

    $googleClientSecret = Read-Host "Google Client Secret" -AsSecureString
    if ($googleClientSecret.Length -gt 0) {
        $config.GOOGLE_CLIENT_SECRET = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($googleClientSecret))
    }

    Write-Host ""
    Write-Host "=== n8n Configuration ===" -ForegroundColor Yellow

    $n8nKey = Read-Host "n8n API Key [$($config.N8N_API_KEY)]"
    if ($n8nKey) { $config.N8N_API_KEY = $n8nKey }

    $n8nUrl = Read-Host "n8n Webhook URL [$($config.N8N_WEBHOOK_URL)]"
    if ($n8nUrl) { $config.N8N_WEBHOOK_URL = $n8nUrl }

    # Set defaults if not present
    if (-not $config.GOOGLE_REDIRECT_URI) { $config.GOOGLE_REDIRECT_URI = "https://developers.google.com/oauthplayground" }
    if (-not $config.N8N_WEBHOOK_URL) { $config.N8N_WEBHOOK_URL = "http://localhost:5678/webhook" }
    if (-not $config.DEFAULT_PRIMARY_STATE) { $config.DEFAULT_PRIMARY_STATE = "NSW" }
    if (-not $config.DEFAULT_PASSING_SCORE) { $config.DEFAULT_PASSING_SCORE = "80" }
    if (-not $config.DEFAULT_IMAGE_STYLE) { $config.DEFAULT_IMAGE_STYLE = "professional" }
    if (-not $config.DEFAULT_TTS_VOICE) { $config.DEFAULT_TTS_VOICE = "en-AU-Standard-A" }
    if (-not $config.DEFAULT_VIDEO_MODE) { $config.DEFAULT_VIDEO_MODE = "slides" }

    # Save configuration
    Write-EnvFile -Config $config -Path $EnvFile

    Write-Host ""
    Write-Host "✅ Configuration saved to $EnvFile" -ForegroundColor Green
}

# Display current configuration
Write-Host ""
Write-Host "Current Configuration:" -ForegroundColor Cyan
Write-Host "----------------------" -ForegroundColor Cyan

$config = Read-EnvFile -Path $EnvFile

# Display non-sensitive values
@(
    "LLM_TEXT_API_URL",
    "LLM_TEXT_MODEL",
    "GEMINI_IMAGE_API_URL",
    "GOOGLE_REDIRECT_URI",
    "N8N_WEBHOOK_URL",
    "DEFAULT_PRIMARY_STATE",
    "DEFAULT_PASSING_SCORE",
    "DEFAULT_IMAGE_STYLE"
) | ForEach-Object {
    if ($config[$_]) {
        Write-Host "$_`: $($config[$_])"
    }
}

# Check sensitive values (just show if set)
@(
    "LLM_TEXT_PASSWORD",
    "GEMINI_PASSWORD",
    "GOOGLE_CLIENT_SECRET",
    "N8N_API_KEY"
) | ForEach-Object {
    if ($config[$_] -and $config[$_] -ne "") {
        Write-Host "$_`: [SET]" -ForegroundColor Green
    } else {
        Write-Host "$_`: [NOT SET]" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Commands:" -ForegroundColor Cyan
Write-Host "  .\scripts\setup-env.ps1 -Interactive    # Configure interactively"
Write-Host "  .\scripts\setup-env.ps1 -Validate       # Validate configuration"
Write-Host ""

# Add to .gitignore if not present
if (Test-Path ".gitignore") {
    $gitignore = Get-Content ".gitignore"
    if ($gitignore -notcontains ".env") {
        Add-Content ".gitignore" "`n# Environment variables`n.env"
        Write-Host "Added .env to .gitignore" -ForegroundColor Gray
    }
}