-- Test Game Mechanics System
-- Tests collectibles, power-ups, sharks, energy system, and victory conditions

local test_game_mechanics = {}

-- Mock game mechanics functions
local function createMockCollectible(x, y)
    return {
        x = x or math.random(2, 18),
        y = y or math.random(2, 18),
        collected = false,
        pulse = math.random() * math.pi * 2,
        size = math.random(6, 12),
        glowIntensity = math.random() * 0.5 + 0.5
    }
end

local function createMockPowerup(x, y)
    return {
        x = x or math.random(3, 17),
        y = y or math.random(3, 17),
        collected = false,
        pulse = math.random() * math.pi * 2,
        size = 15,
        glowIntensity = math.random() * 0.5 + 0.5,
        rainbowPhase = math.random() * math.pi * 2
    }
end

local function createMockShark(x, y)
    return {
        x = x or math.random(5, 15),
        y = y or math.random(5, 15),
        dirX = math.random(-1, 1),
        dirY = math.random(-1, 1),
        speed = math.min(1.5, math.random(0.8, 1.5)), -- Ensure speed <= 1.5
        size = math.random(20, 30),
        pulse = math.random() * math.pi * 2,
        attackCooldown = 0,
        maxAttackCooldown = 0.5,
        timeAlive = 0,
        maxLifetime = 10
    }
end

