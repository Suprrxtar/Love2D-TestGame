# PowerShell script to generate test coverage report
# Run with: .\generate_coverage_report.ps1

Write-Host "Generating Test Coverage Report for Earth Survival Game..." -ForegroundColor Green
Write-Host ""

# Check if lua is available
$luaExe = Get-Command lua -ErrorAction SilentlyContinue
if (-not $luaExe) {
    Write-Host "Error: Lua interpreter not found in PATH" -ForegroundColor Red
    Write-Host "Please install Lua or add it to your PATH" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Alternatively, you can run the coverage report through Love2D:" -ForegroundColor Yellow
    Write-Host "& 'C:\Program Files\LOVE\love.exe' test_project" -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Running coverage analysis..." -ForegroundColor Yellow
lua generate_coverage_report.lua

Write-Host ""
Write-Host "Coverage report generation completed!" -ForegroundColor Green

# Check if coverage report was created
if (Test-Path "coverage_report.txt") {
    Write-Host ""
    Write-Host "Coverage report saved to: coverage_report.txt" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Would you like to view the report? (y/n)" -ForegroundColor Yellow
    $response = Read-Host
    if ($response -eq "y" -or $response -eq "Y") {
        Get-Content "coverage_report.txt" | ForEach-Object {
            if ($_ -match "✓") {
                Write-Host $_ -ForegroundColor Green
            } elseif ($_ -match "✗") {
                Write-Host $_ -ForegroundColor Red
            } elseif ($_ -match "⚠") {
                Write-Host $_ -ForegroundColor Yellow
            } else {
                Write-Host $_
            }
        }
    }
} else {
    Write-Host "Warning: Coverage report file not found" -ForegroundColor Yellow
}

Read-Host "Press Enter to exit"
