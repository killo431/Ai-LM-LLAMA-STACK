# LM Studio Model Import Script
# This script helps import model configurations into LM Studio

param(
    [Parameter(Mandatory=$false)]
    [string]$JsonPath = "",
    
    [Parameter(Mandatory=$false)]
    [string]$LMStudioPath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$AutoDetect = $false
)

# Function to find LM Studio installation
function Find-LMStudioPath {
    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\LM Studio\LM Studio.exe",
        "$env:PROGRAMFILES\LM Studio\LM Studio.exe",
        "${env:PROGRAMFILES(X86)}\LM Studio\LM Studio.exe",
        "$env:USERPROFILE\AppData\Local\Programs\LM Studio\LM Studio.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

# Function to get LM Studio config directory
function Get-LMStudioConfigDir {
    $configPaths = @(
        "$env:APPDATA\LM Studio",
        "$env:LOCALAPPDATA\LM Studio",
        "$env:USERPROFILE\.lmstudio"
    )
    
    foreach ($path in $configPaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    
    # Create default config directory if none exists
    $defaultPath = "$env:APPDATA\LM Studio"
    New-Item -ItemType Directory -Path $defaultPath -Force | Out-Null
    return $defaultPath
}

# Function to backup existing configurations
function Backup-ExistingConfigs {
    param([string]$ConfigDir)
    
    $backupDir = Join-Path $ConfigDir "backups"
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = Join-Path $backupDir "backup_$timestamp"
    
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    
    # Backup model configs if they exist
    $modelConfigPath = Join-Path $ConfigDir "models.json"
    if (Test-Path $modelConfigPath) {
        Copy-Item $modelConfigPath (Join-Path $backupPath "models.json")
        Write-Host "✓ Backed up existing model configurations to: $backupPath" -ForegroundColor Green
    }
    
    return $backupPath
}

# Function to validate JSON structure
function Test-ModelJson {
    param([string]$JsonPath)
    
    try {
        $jsonContent = Get-Content $JsonPath -Raw | ConvertFrom-Json
        
        # Check if it's an array of models
        if ($jsonContent -is [System.Array]) {
            $requiredFields = @("name", "model_family", "default_params")
            
            foreach ($model in $jsonContent) {
                foreach ($field in $requiredFields) {
                    if (-not $model.PSObject.Properties[$field]) {
                        throw "Missing required field '$field' in model: $($model.name)"
                    }
                }
            }
            return $true
        } else {
            throw "JSON should contain an array of model configurations"
        }
    }
    catch {
        Write-Error "Invalid JSON format: $_"
        return $false
    }
}

# Function to merge model configurations
function Merge-ModelConfigs {
    param(
        [string]$ExistingConfigPath,
        [string]$NewJsonPath
    )
    
    $newModels = Get-Content $NewJsonPath -Raw | ConvertFrom-Json
    $mergedModels = @()
    
    # Load existing models if file exists
    if (Test-Path $ExistingConfigPath) {
        try {
            $existingModels = Get-Content $ExistingConfigPath -Raw | ConvertFrom-Json
            $mergedModels += $existingModels
        }
        catch {
            Write-Warning "Could not read existing config file, starting fresh"
        }
    }
    
    # Add new models (avoid duplicates by name)
    $existingNames = $mergedModels | ForEach-Object { $_.name }
    
    foreach ($newModel in $newModels) {
        if ($newModel.name -notin $existingNames) {
            $mergedModels += $newModel
            Write-Host "✓ Added model: $($newModel.name)" -ForegroundColor Green
        } else {
            Write-Host "⚠ Skipped duplicate model: $($newModel.name)" -ForegroundColor Yellow
        }
    }
    
    return $mergedModels
}

# Main script execution
Write-Host "=== LM Studio Model Import Script ===" -ForegroundColor Cyan
Write-Host ""

# Get JSON file path
if ([string]::IsNullOrEmpty($JsonPath)) {
    $JsonPath = Read-Host "Enter path to JSON model configuration file"
}

if (-not (Test-Path $JsonPath)) {
    Write-Error "JSON file not found: $JsonPath"
    exit 1
}

Write-Host "📄 Found JSON file: $JsonPath" -ForegroundColor Green

# Validate JSON
Write-Host "🔍 Validating JSON structure..." -ForegroundColor Yellow
if (-not (Test-ModelJson -JsonPath $JsonPath)) {
    exit 1
}
Write-Host "✓ JSON validation passed" -ForegroundColor Green

# Find LM Studio
if ([string]::IsNullOrEmpty($LMStudioPath)) {
    $LMStudioPath = Find-LMStudioPath
}

if ($LMStudioPath -and (Test-Path $LMStudioPath)) {
    Write-Host "🎯 Found LM Studio: $LMStudioPath" -ForegroundColor Green
} else {
    Write-Warning "LM Studio executable not found. Please ensure LM Studio is installed."
}

# Get config directory
$configDir = Get-LMStudioConfigDir
Write-Host "📁 Config directory: $configDir" -ForegroundColor Green

# Backup existing configurations
Write-Host "💾 Creating backup..." -ForegroundColor Yellow
$backupPath = Backup-ExistingConfigs -ConfigDir $configDir

# Import models
Write-Host "📥 Importing model configurations..." -ForegroundColor Yellow
$modelConfigPath = Join-Path $configDir "models.json"
$mergedModels = Merge-ModelConfigs -ExistingConfigPath $modelConfigPath -NewJsonPath $JsonPath

# Save merged configuration
$mergedModels | ConvertTo-Json -Depth 10 | Set-Content $modelConfigPath -Encoding UTF8
Write-Host "✓ Model configurations saved to: $modelConfigPath" -ForegroundColor Green

# Create a summary
$newModelCount = (Get-Content $JsonPath -Raw | ConvertFrom-Json).Count
Write-Host ""
Write-Host "=== Import Summary ===" -ForegroundColor Cyan
Write-Host "Models to import: $newModelCount" -ForegroundColor White
Write-Host "Total models after merge: $($mergedModels.Count)" -ForegroundColor White
Write-Host "Backup location: $backupPath" -ForegroundColor White
Write-Host ""

# Optional: Start LM Studio
if ($LMStudioPath -and (Test-Path $LMStudioPath)) {
    $startLMStudio = Read-Host "Start LM Studio now? (y/N)"
    if ($startLMStudio -eq 'y' -or $startLMStudio -eq 'Y') {
        Write-Host "🚀 Starting LM Studio..." -ForegroundColor Green
        Start-Process $LMStudioPath
    }
}

Write-Host "✅ Import completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Open LM Studio" -ForegroundColor White
Write-Host "2. Go to 'My Models' section" -ForegroundColor White
Write-Host "3. Your imported model configurations should be available" -ForegroundColor White
Write-Host "4. Download the models you want to use" -ForegroundColor White