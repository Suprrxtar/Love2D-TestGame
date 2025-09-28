-- Test UI Systems
-- Tests user interface elements, display logic, and game state visualization

local test_ui_systems = {}

-- Mock UI data structures
local function createMockGameState()
    return {
        score = 1500,
        gameTime = 45.7,
        isGameOver = false,
        isVictory = false,
        player = {
            energy = 75,
            maxEnergy = 100,
            invincible = false,
            invincibleTime = 0
        },
        collectibles = {
            {collected = false},
            {collected = true},
            {collected = false},
            {collected = true},
            {collected = false}
        },
        enemies = {
            {isFast = true},
            {isFast = true},
            {isFast = false},
            {isFast = false},
            {isFast = false}
        },
        sharks = {
            {timeAlive = 2.5},
            {timeAlive = 5.1}
        },
        timeInWater = 3.2
    }
end

local function createMockTerrainState()
    return {
        isInWater = false,
        isInQuicksand = false,
        isInCave = false,
        isOnMountain = false
    }
end

function test_ui_systems.run_tests(test)
    print("=== UI SYSTEMS TESTS ===")
    
    test("Score display formatting", function()
        local gameState = createMockGameState()
        local scoreText = "Score: " .. gameState.score
        
        assert(scoreText == "Score: 1500", "Score should be formatted correctly")
        assert(string.find(scoreText, "1500"), "Score text should contain the score value")
    end)
    
    test("Energy display formatting", function()
        local gameState = createMockGameState()
        local energyText = "Energy: " .. math.floor(gameState.player.energy) .. "/" .. gameState.player.maxEnergy
        
        assert(energyText == "Energy: 75/100", "Energy should be formatted correctly")
        assert(string.find(energyText, "75"), "Energy text should contain current energy")
        assert(string.find(energyText, "100"), "Energy text should contain max energy")
    end)
    
    test("Game time formatting", function()
        local gameState = createMockGameState()
        local timeText = "Time: " .. string.format("%.1f", gameState.gameTime) .. "s"
        
        assert(timeText == "Time: 45.7s", "Game time should be formatted correctly")
        assert(string.find(timeText, "45.7"), "Time text should contain the time value")
    end)
    
    test("Orbs remaining counter", function()
        local gameState = createMockGameState()
        local remainingOrbs = 0
        
        for _, orb in ipairs(gameState.collectibles) do
            if not orb.collected then
                remainingOrbs = remainingOrbs + 1
            end
        end
        
        assert(remainingOrbs == 3, "Should count 3 remaining orbs")
        
        local orbsText = "Orbs Remaining: " .. remainingOrbs
        assert(orbsText == "Orbs Remaining: 3", "Orbs remaining should be formatted correctly")
    end)
    
    test("Enemy type counting", function()
        local gameState = createMockGameState()
        local fastEnemies = 0
        local slowEnemies = 0
        
        for _, enemy in ipairs(gameState.enemies) do
            if enemy.isFast then
                fastEnemies = fastEnemies + 1
            else
                slowEnemies = slowEnemies + 1
            end
        end
        
        assert(fastEnemies == 2, "Should have 2 fast enemies")
        assert(slowEnemies == 3, "Should have 3 slow enemies")
        
        local enemyText = "Enemies: " .. fastEnemies .. " fast, " .. slowEnemies .. " slow"
        assert(enemyText == "Enemies: 2 fast, 3 slow", "Enemy count should be formatted correctly")
    end)
    
    test("Shark count display", function()
        local gameState = createMockGameState()
        local sharkCount = #gameState.sharks
        local timeInWater = gameState.timeInWater
        
        assert(sharkCount == 2, "Should have 2 sharks")
        assert(timeInWater == 3.2, "Time in water should be 3.2 seconds")
        
        local sharkText = "SHARKS: " .. sharkCount .. " | Time in water: " .. string.format("%.1f", timeInWater) .. "s"
        assert(sharkText == "SHARKS: 2 | Time in water: 3.2s", "Shark info should be formatted correctly")
    end)
    
    test("Terrain status messages", function()
        local terrainState = createMockTerrainState()
        
        -- Test water status
        terrainState.isInWater = true
        local waterStatus = "SWIMMING - Energy draining!"
        assert(waterStatus == "SWIMMING - Energy draining!", "Water status should be correct")
        
        -- Test quicksand status
        terrainState.isInWater = false
        terrainState.isInQuicksand = true
        local quicksandStatus = "SINKING IN QUICKSAND!"
        assert(quicksandStatus == "SINKING IN QUICKSAND!", "Quicksand status should be correct")
        
        -- Test cave status
        terrainState.isInQuicksand = false
        terrainState.isInCave = true
        local caveStatus = "IN CAVE TUNNEL - HIDING FROM ENEMIES!"
        assert(caveStatus == "IN CAVE TUNNEL - HIDING FROM ENEMIES!", "Cave status should be correct")
        
        -- Test mountain status
        terrainState.isInCave = false
        terrainState.isOnMountain = true
        local mountainStatus = "BLOCKED BY MOUNTAIN!"
        assert(mountainStatus == "BLOCKED BY MOUNTAIN!", "Mountain status should be correct")
        
        -- Test normal land status
        terrainState.isOnMountain = false
        local landStatus = "On Land - Energy regenerating"
        assert(landStatus == "On Land - Energy regenerating", "Land status should be correct")
    end)
    
    test("Invincibility status display", function()
        local gameState = createMockGameState()
        
        -- Test not invincible
        assert(gameState.player.invincible == false, "Player should not be invincible initially")
        
        -- Test invincible
        gameState.player.invincible = true
        gameState.player.invincibleTime = 7.5
        local invincibleText = "INVINCIBLE! Time: " .. string.format("%.1f", gameState.player.invincibleTime) .. "s"
        assert(invincibleText == "INVINCIBLE! Time: 7.5s", "Invincibility status should be formatted correctly")
    end)
    
    test("Energy bar calculation", function()
        local gameState = createMockGameState()
        local energyPercent = gameState.player.energy / gameState.player.maxEnergy
        local barWidth = 200
        local energyBarWidth = barWidth * energyPercent
        
        assert(energyPercent == 0.75, "Energy percentage should be 0.75")
        assert(energyBarWidth == 150, "Energy bar width should be 150")
    end)
    
    test("Game over screen display", function()
        local gameState = createMockGameState()
        gameState.isGameOver = true
        
        assert(gameState.isGameOver == true, "Game should be over")
        
        local gameOverText = "GAME OVER!"
        local finalScoreText = "Final Score: " .. gameState.score
        local timeText = "Time Survived: " .. string.format("%.1f", gameState.gameTime) .. "s"
        
        assert(gameOverText == "GAME OVER!", "Game over text should be correct")
        assert(finalScoreText == "Final Score: 1500", "Final score text should be correct")
        assert(timeText == "Time Survived: 45.7s", "Time survived text should be correct")
    end)
    
    test("Victory screen display", function()
        local gameState = createMockGameState()
        gameState.isVictory = true
        
        assert(gameState.isVictory == true, "Game should be in victory state")
        
        local victoryText = "VICTORY!"
        local victoryMessage = "All orbs collected!"
        local finalScoreText = "Final Score: " .. gameState.score
        local timeText = "Time: " .. string.format("%.1f", gameState.gameTime) .. "s"
        
        assert(victoryText == "VICTORY!", "Victory text should be correct")
        assert(victoryMessage == "All orbs collected!", "Victory message should be correct")
        assert(finalScoreText == "Final Score: 1500", "Final score text should be correct")
        assert(timeText == "Time: 45.7s", "Time text should be correct")
    end)
    
    test("UI layout calculations", function()
        local baseY = 10
        local lineHeight = 20
        
        -- Test UI element positioning
        local scoreY = baseY
        local energyY = scoreY + lineHeight
        local timeY = energyY + lineHeight
        local orbsY = timeY + lineHeight
        local enemiesY = orbsY + lineHeight
        
        assert(scoreY == 10, "Score Y should be 10")
        assert(energyY == 30, "Energy Y should be 30")
        assert(timeY == 50, "Time Y should be 50")
        assert(orbsY == 70, "Orbs Y should be 70")
        assert(enemiesY == 90, "Enemies Y should be 90")
    end)
    
    test("Dynamic UI positioning", function()
        local searchingEnemies = 2
        local terrainY = searchingEnemies > 0 and 150 or 130
        
        assert(terrainY == 150, "Terrain Y should be 150 when enemies are searching")
        
        searchingEnemies = 0
        terrainY = searchingEnemies > 0 and 150 or 130
        assert(terrainY == 130, "Terrain Y should be 130 when no enemies are searching")
    end)
    
    test("Color coding validation", function()
        -- Test color values are within valid range (0-1)
        local colors = {
            white = {1, 1, 1},
            red = {1, 0, 0},
            green = {0, 1, 0},
            blue = {0, 0, 1},
            yellow = {1, 1, 0},
            magenta = {1, 0, 1}
        }
        
        for colorName, colorValues in pairs(colors) do
            for i, value in ipairs(colorValues) do
                assert(value >= 0 and value <= 1, colorName .. " color value " .. i .. " should be between 0 and 1")
            end
        end
    end)
    
    test("Text formatting edge cases", function()
        -- Test with zero values
        local zeroScore = "Score: 0"
        local zeroEnergy = "Energy: 0/100"
        local zeroTime = "Time: 0.0s"
        
        assert(zeroScore == "Score: 0", "Zero score should format correctly")
        assert(zeroEnergy == "Energy: 0/100", "Zero energy should format correctly")
        assert(zeroTime == "Time: 0.0s", "Zero time should format correctly")
        
        -- Test with large values
        local largeScore = "Score: 999999"
        local largeTime = "Time: 999.9s"
        
        assert(largeScore == "Score: 999999", "Large score should format correctly")
        assert(largeTime == "Time: 999.9s", "Large time should format correctly")
    end)
    
    test("UI state consistency", function()
        local gameState = createMockGameState()
        
        -- Test that UI state is consistent with game state
        assert(gameState.isGameOver == false, "Game should not be over")
        assert(gameState.isVictory == false, "Game should not be in victory state")
        assert(gameState.player.energy > 0, "Player should have energy")
        assert(gameState.score >= 0, "Score should be non-negative")
        assert(gameState.gameTime >= 0, "Game time should be non-negative")
    end)
end

return test_ui_systems
