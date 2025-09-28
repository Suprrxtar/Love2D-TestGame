# PowerShell script to run Earth Survival Game Tests
# Run this script with: .\run_tests.ps1

Write-Host "Running Earth Survival Game Tests..." -ForegroundColor Green
Write-Host ""

# Check if Love2D is installed
$loveExe = $null

# First try to find it in PATH
try {
    $null = Get-Command love -ErrorAction Stop
    $loveExe = "love"
    Write-Host "Love2D found in PATH. Starting test execution..." -ForegroundColor Yellow
} catch {
    # Check common installation paths
    $commonPaths = @(
        "C:\Program Files\LOVE\love.exe",
        "C:\Program Files (x86)\LOVE\love.exe",
        "C:\Users\$env:USERNAME\AppData\Local\LOVE\love.exe"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $loveExe = $path
            Write-Host "Love2D found at: $path" -ForegroundColor Yellow
            Write-Host "Starting test execution..." -ForegroundColor Yellow
            break
        }
    }
    
    if (-not $loveExe) {
        Write-Host "Error: Love2D is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Love2D from https://love2d.org/" -ForegroundColor Yellow
        Write-Host "Or add Love2D to your PATH environment variable" -ForegroundColor Yellow
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Run the tests
try {
    Write-Host "Running tests..." -ForegroundColor Yellow
    & $loveExe test_project
    
    # Wait a moment for the file to be written
    Start-Sleep -Seconds 2
    
    # Check if test results file exists and display it
    $testResultsFile = "test_results.txt"
    if (Test-Path $testResultsFile) {
        Write-Host ""
        Write-Host "=== TEST RESULTS ===" -ForegroundColor Cyan
        Get-Content $testResultsFile | ForEach-Object {
            if ($_ -match "PASSED") {
                Write-Host $_ -ForegroundColor Green
            } elseif ($_ -match "FAILED") {
                Write-Host $_ -ForegroundColor Red
            } elseif ($_ -match "TEST RESULTS SUMMARY") {
                Write-Host $_ -ForegroundColor Cyan
            } elseif ($_ -match "Total Tests|Passed|Failed|Success Rate") {
                Write-Host $_ -ForegroundColor Yellow
            } else {
                Write-Host $_
            }
        }
        Write-Host "===================" -ForegroundColor Cyan
    } else {
        Write-Host "Test results file not found. Check the Love2D window for output." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Tests completed!" -ForegroundColor Green
} catch {
    Write-Host "Error running tests: $_" -ForegroundColor Red
}

Read-Host "Press Enter to exit"
