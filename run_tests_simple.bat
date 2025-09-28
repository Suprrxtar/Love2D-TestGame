@echo off
echo Running Earth Survival Game Tests...
echo.

REM Check if Love2D is installed
if exist "C:\Program Files\LOVE\love.exe" (
    echo Love2D found at: C:\Program Files\LOVE\love.exe
    echo.
    echo Starting tests...
    "C:\Program Files\LOVE\love.exe" test_project
) else (
    if exist "C:\Program Files (x86)\LOVE\love.exe" (
        echo Love2D found at: C:\Program Files (x86)\LOVE\love.exe
        echo.
        echo Starting tests...
        "C:\Program Files (x86)\LOVE\love.exe" test_project
    ) else (
        echo Error: Love2D not found!
        echo Please install Love2D from https://love2d.org/
        pause
        exit /b 1
    )
)

echo.
echo Tests completed!
pause
