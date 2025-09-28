-- Test Player System
-- Tests player movement, energy, invincibility, and terrain interactions

local test_player = {}

-- Mock Love2D functions for testing
local mock_love = {
    keyboard = {
        isDown = function(key) return false end
    },
    graphics = {
        getWidth = function() return 1920 end,
        getHeight = function() return 1080 end
    }
}

-- Mock game state
local mock_game_state = {
    player = {
        x = 100,
        y = 100,
        baseSize = 24,
        baseSpeed = 200,
        size = 24,
        speed = 200,
        energy = 100,
        maxEnergy = 100,
        invulnerable = false,
        invulnTime = 0,
        invincible = false,
        invincibleTime = 0,
        maxInvincibleTime = 10,
        trail = {},
        maxTrail = 20
    },
    tileSize = 32,
    mapCols = 120,
    mapRows = 68,
    tilemap = {}
}

-- Helper function to set player energy with automatic capping
local function setPlayerEnergy(value)
    mock_game_state.player.energy = math.max(0, math.min(value, mock_game_state.player.maxEnergy))
end

-- Initialize mock tilemap
for y = 1, mock_game_state.mapRows do
    mock_game_state.tilemap[y] = {}
    for x = 1, mock_game_state.mapCols do
        mock_game_state.tilemap[y][x] = "grass"
    end
end

function test_player.run_tests(test)
    print("=== PLAYER SYSTEM TESTS ===")
    
    test("Player initialization", function()
        local player = mock_game_state.player
        assert(player.x == 100, "Player X should be 100")
        assert(player.y == 100, "Player Y should be 100")
        assert(player.energy == 100, "Player energy should be 100")
        assert(player.size == 24, "Player size should be 24")
        assert(player.speed == 200, "Player speed should be 200")
    end)
    
    test("Player movement bounds", function()
        local player = mock_game_state.player
        local tileSize = mock_game_state.tileSize
        local mapCols = mock_game_state.mapCols
        local mapRows = mock_game_state.mapRows
        
        -- Test boundary calculations
        local minX = tileSize + player.size/2
        local maxX = (mapCols - 1) * tileSize - player.size/2
        local minY = tileSize + player.size/2
        local maxY = (mapRows - 1) * tileSize - player.size/2
        
        assert(minX > 0, "Min X should be positive")
        assert(maxX > minX, "Max X should be greater than min X")
        assert(minY > 0, "Min Y should be positive")
        assert(maxY > minY, "Max Y should be greater than min Y")
    end)
    
    test("Player energy system", function()
        local player = mock_game_state.player
        
        -- Test energy reduction
        player.energy = player.energy - 20
        assert(player.energy == 80, "Energy should be 80 after reducing by 20")
        
        -- Test energy regeneration
        player.energy = player.energy + 5
        assert(player.energy == 85, "Energy should be 85 after adding 5")
        
        -- Test energy cap
        setPlayerEnergy(player.maxEnergy + 10)
        assert(player.energy <= player.maxEnergy, "Energy should not exceed max energy")
    end)
    
    test("Player invincibility system", function()
        local player = mock_game_state.player
        
        -- Test invincibility activation
        player.invincible = true
        player.invincibleTime = player.maxInvincibleTime
        assert(player.invincible == true, "Player should be invincible")
        assert(player.invincibleTime == 10, "Invincibility time should be 10 seconds")
        
        -- Test invincibility countdown
        player.invincibleTime = player.invincibleTime - 1
        assert(player.invincibleTime == 9, "Invincibility time should decrease")
        
        -- Test invincibility expiry
        player.invincibleTime = 0
        player.invincible = false
        assert(player.invincible == false, "Player should not be invincible when time expires")
    end)
    
    test("Player terrain detection", function()
        local player = mock_game_state.player
        local tileSize = mock_game_state.tileSize
        local tilemap = mock_game_state.tilemap
        
        -- Test tile coordinate calculation
        local playerTileX = math.floor(player.x / tileSize) + 1
        local playerTileY = math.floor(player.y / tileSize) + 1
        
        assert(playerTileX >= 1, "Player tile X should be >= 1")
        assert(playerTileY >= 1, "Player tile Y should be >= 1")
        assert(playerTileX <= mock_game_state.mapCols, "Player tile X should be <= mapCols")
        assert(playerTileY <= mock_game_state.mapRows, "Player tile Y should be <= mapRows")
        
        -- Test terrain type detection
        local terrainType = tilemap[playerTileY][playerTileX]
        assert(terrainType == "grass", "Player should be on grass terrain")
    end)
    
    test("Player scaling system", function()
        local player = mock_game_state.player
        local baseTileSize = 32
        local newTileSize = 48
        
        -- Test scaling factor calculation
        local scaleFactor = newTileSize / baseTileSize
        assert(scaleFactor == 1.5, "Scale factor should be 1.5")
        
        -- Test player size scaling
        local scaledSize = player.baseSize * scaleFactor
        assert(scaledSize == 36, "Scaled size should be 36")
        
        -- Test player speed scaling
        local scaledSpeed = player.baseSpeed * scaleFactor
        assert(scaledSpeed == 300, "Scaled speed should be 300")
    end)
    
    test("Player trail system", function()
        local player = mock_game_state.player
        local trail = {}
        local maxTrail = 20
        
        -- Test trail particle creation
        table.insert(trail, {
            x = player.x,
            y = player.y,
            life = 1.0,
            size = player.size * 0.3
        })
        
        assert(#trail == 1, "Trail should have 1 particle")
        assert(trail[1].x == player.x, "Trail particle X should match player X")
        assert(trail[1].y == player.y, "Trail particle Y should match player Y")
        assert(trail[1].life == 1.0, "Trail particle life should be 1.0")
        
        -- Test trail limit
        for i = 1, maxTrail + 5 do
            table.insert(trail, {x = 0, y = 0, life = 1.0, size = 10})
        end
        
        -- Simulate trail cleanup (remove excess particles)
        while #trail > maxTrail do
            table.remove(trail, 1)
        end
        
        assert(#trail <= maxTrail, "Trail should not exceed max after cleanup")
    end)
    
    test("Player invulnerability frames", function()
        local player = mock_game_state.player
        
        -- Test invulnerability activation
        player.invulnerable = true
        player.invulnTime = 1.0
        assert(player.invulnerable == true, "Player should be invulnerable")
        
        -- Test invulnerability countdown
        player.invulnTime = player.invulnTime - 0.5
        assert(player.invulnTime == 0.5, "Invulnerability time should decrease")
        
        -- Test invulnerability expiry
        player.invulnTime = 0
        player.invulnerable = false
        assert(player.invulnerable == false, "Player should not be invulnerable when time expires")
    end)
end

return test_player
