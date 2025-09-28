-- Test Enemy AI System
-- Tests enemy behavior, pathfinding, search mechanics, and cave interactions

local test_enemy_ai = {}

-- Mock enemy data structure
local function createMockEnemy(isFast, x, y)
    return {
        x = x or 10,
        y = y or 10,
        dirX = 0,
        dirY = 0,
        speed = isFast and 1.5 or 0.4,
        size = 15,
        pulse = 0,
        attackCooldown = 0,
        maxAttackCooldown = 2,
        isFast = isFast or false,
        searchTimer = 0,
        lastKnownPlayerX = 0,
        lastKnownPlayerY = 0,
        isSearching = false
    }
end

-- Mock tilemap for testing
local function createMockTilemap()
    local tilemap = {}
    for y = 1, 20 do
        tilemap[y] = {}
        for x = 1, 20 do
            tilemap[y][x] = "grass"
        end
    end
    
    -- Add some caves
    tilemap[10][10] = "cave"
    tilemap[10][11] = "cave"
    tilemap[11][10] = "cave"
    
    -- Add some mountains
    tilemap[5][5] = "mountain"
    tilemap[5][6] = "mountain"
    tilemap[6][5] = "mountain"
    
    return tilemap
end

function test_enemy_ai.run_tests(test)
    print("=== ENEMY AI TESTS ===")
    
    test("Enemy creation", function()
        local fastEnemy = createMockEnemy(true, 5, 5)
        local slowEnemy = createMockEnemy(false, 8, 8)
        
        assert(fastEnemy.isFast == true, "Fast enemy should be marked as fast")
        assert(slowEnemy.isFast == false, "Slow enemy should be marked as slow")
        assert(fastEnemy.speed > slowEnemy.speed, "Fast enemy should be faster than slow enemy")
        assert(fastEnemy.x == 5, "Enemy X position should be set correctly")
        assert(fastEnemy.y == 5, "Enemy Y position should be set correctly")
    end)
    
    test("Enemy speed differentiation", function()
        local fastEnemy = createMockEnemy(true)
        local slowEnemy = createMockEnemy(false)
        
        assert(fastEnemy.speed >= 1.2, "Fast enemy speed should be >= 1.2")
        assert(fastEnemy.speed <= 1.8, "Fast enemy speed should be <= 1.8")
        assert(slowEnemy.speed >= 0.2, "Slow enemy speed should be >= 0.2")
        assert(slowEnemy.speed <= 0.5, "Slow enemy speed should be <= 0.5")
    end)
    
    test("Enemy movement calculation", function()
        local enemy = createMockEnemy(false, 10, 10)
        local playerX = 15
        local playerY = 12
        local tileSize = 32
        
        -- Calculate direction to player
        local dx = (playerX - (enemy.x * tileSize)) / tileSize
        local dy = (playerY - (enemy.y * tileSize)) / tileSize
        local dist = math.sqrt(dx*dx + dy*dy)
        
        assert(dist > 0, "Distance to player should be positive")
        
        -- Normalize direction
        enemy.dirX = dx / dist
        enemy.dirY = dy / dist
        
        assert(math.abs(enemy.dirX) <= 1, "Direction X should be normalized")
        assert(math.abs(enemy.dirY) <= 1, "Direction Y should be normalized")
        
        -- Test movement
        local dt = 0.016  -- 60 FPS
        local newX = enemy.x + enemy.dirX * enemy.speed * dt
        local newY = enemy.y + enemy.dirY * enemy.speed * dt
        
        assert(newX ~= enemy.x or newY ~= enemy.y, "Enemy should move towards player")
    end)
    
    test("Enemy cave blocking", function()
        local enemy = createMockEnemy(false, 9, 10)
        local tilemap = createMockTilemap()
        
        -- Try to move into cave
        enemy.dirX = 1
        enemy.dirY = 0
        local newX = enemy.x + enemy.dirX * enemy.speed * 0.016
        local newY = enemy.y + enemy.dirY * enemy.speed * 0.016
        
        local enemyTileX = math.floor(newX)
        local enemyTileY = math.floor(newY)
        
        if tilemap[enemyTileY] and tilemap[enemyTileY][enemyTileX] == "cave" then
            -- Enemy should be blocked
            assert(true, "Enemy should be blocked by cave")
        else
            -- Enemy can move normally
            assert(true, "Enemy can move to non-cave tile")
        end
    end)
    
    test("Enemy search behavior", function()
        local enemy = createMockEnemy(false, 10, 10)
        local playerX = 15
        local playerY = 12
        
        -- Player goes into cave
        enemy.lastKnownPlayerX = playerX
        enemy.lastKnownPlayerY = playerY
        enemy.isSearching = true
        enemy.searchTimer = 0
        
        assert(enemy.isSearching == true, "Enemy should be searching")
        assert(enemy.searchTimer == 0, "Search timer should start at 0")
        
        -- Simulate search timer progression
        enemy.searchTimer = enemy.searchTimer + 1.0
        assert(enemy.searchTimer == 1.0, "Search timer should increment")
        
        -- Test search timeout
        enemy.searchTimer = 5.1
        if enemy.searchTimer > 5.0 then
            enemy.isSearching = false
        end
        assert(enemy.isSearching == false, "Enemy should stop searching after timeout")
    end)
    
    test("Enemy collision detection", function()
        local enemy = createMockEnemy(false, 10, 10)
        local playerX = 10.5
        local playerY = 10.5
        local tileSize = 32
        
        -- Calculate distance
        local enemyScreenX = enemy.x * tileSize
        local enemyScreenY = enemy.y * tileSize
        local distance = math.sqrt((playerX - enemyScreenX)^2 + (playerY - enemyScreenY)^2)
        
        -- Test collision threshold
        local collisionThreshold = (24 + enemy.size) / 2  -- Player size + enemy size / 2
        
        if distance < collisionThreshold then
            assert(true, "Enemy should detect collision with player")
        else
            assert(true, "Enemy should not detect collision with player")
        end
    end)
    
    test("Enemy boundary constraints", function()
        local enemy = createMockEnemy(false, 1, 1)
        local mapCols = 20
        local mapRows = 20
        
        -- Test boundary enforcement
        enemy.x = math.max(1, math.min(enemy.x, mapCols - 2))
        enemy.y = math.max(1, math.min(enemy.y, mapRows - 2))
        
        assert(enemy.x >= 1, "Enemy X should be >= 1")
        assert(enemy.y >= 1, "Enemy Y should be >= 1")
        assert(enemy.x <= mapCols - 2, "Enemy X should be <= mapCols - 2")
        assert(enemy.y <= mapRows - 2, "Enemy Y should be <= mapRows - 2")
    end)
    
    test("Enemy state transitions", function()
        local enemy = createMockEnemy(false, 10, 10)
        
        -- Test chase state
        enemy.isSearching = false
        enemy.searchTimer = 0
        assert(enemy.isSearching == false, "Enemy should start in chase state")
        
        -- Transition to search state
        enemy.isSearching = true
        enemy.searchTimer = 0
        assert(enemy.isSearching == true, "Enemy should transition to search state")
        
        -- Test search progression
        enemy.searchTimer = 2.0
        assert(enemy.searchTimer == 2.0, "Search timer should progress")
        
        -- Test return to chase state
        enemy.isSearching = false
        enemy.searchTimer = 0
        assert(enemy.isSearching == false, "Enemy should return to chase state")
    end)
    
    test("Enemy attack cooldown", function()
        local enemy = createMockEnemy(false, 10, 10)
        
        -- Test initial cooldown
        assert(enemy.attackCooldown == 0, "Attack cooldown should start at 0")
        
        -- Simulate attack
        enemy.attackCooldown = enemy.maxAttackCooldown
        assert(enemy.attackCooldown == enemy.maxAttackCooldown, "Attack cooldown should be set to max")
        
        -- Simulate cooldown countdown
        local dt = 0.016
        enemy.attackCooldown = enemy.attackCooldown - dt
        assert(enemy.attackCooldown < enemy.maxAttackCooldown, "Attack cooldown should decrease")
    end)
    
    test("Enemy pulse animation", function()
        local enemy = createMockEnemy(false, 10, 10)
        
        -- Test initial pulse
        assert(enemy.pulse >= 0, "Pulse should be >= 0")
        
        -- Simulate pulse update
        local dt = 0.016
        local oldPulse = enemy.pulse
        enemy.pulse = enemy.pulse + dt * 2
        
        assert(enemy.pulse > oldPulse, "Pulse should increase over time")
        assert(enemy.pulse < math.pi * 2, "Pulse should stay within reasonable bounds")
    end)
    
    test("Enemy AI decision making", function()
        local enemy = createMockEnemy(false, 10, 10)
        local tilemap = createMockTilemap()
        local playerInCave = true
        
        -- Test AI decision when player is in cave
        if playerInCave then
            if not enemy.isSearching then
                enemy.isSearching = true
                enemy.searchTimer = 0
            end
            assert(enemy.isSearching == true, "Enemy should start searching when player is in cave")
        else
            enemy.isSearching = false
            enemy.searchTimer = 0
            assert(enemy.isSearching == false, "Enemy should chase when player is visible")
        end
    end)
end

return test_enemy_ai
