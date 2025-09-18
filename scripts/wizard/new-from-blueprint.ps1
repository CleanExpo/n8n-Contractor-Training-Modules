# new-from-blueprint.ps1 - Create new workflow from blueprint template

param(
    [string]$Template,
    [string]$Name,
    [string]$OutputPath,
    [switch]$Interactive
)

Write-Host "======================================" -ForegroundColor Cyan
Write-Host " Create New Workflow from Blueprint  " -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$blueprintDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "blueprints"
$flowsDir = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "flows"

# Function to find blueprint by name
function Find-Blueprint {
    param([string]$Name)

    $found = Get-ChildItem -Path $blueprintDir -Filter "*.json" -Recurse | Where-Object {
        $_.BaseName -like "*$Name*"
    } | Select-Object -First 1

    return $found
}

# Interactive mode
if ($Interactive -or -not $Template) {
    Write-Host "Available blueprint categories:" -ForegroundColor Green
    $categories = Get-ChildItem -Path $blueprintDir -Directory | Select-Object -ExpandProperty Name

    Write-Host ""
    for ($i = 0; $i -lt $categories.Count; $i++) {
        Write-Host "$($i + 1). $($categories[$i])" -ForegroundColor White
    }

    Write-Host ""
    $catSelection = Read-Host "Select category (1-$($categories.Count))"
    $selectedCategory = $categories[[int]$catSelection - 1]

    # Show blueprints in category
    $categoryPath = Join-Path $blueprintDir $selectedCategory
    $templates = Get-ChildItem -Path $categoryPath -Filter "*.json" -ErrorAction SilentlyContinue

    if ($templates.Count -eq 0) {
        Write-Host "No templates in this category yet" -ForegroundColor Yellow
        exit 1
    }

    Write-Host ""
    Write-Host "Templates in $selectedCategory`:" -ForegroundColor Green
    for ($i = 0; $i -lt $templates.Count; $i++) {
        Write-Host "$($i + 1). $($templates[$i].BaseName)" -ForegroundColor White
    }

    Write-Host ""
    $tempSelection = Read-Host "Select template (1-$($templates.Count))"
    $Template = $templates[[int]$tempSelection - 1].FullName
} else {
    # Find blueprint by name
    $found = Find-Blueprint -Name $Template
    if (-not $found) {
        Write-Host "Blueprint '$Template' not found!" -ForegroundColor Red
        exit 1
    }
    $Template = $found.FullName
}

# Load the template
Write-Host ""
Write-Host "Loading template..." -ForegroundColor Yellow
$templateJson = Get-Content $Template -Raw
$workflow = $templateJson | ConvertFrom-Json

# Get workflow name
if (-not $Name) {
    Write-Host ""
    Write-Host "Current name: $($workflow.name)" -ForegroundColor Cyan
    $Name = Read-Host "Enter new workflow name (or press Enter to keep)"
    if (-not $Name) {
        $Name = $workflow.name
    }
}

$workflow.name = $Name

# Get output path
if (-not $OutputPath) {
    $defaultPath = Join-Path $flowsDir "$($Name -replace '\s+', '-').json"
    Write-Host ""
    $OutputPath = Read-Host "Output path [$defaultPath]"
    if (-not $OutputPath) {
        $OutputPath = $defaultPath
    }
}

# Ensure output directory exists
$outputDir = Split-Path $OutputPath
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Interactive customization
Write-Host ""
$customize = Read-Host "Customize workflow settings? (y/N)"
if ($customize -eq "y" -or $customize -eq "Y") {
    Write-Host ""
    Write-Host "Workflow Customization" -ForegroundColor Cyan
    Write-Host "----------------------" -ForegroundColor Cyan

    # Customize webhook paths
    $webhookNodes = $workflow.nodes | Where-Object { $_.type -like "*webhook*" }
    if ($webhookNodes) {
        Write-Host ""
        Write-Host "Webhook Configuration:" -ForegroundColor Yellow
        foreach ($node in $webhookNodes) {
            if ($node.parameters.path) {
                $currentPath = $node.parameters.path
                Write-Host "  Current path for '$($node.name)': $currentPath" -ForegroundColor Gray
                $newPath = Read-Host "  Enter new path (or press Enter to keep)"
                if ($newPath) {
                    $node.parameters.path = $newPath
                }
            }
        }
    }

    # Customize HTTP request URLs
    $httpNodes = $workflow.nodes | Where-Object { $_.type -like "*httpRequest*" }
    if ($httpNodes) {
        Write-Host ""
        Write-Host "HTTP Request Configuration:" -ForegroundColor Yellow
        foreach ($node in $httpNodes) {
            if ($node.parameters.url) {
                $currentUrl = $node.parameters.url
                Write-Host "  Current URL for '$($node.name)': $currentUrl" -ForegroundColor Gray
                $newUrl = Read-Host "  Enter new URL (or press Enter to keep)"
                if ($newUrl) {
                    $node.parameters.url = $newUrl
                }
            }
        }
    }

    # Customize schedule/cron
    $cronNodes = $workflow.nodes | Where-Object { $_.type -like "*cron*" -or $_.type -like "*schedule*" }
    if ($cronNodes) {
        Write-Host ""
        Write-Host "Schedule Configuration:" -ForegroundColor Yellow
        foreach ($node in $cronNodes) {
            if ($node.parameters.cronExpression) {
                $currentCron = $node.parameters.cronExpression
                Write-Host "  Current schedule for '$($node.name)': $currentCron" -ForegroundColor Gray
                Write-Host "  Examples: '0 9 * * 1-5' (9am weekdays), '*/5 * * * *' (every 5 min)" -ForegroundColor Gray
                $newCron = Read-Host "  Enter new cron expression (or press Enter to keep)"
                if ($newCron) {
                    $node.parameters.cronExpression = $newCron
                }
            }
        }
    }
}

# Add metadata
if (-not $workflow.meta) {
    $workflow | Add-Member -NotePropertyName "meta" -NotePropertyValue @{} -Force
}
$workflow.meta | Add-Member -NotePropertyName "templateSource" -NotePropertyValue (Split-Path $Template -Leaf) -Force
$workflow.meta | Add-Member -NotePropertyName "createdFrom" -NotePropertyValue "blueprint-wizard" -Force
$workflow.meta | Add-Member -NotePropertyName "createdAt" -NotePropertyValue (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force

# Save the workflow
Write-Host ""
Write-Host "Saving workflow to: $OutputPath" -ForegroundColor Yellow
$workflow | ConvertTo-Json -Depth 10 | Out-File $OutputPath -Encoding UTF8

Write-Host ""
Write-Host "======================================" -ForegroundColor Green
Write-Host "    Workflow created successfully!    " -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green
Write-Host ""
Write-Host "File saved: $OutputPath" -ForegroundColor White
Write-Host ""

# Ask if user wants to deploy
$deploy = Read-Host "Deploy this workflow now? (y/N)"
if ($deploy -eq "y" -or $deploy -eq "Y") {
    Write-Host ""
    $deployScript = Join-Path (Split-Path $PSScriptRoot) "workflows\apply-cli.ps1"

    $activate = Read-Host "Activate after deployment? (y/N)"
    if ($activate -eq "y" -or $activate -eq "Y") {
        & $deployScript -WorkflowFile $OutputPath -Activate
    } else {
        & $deployScript -WorkflowFile $OutputPath
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review the workflow file: $OutputPath" -ForegroundColor White
Write-Host "2. Deploy using: .\scripts\workflows\apply-cli.ps1 -WorkflowFile '$OutputPath'" -ForegroundColor White
Write-Host "3. Configure credentials in n8n UI" -ForegroundColor White