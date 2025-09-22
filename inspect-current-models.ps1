# Quick inspection of current LM Studio setup

$LMStudioDir = "$env:USERPROFILE\.lmstudio"
$ModelsDir = Join-Path $LMStudioDir "models"
$ConfigDir = Join-Path $LMStudioDir ".internal\user-concrete-model-default-config"

Write-Host "=== LM Studio Current State ===" -ForegroundColor Cyan
Write-Host "Date: 2025-09-21 18:11:41" -ForegroundColor Gray
Write-Host ""

# Downloaded models
Write-Host "📦 Downloaded Models:" -ForegroundColor Yellow
if (Test-Path $ModelsDir) {
    Get-ChildItem $ModelsDir -Recurse -Filter "*.gguf" | ForEach-Object {
        $size = "{0:F2} GB" -f ($_.Length / 1GB)
        Write-Host "  • $($_.Name) ($size)" -ForegroundColor White
        Write-Host "    Path: $($_.DirectoryName.Replace($ModelsDir, ''))" -ForegroundColor Gray
    }
} else {
    Write-Host "  No models directory found" -ForegroundColor Red
}

Write-Host ""

# Existing configs
Write-Host "⚙️  Existing Configurations:" -ForegroundColor Yellow
if (Test-Path $ConfigDir) {
    Get-ChildItem $ConfigDir -Recurse -Filter "*.json" | ForEach-Object {
        try {
            $config = Get-Content $_.FullName -Raw | ConvertFrom-Json
            Write-Host "  • $($config.name)" -ForegroundColor White
            Write-Host "    Source: $($config.source)" -ForegroundColor Gray
            Write-Host "    Config: $($_.FullName.Replace($ConfigDir, ''))" -ForegroundColor Gray
        } catch {
            Write-Host "  • $($_.Name) (Invalid JSON)" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  No config directory found" -ForegroundColor Red
}