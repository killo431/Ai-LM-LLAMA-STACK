# LM Studio Model Configuration Updater
# Updates configurations for already downloaded models

param(
    [Parameter(Mandatory=$false)]
    [string]$JsonPath = "lm_studio_model_bundle_custom.json",
    
    [Parameter(Mandatory=$false)]
    [string]$ModelFilter = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DetailedOutput = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$ListOnly = $false
)

# LM Studio directories
$LMStudioConfigDir = "$env:USERPROFILE\.lmstudio"
$UserConfigDir = Join-Path $LMStudioConfigDir ".internal\user-concrete-model-default-config"
$ModelsDir = Join-Path $LMStudioConfigDir "models"

Write-Host "=== LM Studio Model Configuration Updater ===" -ForegroundColor Cyan
Write-Host "User: killo431" -ForegroundColor Green
Write-Host "Date: 2025-09-21 18:11:41" -ForegroundColor Gray
Write-Host ""

# Function to find downloaded models
function Get-DownloadedModels {
    $downloadedModels = @()
    
    if (Test-Path $ModelsDir) {
        Get-ChildItem $ModelsDir -Recurse -Filter "*.gguf" | ForEach-Object {
            $relativePath = $_.FullName.Replace($ModelsDir, "").TrimStart("\").Replace("\", "/")
            $downloadedModels += @{
                "FileName" = $_.Name
                "FullPath" = $_.FullName
                "RelativePath" = $relativePath
                "Size" = "{0:F2} GB" -f ($_.Length / 1GB)
                "LastModified" = $_.LastWriteTime
            }
        }
    }
    
    return $downloadedModels
}

# Function to find existing config files
function Get-ExistingConfigs {
    $existingConfigs = @()
    
    if (Test-Path $UserConfigDir) {
        Get-ChildItem $UserConfigDir -Recurse -Filter "*.json" | ForEach-Object {
            try {
                $configContent = Get-Content $_.FullName -Raw | ConvertFrom-Json
                $relativePath = $_.FullName.Replace($UserConfigDir, "").TrimStart("\").Replace("\", "/")
                
                $existingConfigs += @{
                    "ConfigPath" = $_.FullName
                    "RelativePath" = $relativePath
                    "ModelName" = $configContent.name
                    "Source" = $configContent.source
                    "Family" = $configContent.family
                    "LastModified" = $_.LastWriteTime
                    "Content" = $configContent
                }
            }
            catch {
                Write-Warning "Could not parse config file: $($_.FullName)"
            }
        }
    }
    
    return $existingConfigs
}

# Function to match downloaded models with config templates
function Find-ModelMatches {
    param(
        [array]$DownloadedModels,
        [array]$ConfigTemplates
    )
    
    $matches = @()
    
    foreach ($downloaded in $DownloadedModels) {
        foreach ($template in $ConfigTemplates) {
            # Try to match by model name patterns
            $templateNamePattern = $template.name.Replace(" ", "[-_]?").Replace("'", "")
            $downloadedNameNormalized = $downloaded.FileName.Replace("-", "").Replace("_", "").Replace(".", "")
            $templateNameNormalized = $template.name.Replace(" ", "").Replace("-", "").Replace("_", "").Replace("'", "")
            
            if ($downloaded.FileName -match $templateNamePattern -or 
                $downloadedNameNormalized -match $templateNameNormalized -or
                $downloaded.FileName.ToLower().Contains($template.name.ToLower().Replace(" ", "")) -or
                $template.name.ToLower().Contains($downloaded.FileName.Split(".")[0].ToLower())) {
                
                $matches += @{
                    "DownloadedModel" = $downloaded
                    "ConfigTemplate" = $template
                    "MatchType" = "Pattern"
                }
                break
            }
        }
    }
    
    return $matches
}

# Function to create updated config file
function Update-ModelConfig {
    param(
        [hashtable]$Match,
        [string]$ConfigDir
    )
    
    $model = $Match.ConfigTemplate
    $downloaded = $Match.DownloadedModel
    
    # Create directory structure
    $modelDir = Join-Path $ConfigDir $model.source
    $modelSubDir = Join-Path $modelDir $model.name.Replace(" ", "-").Replace("'", "")
    
    if (-not (Test-Path $modelSubDir)) {
        New-Item -ItemType Directory -Path $modelSubDir -Force | Out-Null
    }
    
    # Create config file name
    $configFileName = $downloaded.FileName.Replace(".gguf", ".json")
    $configFilePath = Join-Path $modelSubDir $configFileName
    
    # Create updated config
    $configContent = @{
        "modelPath" = $downloaded.RelativePath
        "name" = $model.name
        "description" = $model.description + " (Updated: $(Get-Date -Format 'yyyy-MM-dd'))"
        "family" = $model.model_family
        "quantization" = $model.quantization
        "size" = $downloaded.Size
        "contextLength" = $model.context_length
        "source" = $model.source
        "localPath" = $downloaded.FullPath
        "defaultParams" = $model.default_params
        "metadata" = @{
            "importedBy" = "PowerShell Config Updater"
            "importDate" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            "version" = "2.0"
            "user" = "killo431"
            "lastUpdated" = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            "originalSize" = $model.size
            "actualSize" = $downloaded.Size
        }
    }
    
    # Write config file
    $configContent | ConvertTo-Json -Depth 10 | Set-Content $configFilePath -Encoding UTF8
    
    return $configFilePath
}

# Function to backup existing configs
function Backup-ExistingConfigs {
    param([string]$ConfigDir)
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupDir = Join-Path $ConfigDir "backups\update_backup_$timestamp"
    
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    
    if (Test-Path $UserConfigDir) {
        Copy-Item $UserConfigDir $backupDir -Recurse -Force
        Write-Host "✓ Backed up existing configs to: $backupDir" -ForegroundColor Green
    }
    
    return $backupDir
}

# Main execution
Write-Host "🔍 Scanning for downloaded models..." -ForegroundColor Yellow
$downloadedModels = Get-DownloadedModels

if ($downloadedModels.Count -eq 0) {
    Write-Host "No downloaded models found in: $ModelsDir" -ForegroundColor Yellow
    exit 0
}

Write-Host "✓ Found $($downloadedModels.Count) downloaded models" -ForegroundColor Green

if ($DetailedOutput) {
    Write-Host ""
    Write-Host "📋 Downloaded Models:" -ForegroundColor Cyan
    foreach ($model in $downloadedModels) {
        Write-Host "  • $($model.FileName) ($($model.Size))" -ForegroundColor White
    }
}

if ($ListOnly) {
    Write-Host ""
    Write-Host "📋 Current Downloaded Models:" -ForegroundColor Cyan
    $downloadedModels | ForEach-Object {
        Write-Host "  📄 $($_.FileName)" -ForegroundColor White
        Write-Host "     Size: $($_.Size)" -ForegroundColor Gray
        Write-Host "     Modified: $($_.LastModified)" -ForegroundColor Gray
        Write-Host "     Path: $($_.RelativePath)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "📋 Existing Configurations:" -ForegroundColor Cyan
    $existingConfigs = Get-ExistingConfigs
    if ($existingConfigs.Count -gt 0) {
        $existingConfigs | ForEach-Object {
            Write-Host "  ⚙️  $($_.ModelName)" -ForegroundColor White
            Write-Host "     Source: $($_.Source)" -ForegroundColor Gray
            Write-Host "     Config: $($_.RelativePath)" -ForegroundColor Gray
            Write-Host ""
        }
    } else {
        Write-Host "  No existing configurations found." -ForegroundColor Gray
    }
    exit 0
}

# Load config templates
if (-not (Test-Path $JsonPath)) {
    Write-Error "JSON template file not found: $JsonPath"
    exit 1
}

$configTemplates = Get-Content $JsonPath -Raw | ConvertFrom-Json
Write-Host "📄 Loaded $($configTemplates.Count) configuration templates" -ForegroundColor Green

# Find matches
Write-Host "🔍 Matching downloaded models with configuration templates..." -ForegroundColor Yellow
$matches = Find-ModelMatches -DownloadedModels $downloadedModels -ConfigTemplates $configTemplates

if ($matches.Count -eq 0) {
    Write-Host "No matches found between downloaded models and configuration templates." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "💡 Suggestions:" -ForegroundColor Cyan
    Write-Host "1. Check if your model names in the JSON match your downloaded models" -ForegroundColor White
    Write-Host "2. Use -ListOnly to see all downloaded models and existing configs" -ForegroundColor White
    Write-Host "3. Manually update the JSON template with correct model names" -ForegroundColor White
    exit 0
}

Write-Host "✓ Found $($matches.Count) matches" -ForegroundColor Green

if ($DetailedOutput) {
    Write-Host ""
    Write-Host "📋 Matches Found:" -ForegroundColor Cyan
    foreach ($match in $matches) {
        Write-Host "  🔗 $($match.DownloadedModel.FileName) ↔ $($match.ConfigTemplate.name)" -ForegroundColor White
    }
}

# Apply filter if specified
if ($ModelFilter) {
    $matches = $matches | Where-Object { $_.DownloadedModel.FileName -like "*$ModelFilter*" -or $_.ConfigTemplate.name -like "*$ModelFilter*" }
    Write-Host "🔍 Filtered to $($matches.Count) matches based on filter: $ModelFilter" -ForegroundColor Yellow
}

if ($matches.Count -eq 0) {
    Write-Host "No matches found after applying filter." -ForegroundColor Yellow
    exit 0
}

# Confirm update
if (-not $Force) {
    Write-Host ""
    Write-Host "⚠️  This will update configurations for $($matches.Count) models." -ForegroundColor Yellow
    $continue = Read-Host "Continue? (y/N)"
    if ($continue -ne 'y' -and $continue -ne 'Y') {
        Write-Host "Update cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Create backup
Write-Host "💾 Creating backup..." -ForegroundColor Yellow
$backupPath = Backup-ExistingConfigs -ConfigDir $LMStudioConfigDir

# Update configurations
Write-Host "📥 Updating model configurations..." -ForegroundColor Yellow
$updatedCount = 0
$failedCount = 0

foreach ($match in $matches) {
    try {
        Write-Host "Updating: $($match.DownloadedModel.FileName)" -ForegroundColor Cyan
        
        $configPath = Update-ModelConfig -Match $match -ConfigDir $UserConfigDir
        $updatedCount++
        
        if ($DetailedOutput) {
            Write-Host "  ✓ Updated config: $configPath" -ForegroundColor Green
            Write-Host "  📊 Size: $($match.DownloadedModel.Size)" -ForegroundColor Gray
            Write-Host "  🏷️  Template: $($match.ConfigTemplate.name)" -ForegroundColor Gray
        }
    }
    catch {
        Write-Warning "Failed to update config for '$($match.DownloadedModel.FileName)': $_"
        $failedCount++
    }
}

# Summary
Write-Host ""
Write-Host "=== Update Summary ===" -ForegroundColor Cyan
Write-Host "Successfully updated: $updatedCount configurations" -ForegroundColor Green
Write-Host "Failed: $failedCount configurations" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Green" })
Write-Host "Backup location: $backupPath" -ForegroundColor White
Write-Host ""

Write-Host "✅ Configuration update completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Restart LM Studio to load updated configurations" -ForegroundColor White
Write-Host "2. Check 'My Models' for updated parameter settings" -ForegroundColor White
Write-Host "3. Your downloaded models now use optimized configurations" -ForegroundColor White

# GitHub integration note
Write-Host ""
Write-Host "💡 Consider committing updated configs to your AI_STACK repository!" -ForegroundColor Cyan
Write-Host "Repository: https://github.com/killo431/AI_STACK" -ForegroundColor Blue