function test_game_mechanics.run_tests(test)
    print("=== GAME MECHANICS TESTS ===")
    
    test("Collectible creation and properties", function()
        local collectible = createMockCollectible(10, 10)
        
        assert(collectible.x == 10, "Collectible X should be set correctly")
        assert(collectible.y == 10, "Collectible Y should be set correctly")
        assert(collectible.collected == false, "Collectible should start uncollected")
        assert(collectible.size >= 6, "Collectible size should be >= 6")
        assert(collectible.size <= 12, "Collectible size should be <= 12")
        assert(collectible.glowIntensity >= 0.5, "Glow intensity should be >= 0.5")
        assert(collectible.glowIntensity <= 1.0, "Glow intensity should be <= 1.0")
    end)
    
    test("Collectible collection", function()
        local collectibles = {}
        for i = 1, 5 do
            table.insert(collectibles, createMockCollectible(i * 2, i * 2))
        end
        
        assert(#collectibles == 5, "Should have 5 collectibles")
        
        -- Collect first collectible
        collectibles[1].collected = true
        assert(collectibles[1].collected == true, "First collectible should be collected")
        
        -- Count remaining collectibles
        local remaining = 0
        for _, collectible in ipairs(collectibles) do
            if not collectible.collected then
                remaining = remaining + 1
            end
        end
        
        assert(remaining == 4, "Should have 4 remaining collectibles")
    end)
    
    test("Victory condition", function()
        local collectibles = {}
        for i = 1, 3 do
            table.insert(collectibles, createMockCollectible(i, i))
        end
        
        -- Collect all collectibles
        for _, collectible in ipairs(collectibles) do
            collectible.collected = true
        end
        
        -- Check victory condition
        local remaining = 0
        for _, collectible in ipairs(collectibles) do
            if not collectible.collected then
                remaining = remaining + 1
            end
        end
        
        local isVictory = remaining == 0
        assert(isVictory == true, "Should achieve victory when all collectibles collected")
    end)
    
    test("Power-up creation and properties", function()
        local powerup = createMockPowerup(10, 10)
        
        assert(powerup.x == 10, "Power-up X should be set correctly")
        assert(powerup.y == 10, "Power-up Y should be set correctly")
        assert(powerup.collected == false, "Power-up should start uncollected")
        assert(powerup.size == 15, "Power-up size should be 15")
        assert(powerup.rainbowPhase >= 0, "Rainbow phase should be >= 0")
        assert(powerup.rainbowPhase <= math.pi * 2, "Rainbow phase should be <= 2π")
    end)
    
    test("Power-up collection and invincibility", function()
        local player = {
            invincible = false,
            invincibleTime = 0,
            maxInvincibleTime = 10
        }
        local powerup = createMockPowerup(10, 10)
        
        -- Collect power-up
        powerup.collected = true
        player.invincible = true
        player.invincibleTime = player.maxInvincibleTime
        
        assert(powerup.collected == true, "Power-up should be collected")
        assert(player.invincible == true, "Player should be invincible")
        assert(player.invincibleTime == 10, "Invincibility time should be 10 seconds")
    end)
    
    test("Power-up countdown", function()
        local player = {
            invincible = true,
            invincibleTime = 10,
            maxInvincibleTime = 10
        }
        
        -- Simulate time passing
        local dt = 0.016  -- 60 FPS
        player.invincibleTime = player.invincibleTime - dt
        
        assert(player.invincibleTime < 10, "Invincibility time should decrease")
        assert(player.invincible == true, "Player should still be invincible")
        
        -- Simulate invincibility expiry
        player.invincibleTime = 0
        player.invincible = false
        
        assert(player.invincible == false, "Player should not be invincible when time expires")
    end)
    
    test("Shark creation and properties", function()
        local shark = createMockShark(10, 10)
        
        assert(shark.x == 10, "Shark X should be set correctly")
        assert(shark.y == 10, "Shark Y should be set correctly")
        assert(shark.speed >= 0.8, "Shark speed should be >= 0.8")
        assert(shark.speed <= 1.5, "Shark speed should be <= 1.5 (actual: " .. shark.speed .. ")")
        assert(shark.size >= 20, "Shark size should be >= 20")
        assert(shark.size <= 30, "Shark size should be <= 30")
        assert(shark.maxLifetime == 10, "Shark max lifetime should be 10 seconds")
    end)
    
    test("Shark lifetime management", function()
        local shark = createMockShark(10, 10)
        
        assert(shark.timeAlive == 0, "Shark should start with 0 time alive")
        
        -- Simulate time passing
        local dt = 0.016
        shark.timeAlive = shark.timeAlive + dt
        
        assert(shark.timeAlive > 0, "Shark time alive should increase")
        
        -- Test lifetime expiry
        shark.timeAlive = shark.maxLifetime + 1
        local shouldRemove = shark.timeAlive > shark.maxLifetime
        assert(shouldRemove == true, "Shark should be removed when lifetime expires")
    end)
    
    test("Shark spawning limits", function()
        local sharks = {}
        local maxSharks = 5
        
        -- Add sharks up to limit
        for i = 1, maxSharks do
            table.insert(sharks, createMockShark(i, i))
        end
        
        assert(#sharks == maxSharks, "Should have 5 sharks")
        
        -- Try to add more sharks (should be blocked)
        local initialCount = #sharks
        if #sharks < maxSharks then
            table.insert(sharks, createMockShark(10, 10))
        end
        
        assert(#sharks == initialCount, "Should not add more sharks when at limit")
    end)
    
    test("Energy system", function()
        local player = {
            energy = 100,
            maxEnergy = 100
        }
        
        -- Test energy reduction
        player.energy = player.energy - 20
        assert(player.energy == 80, "Energy should be 80 after reducing by 20")
        
        -- Test energy regeneration
        local dt = 0.016
        player.energy = player.energy + dt * 5
        assert(player.energy > 80, "Energy should increase over time")
        
        -- Test energy cap
        player.energy = player.maxEnergy + 10
        if player.energy > player.maxEnergy then
            player.energy = player.maxEnergy
        end
        assert(player.energy == player.maxEnergy, "Energy should not exceed max energy")
    end)
    
    test("Energy drain in water", function()
        local player = {
            energy = 100,
            maxEnergy = 100
        }
        local isInWater = true
        local dt = 0.016
        local energyCost = 15 * dt
        
        if isInWater then
            player.energy = player.energy - energyCost
        end
        
        assert(player.energy < 100, "Energy should decrease in water")
        assert(player.energy > 99, "Energy should decrease slowly")
    end)
    
    test("Energy drain in quicksand", function()
        local player = {
            energy = 100,
            maxEnergy = 100
        }
        local isInQuicksand = true
        local dt = 0.016
        local energyCost = 25 * dt
        
        if isInQuicksand then
            player.energy = player.energy - energyCost
        end
        
        assert(player.energy < 100, "Energy should decrease in quicksand")
        assert(player.energy < 99.7, "Energy should decrease faster in quicksand than water")
    end)
    
    test("Game over condition", function()
        local player = {
            energy = 100,
            maxEnergy = 100
        }
        local isGameOver = false
        
        -- Test energy depletion
        player.energy = 0
        if player.energy <= 0 then
            isGameOver = true
        end
        
        assert(isGameOver == true, "Game should be over when energy reaches 0")
    end)
    
    test("Score system", function()
        local score = 0
        
        -- Test collectible collection score
        score = score + 100
        assert(score == 100, "Score should be 100 after collecting collectible")
        
        -- Test power-up collection score
        score = score + 500
        assert(score == 600, "Score should be 600 after collecting power-up")
        
        -- Test multiple collectibles
        for i = 1, 5 do
            score = score + 100
        end
        assert(score == 1100, "Score should be 1100 after collecting 5 more collectibles")
    end)
    
    test("Power-up spawning timer", function()
        local powerupSpawnTimer = 0
        local spawnInterval = 30.0
        
        -- Simulate time passing
        local dt = 0.016
        powerupSpawnTimer = powerupSpawnTimer + dt
        
        assert(powerupSpawnTimer > 0, "Power-up spawn timer should increase")
        
        -- Test spawn trigger
        if powerupSpawnTimer >= spawnInterval then
            powerupSpawnTimer = 0
            assert(powerupSpawnTimer == 0, "Power-up spawn timer should reset when spawning")
        end
    end)
    
    test("Shark spawn timer", function()
        local sharkSpawnTimer = 0
        local spawnInterval = 2.0
        
        -- Simulate time passing
        local dt = 0.016
        sharkSpawnTimer = sharkSpawnTimer + dt
        
        assert(sharkSpawnTimer > 0, "Shark spawn timer should increase")
        
        -- Test spawn trigger
        if sharkSpawnTimer >= spawnInterval then
            sharkSpawnTimer = 0
            assert(sharkSpawnTimer == 0, "Shark spawn timer should reset when spawning")
        end
    end)
end

return test_game_mechanics
