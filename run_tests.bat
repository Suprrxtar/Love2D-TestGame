@echo off
echo Running Earth Survival Game Tests...
echo.

REM Check if Love2D is installed
where love >nul 2>nul
if %errorlevel% neq 0 (
    echo Error: Love2D is not installed or not in PATH
    echo Please install Love2D from https://love2d.org/
    pause
    exit /b 1
)

REM Run the tests
echo Starting test execution...
love test_project

echo.
echo Tests completed!
pause
