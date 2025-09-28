# Test Suite Documentation

## Overview
Comprehensive test suite for Earth Survival with 100% function coverage across all game systems.

## Current Status
- **Tests**: 77 total, 100% pass rate
- **Coverage**: 100% (28/28 functions tested)
- **Systems**: 8 categories fully covered

## Test Structure

### Test Files
- `tests/test_runner.lua` - Main test runner
- `tests/test_player.lua` - Player system (8 tests)
- `tests/test_world_generation.lua` - World generation (9 tests)
- `tests/test_enemy_ai.lua` - Enemy AI (11 tests)
- `tests/test_collision_detection.lua` - Collision detection (11 tests)
- `tests/test_game_mechanics.lua` - Game mechanics (16 tests)
- `tests/test_ui_systems.lua` - UI systems (16 tests)
- `tests/test_coverage.lua` - Coverage analysis (6 tests)

## Running Tests

### Windows
```powershell
# PowerShell (recommended)
.\run_tests.ps1

# Batch file
run_tests.bat

# Simple batch (finds Love2D automatically)
run_tests_simple.bat
```

### Linux/Mac
```bash
./run_tests.sh
```

### Direct Love2D
```powershell
& "C:\Program Files\LOVE\love.exe" test_project
```

### Coverage Report Only
```powershell
.\generate_coverage_report.ps1
```

## Test Categories

- **Player System** (8 tests): Movement, energy, invincibility, trails
- **World Generation** (9 tests): Procedural generation, terrain placement, caves
- **Enemy AI** (11 tests): Pathfinding, search behavior, state transitions
- **Collision Detection** (11 tests): All collision types, boundaries, invincibility
- **Game Mechanics** (16 tests): Collectibles, power-ups, sharks, energy systems
- **UI Systems** (16 tests): Display formatting, layout calculations, status messages
- **Coverage Analysis** (6 tests): Coverage tracking and reporting system

## Coverage System

Automatically tracks function coverage across all game systems. Generates reports showing which functions are tested and overall coverage percentages.

## Coverage Status

All 28 functions across 8 game systems are fully tested with 100% coverage.

## Output

Tests generate detailed reports with pass/fail status, coverage analysis, and summary statistics. Results are saved to `test_results.txt`.

## Adding Tests

1. Create test functions in appropriate test modules
2. Use descriptive test names and clear assertions
3. Test both normal and edge cases
4. Update test runner if adding new modules
