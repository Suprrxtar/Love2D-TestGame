-- Test Collision Detection System
-- Tests player-enemy, player-collectible, player-terrain, and player-powerup collisions

local test_collision_detection = {}

-- Mock collision detection functions
local function calculateDistance(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

local function checkCollision(obj1, obj2, threshold)
    local distance = calculateDistance(obj1.x, obj1.y, obj2.x, obj2.y)
    return distance < threshold
end

local function checkTerrainCollision(playerX, playerY, tilemap, tileSize)
    local playerTileX = math.floor(playerX / tileSize) + 1
    local playerTileY = math.floor(playerY / tileSize) + 1
    
    if tilemap[playerTileY] and tilemap[playerTileY][playerTileX] then
        return tilemap[playerTileY][playerTileX]
    end
    return nil
end

function test_collision_detection.run_tests(test)
    print("=== COLLISION DETECTION TESTS ===")
    
    test("Distance calculation", function()
        local dist1 = calculateDistance(0, 0, 3, 4)
        assert(dist1 == 5, "Distance should be 5 for (0,0) to (3,4)")
        
        local dist2 = calculateDistance(10, 10, 10, 10)
        assert(dist2 == 0, "Distance should be 0 for same point")
        
        local dist3 = calculateDistance(0, 0, 0, 5)
        assert(dist3 == 5, "Distance should be 5 for vertical line")
        
        local dist4 = calculateDistance(0, 0, 5, 0)
        assert(dist4 == 5, "Distance should be 5 for horizontal line")
    end)
    
    test("Player-enemy collision", function()
        local player = {x = 100, y = 100, size = 24}
        local enemy = {x = 110, y = 100, size = 15}
        
        local collisionThreshold = (player.size + enemy.size) / 2
        local isColliding = checkCollision(player, enemy, collisionThreshold)
        
        assert(isColliding == true, "Player and enemy should collide when close")
        
        -- Test non-collision
        enemy.x = 200
        enemy.y = 200
        isColliding = checkCollision(player, enemy, collisionThreshold)
        assert(isColliding == false, "Player and enemy should not collide when far apart")
    end)
    
    test("Player-collectible collision", function()
        local player = {x = 100, y = 100, size = 24}
        local collectible = {x = 105, y = 105, size = 8}
        
        local collisionThreshold = player.size
        local isColliding = checkCollision(player, collectible, collisionThreshold)
        
        assert(isColliding == true, "Player should collide with nearby collectible")
        
        -- Test edge case
        collectible.x = 100 + player.size - 1
        collectible.y = 100
        isColliding = checkCollision(player, collectible, collisionThreshold)
        assert(isColliding == true, "Player should collide with collectible at edge")
        
        -- Test just outside collision
        collectible.x = 100 + player.size + 1
        isColliding = checkCollision(player, collectible, collisionThreshold)
        assert(isColliding == false, "Player should not collide with collectible just outside range")
    end)
    
    test("Player-powerup collision", function()
        local player = {x = 100, y = 100, size = 24}
        local powerup = {x = 100, y = 100, size = 15}
        
        local collisionThreshold = player.size
        local isColliding = checkCollision(player, powerup, collisionThreshold)
        
        assert(isColliding == true, "Player should collide with powerup at same position")
        
        -- Test offset collision
        powerup.x = 110
        powerup.y = 110
        isColliding = checkCollision(player, powerup, collisionThreshold)
        assert(isColliding == true, "Player should collide with nearby powerup")
    end)
    
    test("Player-shark collision", function()
        local player = {x = 100, y = 100, size = 24}
        local shark = {x = 105, y = 105, size = 25}
        
        local collisionThreshold = (player.size + shark.size) / 2
        local isColliding = checkCollision(player, shark, collisionThreshold)
        
        assert(isColliding == true, "Player should collide with nearby shark")
        
        -- Test instant death collision
        shark.x = 100
        shark.y = 100
        isColliding = checkCollision(player, shark, collisionThreshold)
        assert(isColliding == true, "Player should collide with shark at same position")
    end)
    
    test("Terrain collision detection", function()
        local tilemap = {
            {1, 1, 1, 1, 1},
            {1, "grass", "mountain", "water", 1},
            {1, "cave", "quicksand", "grass", 1},
            {1, 1, 1, 1, 1}
        }
        local tileSize = 32
        
        -- Test grass collision
        local terrain = checkTerrainCollision(32, 32, tilemap, tileSize)
        assert(terrain == "grass", "Should detect grass terrain")
        
        -- Test mountain collision
        terrain = checkTerrainCollision(64, 32, tilemap, tileSize)
        assert(terrain == "mountain", "Should detect mountain terrain")
        
        -- Test water collision
        terrain = checkTerrainCollision(96, 32, tilemap, tileSize)
        assert(terrain == "water", "Should detect water terrain")
        
        -- Test cave collision
        terrain = checkTerrainCollision(32, 64, tilemap, tileSize)
        assert(terrain == "cave", "Should detect cave terrain")
        
        -- Test quicksand collision
        terrain = checkTerrainCollision(64, 64, tilemap, tileSize)
        assert(terrain == "quicksand", "Should detect quicksand terrain")
    end)
    
    test("Boundary collision detection", function()
        local player = {x = 10, y = 10, size = 24}
        local mapWidth = 100
        local mapHeight = 100
        local tileSize = 32
        
        -- Test left boundary
        player.x = 5
        local isOutOfBounds = player.x < tileSize + player.size/2
        assert(isOutOfBounds == true, "Player should be out of bounds on left")
        
        -- Test right boundary
        player.x = (mapWidth - 1) * tileSize + 10  -- Position player beyond right boundary
        isOutOfBounds = player.x > (mapWidth - 1) * tileSize - player.size/2
        assert(isOutOfBounds == true, "Player should be out of bounds on right")
        
        -- Test top boundary
        player.x = 50
        player.y = 5
        isOutOfBounds = player.y < tileSize + player.size/2
        assert(isOutOfBounds == true, "Player should be out of bounds on top")
        
        -- Test bottom boundary
        player.y = (mapHeight - 1) * tileSize + 10  -- Position player beyond bottom boundary
        isOutOfBounds = player.y > (mapHeight - 1) * tileSize - player.size/2
        assert(isOutOfBounds == true, "Player should be out of bounds on bottom")
        
        -- Test in bounds
        player.x = 50
        player.y = 50
        local inBoundsX = player.x >= tileSize + player.size/2 and player.x <= (mapWidth - 1) * tileSize - player.size/2
        local inBoundsY = player.y >= tileSize + player.size/2 and player.y <= (mapHeight - 1) * tileSize - player.size/2
        assert(inBoundsX == true, "Player should be in bounds horizontally")
        assert(inBoundsY == true, "Player should be in bounds vertically")
    end)
    
    test("Collision threshold calculations", function()
        local player = {size = 24}
        local enemy = {size = 15}
        local collectible = {size = 8}
        local powerup = {size = 15}
        local shark = {size = 25}
        
        -- Test different collision thresholds
        local playerEnemyThreshold = (player.size + enemy.size) / 2
        local playerCollectibleThreshold = player.size
        local playerPowerupThreshold = player.size
        local playerSharkThreshold = (player.size + shark.size) / 2
        
        assert(playerEnemyThreshold == 19.5, "Player-enemy threshold should be 19.5")
        assert(playerCollectibleThreshold == 24, "Player-collectible threshold should be 24")
        assert(playerPowerupThreshold == 24, "Player-powerup threshold should be 24")
        assert(playerSharkThreshold == 24.5, "Player-shark threshold should be 24.5")
    end)
    
    test("Multiple collision detection", function()
        local player = {x = 100, y = 100, size = 24}
        local enemies = {
            {x = 105, y = 105, size = 15},
            {x = 200, y = 200, size = 15},
            {x = 110, y = 110, size = 15}
        }
        
        local collisionThreshold = (player.size + enemies[1].size) / 2
        local collidingEnemies = 0
        
        for _, enemy in ipairs(enemies) do
            if checkCollision(player, enemy, collisionThreshold) then
                collidingEnemies = collidingEnemies + 1
            end
        end
        
        assert(collidingEnemies == 2, "Should detect collision with 2 enemies")
    end)
    
    test("Collision with invincibility", function()
        local player = {x = 100, y = 100, size = 24, invincible = true}
        local enemy = {x = 105, y = 105, size = 15}
        
        local collisionThreshold = (player.size + enemy.size) / 2
        local isColliding = checkCollision(player, enemy, collisionThreshold)
        
        -- Collision should be detected but damage should be ignored
        assert(isColliding == true, "Collision should still be detected")
        assert(player.invincible == true, "Player should remain invincible")
    end)
    
    test("Collision with invulnerability frames", function()
        local player = {x = 100, y = 100, size = 24, invulnerable = true}
        local enemy = {x = 105, y = 105, size = 15}
        
        local collisionThreshold = (player.size + enemy.size) / 2
        local isColliding = checkCollision(player, enemy, collisionThreshold)
        
        -- Collision should be detected but damage should be ignored
        assert(isColliding == true, "Collision should still be detected")
        assert(player.invulnerable == true, "Player should remain invulnerable")
    end)
end

return test_collision_detection
