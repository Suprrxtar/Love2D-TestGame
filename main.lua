-- Love2D Game: Player and Tileset System

-- Love2D configuration (must be at the top)
function love.conf(t)
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.fullscreen = false
    t.window.vsync = 1
end


-- Player system
local player = {
    x = 100,  -- Player position in pixels
    y = 100,
    baseSize = 24,  -- Base player size (will be scaled)
    baseSpeed = 200,  -- Base movement speed (will be scaled)
    size = 24,  -- Current scaled size
    speed = 200,  -- Current scaled speed
    trail = {},  -- Particle trail
    maxTrail = 20,  -- Maximum trail particles
    energy = 100,  -- Player energy/health
    maxEnergy = 100,
    invulnerable = false,  -- Invulnerability frames
    invulnTime = 0,
    invincible = false,  -- Power-up invincibility
    invincibleTime = 0,  -- Time remaining for power-up
    maxInvincibleTime = 10  -- 10 seconds of invincibility
}

-- Helper function to set player energy with automatic capping
local function setPlayerEnergy(value)
    player.energy = math.max(0, math.min(value, player.maxEnergy))
end

-- Tileset system
local tileSize = 32  -- Size of each tile in pixels
local tileset = {
    -- Different tile types with their colors
    grass = {0.2, 0.8, 0.2},      -- Green
    water = {0.2, 0.4, 1.0},      -- Blue
    mountain = {0.6, 0.6, 0.6},   -- Light gray mountains
    quicksand = {0.9, 0.7, 0.3},  -- Darker yellow/brown quicksand
    cave = {0.1, 0.1, 0.1},       -- Black cave/tunnel
    wall = {0.3, 0.3, 0.3},       -- Dark gray
    empty = {0.1, 0.1, 0.1}       -- Dark (transparent-ish)
}

-- MASSIVE OPEN WORLD TILEMAP (120x68 - 16:9 aspect ratio!)
local tilemap = {}

-- Generate procedural world
local function generateWorld()
    local worldWidth = 120   -- Much wider for bigger world
    local worldHeight = 68   -- Taller for bigger world (16:9 ratio maintained)
    tilemap = {}
    
    -- Initialize with grass
    for y = 1, worldHeight do
        tilemap[y] = {}
        for x = 1, worldWidth do
            tilemap[y][x] = "grass"
        end
    end
    
    -- Add border walls
    for i = 1, worldWidth do
        tilemap[1][i] = "wall"
        tilemap[worldHeight][i] = "wall"
    end
    for i = 1, worldHeight do
        tilemap[i][1] = "wall"
        tilemap[i][worldWidth] = "wall"
    end
    
    -- Add water features with connectivity
    local waterBodies = {}
    for i = 1, 15 do
        local x, y = math.random(5, worldWidth-5), math.random(5, worldHeight-5)
        local size = math.random(3, 6)
        local waterBody = {}
        
        for dy = -size, size do
            for dx = -size, size do
                local nx, ny = x + dx, y + dy
                if nx > 1 and nx < worldWidth and ny > 1 and ny < worldHeight and math.sqrt(dx*dx + dy*dy) <= size then
                    tilemap[ny][nx] = "water"
                    table.insert(waterBody, {x = nx, y = ny})
                end
            end
        end
        
        if #waterBody > 0 then
            table.insert(waterBodies, waterBody)
        end
    end
    
    -- Ensure connectivity between water bodies
    for i = 1, #waterBodies - 1 do
        local body1 = waterBodies[i]
        local body2 = waterBodies[i + 1]
        
        if #body1 > 0 and #body2 > 0 then
            local point1 = body1[math.random(#body1)]
            local point2 = body2[math.random(#body2)]
            
            -- Create a thin water connection
            local dx = point2.x - point1.x
            local dy = point2.y - point1.y
            local steps = math.max(math.abs(dx), math.abs(dy))
            
            for step = 0, steps do
                local t = step / steps
                local nx = math.floor(point1.x + dx * t + 0.5)
                local ny = math.floor(point1.y + dy * t + 0.5)
                
                if nx > 1 and nx < worldWidth and ny > 1 and ny < worldHeight then
                    tilemap[ny][nx] = "water"
                end
            end
        end
    end
    
    -- Add mountain formations (larger and more imposing) - 20% less
    for i = 1, 12 do  -- Reduced from 15 to 12 (20% less)
        local x, y = math.random(4, worldWidth-4), math.random(4, worldHeight-4)
        local size = math.random(4, 8) -- Larger mountain ranges
        for dy = -size, size do
            for dx = -size, size do
                local nx, ny = x + dx, y + dy
                if nx > 1 and nx < worldWidth and ny > 1 and ny < worldHeight and math.sqrt(dx*dx + dy*dy) <= size and tilemap[ny][nx] ~= "water" then
                    tilemap[ny][nx] = "mountain"
                end
            end
        end
    end
    
    -- Add smaller mountain peaks for variety - 20% less
    for i = 1, 16 do  -- Reduced from 20 to 16 (20% less)
        local x, y = math.random(3, worldWidth-3), math.random(3, worldHeight-3)
        local size = math.random(2, 4)
        for dy = -size, size do
            for dx = -size, size do
                local nx, ny = x + dx, y + dy
                if nx > 1 and nx < worldWidth and ny > 1 and ny < worldHeight and math.sqrt(dx*dx + dy*dy) <= size and tilemap[ny][nx] ~= "water" then
                    tilemap[ny][nx] = "mountain"
                end
            end
        end
    end
    
    -- Add cave/tunnel systems through mountains
    for i = 1, 8 do  -- Create 8 cave systems
        local startX, startY = math.random(5, worldWidth-5), math.random(5, worldHeight-5)
        local endX, endY = math.random(5, worldWidth-5), math.random(5, worldHeight-5)
        
        -- Create a winding tunnel between two points
        local currentX, currentY = startX, startY
        local steps = math.max(math.abs(endX - startX), math.abs(endY - startY)) + math.random(5, 15)
        
        for step = 1, steps do
            -- Only place cave if we're in mountain terrain
            if tilemap[currentY] and tilemap[currentY][currentX] == "mountain" then
                tilemap[currentY][currentX] = "cave"
                
                -- Add some branching tunnels (narrow paths)
                if math.random() < 0.3 then  -- 30% chance for branch
                    local branchLength = math.random(2, 4)
                    local branchDirX = math.random(-1, 1)
                    local branchDirY = math.random(-1, 1)
                    
                    for branch = 1, branchLength do
                        local branchX = currentX + branchDirX * branch
                        local branchY = currentY + branchDirY * branch
                        
                        if branchX >= 1 and branchX <= worldWidth and branchY >= 1 and branchY <= worldHeight then
                            if tilemap[branchY] and tilemap[branchY][branchX] == "mountain" then
                                tilemap[branchY][branchX] = "cave"
                            end
                        end
                    end
                end
            end
            
            -- Move towards end point with some randomness
            if currentX < endX then
                currentX = currentX + 1
            elseif currentX > endX then
                currentX = currentX - 1
            end
            
            if currentY < endY then
                currentY = currentY + 1
            elseif currentY > endY then
                currentY = currentY - 1
            end
            
            -- Add some randomness to create winding paths
            if math.random() < 0.2 then  -- 20% chance to deviate
                currentX = currentX + math.random(-1, 1)
                currentY = currentY + math.random(-1, 1)
                currentX = math.max(1, math.min(currentX, worldWidth))
                currentY = math.max(1, math.min(currentY, worldHeight))
            end
        end
    end
    
    -- Add quicksand areas (dangerous terrain)
    for i = 1, 20 do  -- More quicksand areas in bigger world
        local x, y = math.random(4, worldWidth-4), math.random(4, worldHeight-4)
        local size = math.random(3, 8)
        for dy = -size, size do
            for dx = -size, size do
                local nx, ny = x + dx, y + dy
                if nx > 2 and nx < worldWidth-1 and ny > 2 and ny < worldHeight-1 and math.sqrt(dx*dx + dy*dy) <= size and tilemap[ny][nx] == "grass" then
                    tilemap[ny][nx] = "quicksand"
                end
            end
        end
    end
end

-- Calculate dynamic tilemap dimensions (will be set after world generation)
local mapRows = 68  -- Updated for bigger world
local mapCols = 120

-- Visual effects system
local effects = {
    particles = {},
    maxParticles = 100,
    screenShake = 0,
    screenShakeIntensity = 0,
    glowIntensity = 0,
    pulseTime = 0
}

-- Game mechanics
local collectibles = {}
local enemies = {}
local sharks = {}
local powerups = {}
local score = 0
local gameTime = 0
local isGameOver = false
local isVictory = false
local timeInWater = 0
local sharkSpawnTimer = 0
local powerupSpawnTimer = 0

-- Camera system
local camera = {
    x = 0,
    y = 0,
    targetX = 0,
    targetY = 0,
    zoom = 1,
    targetZoom = 1,
    smoothness = 5
}

-- Generate collectibles
local function generateCollectibles()
    collectibles = {}
    local attempts = 0
    local maxAttempts = 300
    
    while #collectibles < 60 and attempts < maxAttempts do
        local x = math.random(2, mapCols - 1)
        local y = math.random(2, mapRows - 1)
        
        if tilemap[y] and (tilemap[y][x] == "grass" or tilemap[y][x] == "quicksand" or tilemap[y][x] == "cave") then
            table.insert(collectibles, {
                x = x,
                y = y,
                collected = false,
                pulse = math.random() * math.pi * 2,
                size = math.random(6, 12),
                glowIntensity = math.random() * 0.5 + 0.5
            })
        end
        attempts = attempts + 1
    end
end

-- Generate enemies
local function generateEnemies()
    enemies = {}
    local attempts = 0
    local maxAttempts = 200
    
    while #enemies < 20 and attempts < maxAttempts do
        local x = math.random(3, mapCols - 2)
        local y = math.random(3, mapRows - 2)
        
        if tilemap[y] and (tilemap[y][x] == "grass" or tilemap[y][x] == "mountain" or tilemap[y][x] == "quicksand") then
            -- Create enemy with different speeds (2 fast, rest slow)
            local isFast = #enemies < 2  -- First 2 enemies are fast
            local enemySpeed = isFast and math.random(1.2, 1.8) or math.random(0.2, 0.5)
            
            table.insert(enemies, {
                x = x,
                y = y,
                dirX = math.random(-1, 1),
                dirY = math.random(-1, 1),
                speed = enemySpeed,
                size = math.random(12, 20),
                pulse = math.random() * math.pi * 2,
                attackCooldown = 0,
                maxAttackCooldown = math.random(1, 3),
                isFast = isFast,
                searchTimer = 0,  -- Timer for searching behavior
                lastKnownPlayerX = 0,
                lastKnownPlayerY = 0,
                isSearching = false
            })
        end
        attempts = attempts + 1
    end
end

-- Generate sharks (spawn dynamically when player is in water)
local function generateSharks()
    sharks = {}
    -- Sharks spawn dynamically, not at world generation
end

-- Spawn a shark near the player when they're in water
local function spawnSharkNearPlayer()
    if #sharks >= 5 then return end -- Max 5 sharks
    
    local attempts = 0
    local maxAttempts = 50
    
    while attempts < maxAttempts do
        local offsetX = math.random(-15, 15)
        local offsetY = math.random(-15, 15)
        
        local sharkX = (player.x / tileSize) + offsetX
        local sharkY = (player.y / tileSize) + offsetY
        
        -- Make sure shark spawns in water and within bounds
        if sharkX > 1 and sharkX < mapCols and sharkY > 1 and sharkY < mapRows then
            local tileX = math.floor(sharkX)
            local tileY = math.floor(sharkY)
            
            if tilemap[tileY] and tilemap[tileY][tileX] == "water" then
                table.insert(sharks, {
                    x = sharkX,
                    y = sharkY,
                    dirX = math.random(-1, 1),
                    dirY = math.random(-1, 1),
                    speed = math.min(1.5, math.random(0.8, 1.5)), -- Faster than regular enemies, capped at 1.5
                    size = math.random(20, 30),
                    pulse = math.random() * math.pi * 2,
                    attackCooldown = 0,
                    maxAttackCooldown = 0.5,
                    timeAlive = 0,
                    maxLifetime = 10 -- Sharks disappear after 10 seconds if not in water
                })
                break
            end
        end
        attempts = attempts + 1
    end
end

-- Generate power-ups (invincibility stars)
local function generatePowerups()
    powerups = {}
    -- Power-ups spawn dynamically, not at world generation
end

-- Spawn a power-up randomly on the map
local function spawnPowerup()
    if #powerups >= 2 then return end -- Max 2 power-ups
    
    local attempts = 0
    local maxAttempts = 100
    
    while attempts < maxAttempts do
        local x = math.random(3, mapCols - 2)
        local y = math.random(3, mapRows - 2)
        
        -- Only spawn on grass or cave (safe terrain)
        if tilemap[y] and (tilemap[y][x] == "grass" or tilemap[y][x] == "cave") then
            table.insert(powerups, {
                x = x,
                y = y,
                collected = false,
                pulse = math.random() * math.pi * 2,
                size = 15,
                glowIntensity = math.random() * 0.5 + 0.5,
                rainbowPhase = math.random() * math.pi * 2
            })
            break
        end
        attempts = attempts + 1
    end
end

-- Find the nearest safe spot (grass, sand, or water) to the given position
local function findNearestSafeSpot(x, y)
    local maxSearchRadius = 10  -- Maximum distance to search
    
    -- Check in expanding circles around the player
    for radius = 1, maxSearchRadius do
        for dx = -radius, radius do
            for dy = -radius, radius do
                -- Only check positions on the circle's edge
                if math.abs(dx) == radius or math.abs(dy) == radius then
                    local checkX = x + dx
                    local checkY = y + dy
                    
                    -- Make sure we're within map bounds
                    if checkX >= 1 and checkX <= mapCols and checkY >= 1 and checkY <= mapRows then
                        if tilemap[checkY] then
                            local tileType = tilemap[checkY][checkX]
                            -- Safe tiles: grass, quicksand, water, cave (but not mountains or walls)
                            if tileType == "grass" or tileType == "quicksand" or tileType == "water" or tileType == "cave" then
                                return checkX, checkY
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- If no safe spot found, return the original position (fallback)
    return x, y
end

-- Particle system functions
local function addParticle(x, y, color, life, size, velocity)
    table.insert(effects.particles, {
        x = x,
        y = y,
        vx = velocity and velocity.x or (math.random(-50, 50)),
        vy = velocity and velocity.y or (math.random(-50, 50)),
        life = life,
        maxLife = life,
        size = size,
        color = color,
        alpha = 1
    })
    
    -- Limit particle count
    if #effects.particles > effects.maxParticles then
        table.remove(effects.particles, 1)
    end
end

local function updateParticles(dt)
    for i = #effects.particles, 1, -1 do
        local p = effects.particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.life = p.life - dt
        p.alpha = p.life / p.maxLife
        p.size = p.size * (0.98 + math.sin(p.life * 10) * 0.02)
        
        if p.life <= 0 then
            table.remove(effects.particles, i)
        end
    end
end

local function drawParticles()
    for _, p in ipairs(effects.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.alpha)
        love.graphics.circle("fill", p.x, p.y, p.size)
    end
end

-- Trail effect
local function updateTrail(dt)
    -- Add new trail particle
    table.insert(player.trail, {
        x = player.x,
        y = player.y,
        life = 1.0,
        size = player.size * 0.3
    })
    
    -- Update and remove old trail particles
    for i = #player.trail, 1, -1 do
        local t = player.trail[i]
        t.life = t.life - dt * 2
        t.size = t.size * 0.95
        
        if t.life <= 0 or #player.trail > player.maxTrail then
            table.remove(player.trail, i)
        end
    end
end

local function drawTrail()
    for i, t in ipairs(player.trail) do
        local alpha = t.life * 0.5
        love.graphics.setColor(0.2, 0.8, 1.0, alpha)
        love.graphics.circle("fill", t.x, t.y, t.size)
    end
end

-- Screen shake effect
local function addScreenShake(intensity)
    effects.screenShake = 1.0
    effects.screenShakeIntensity = intensity
end

local function updateScreenShake(dt)
    if effects.screenShake > 0 then
        effects.screenShake = effects.screenShake - dt * 3
        if effects.screenShake < 0 then
            effects.screenShake = 0
        end
    end
end

function love.update(dt)
    if isGameOver or isVictory then return end
    
    -- Get window dimensions
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    
    -- Calculate dynamic tile size to fill entire window
    local baseTileSize = math.min(windowWidth / mapCols, windowHeight / mapRows)
    tileSize = baseTileSize
    
    -- Scale player size and speed based on tile size
    local scaleFactor = tileSize / 32
    player.size = player.baseSize * scaleFactor
    player.speed = player.baseSpeed * scaleFactor
    
    -- Update game time and effects
    gameTime = gameTime + dt
    effects.pulseTime = effects.pulseTime + dt
    effects.glowIntensity = 0.5 + math.sin(effects.pulseTime * 3) * 0.3
    
    -- Update power-up spawning timer
    powerupSpawnTimer = powerupSpawnTimer + dt
    if powerupSpawnTimer >= 30.0 then -- Spawn power-up every 30 seconds
        spawnPowerup()
        powerupSpawnTimer = 0
    end
    
    -- Update invulnerability
    if player.invulnerable then
        player.invulnTime = player.invulnTime - dt
        if player.invulnTime <= 0 then
            player.invulnerable = false
        end
    end
    
    -- Update invincibility power-up
    if player.invincible then
        player.invincibleTime = player.invincibleTime - dt
        if player.invincibleTime <= 0 then
            player.invincible = false
            
            -- Check if player is stuck in impassable terrain when invincibility ends
            local playerTileX = math.floor(player.x / tileSize) + 1
            local playerTileY = math.floor(player.y / tileSize) + 1
            
            if tilemap[playerTileY] and (tilemap[playerTileY][playerTileX] == "mountain" or tilemap[playerTileY][playerTileX] == "wall") then
                -- Player is stuck in impassable terrain, find nearest safe spot
                local safeX, safeY = findNearestSafeSpot(playerTileX, playerTileY)
                if safeX and safeY then
                    player.x = (safeX - 1) * tileSize + tileSize / 2
                    player.y = (safeY - 1) * tileSize + tileSize / 2
                    addParticle(player.x, player.y, {1.0, 1.0, 0.0}, 1.0, 8) -- Yellow teleport effect
                end
            end
        end
    end
    
    -- Store old position for collision detection
    local oldX = player.x
    local oldY = player.y
    local wasMoving = false
    
    -- Check if player is in water or quicksand
    local playerTileX = math.floor(player.x / tileSize) + 1
    local playerTileY = math.floor(player.y / tileSize) + 1
    local isInWater = false
    local isInQuicksand = false
    
    if tilemap[playerTileY] and tilemap[playerTileY][playerTileX] == "water" then
        isInWater = true
        timeInWater = timeInWater + dt
        sharkSpawnTimer = sharkSpawnTimer + dt
        
        -- Spawn sharks if player has been in water too long
        if sharkSpawnTimer >= 2.0 then -- Spawn shark every 2 seconds in water
            spawnSharkNearPlayer()
            sharkSpawnTimer = 0
        end
    elseif tilemap[playerTileY] and tilemap[playerTileY][playerTileX] == "quicksand" then
        isInQuicksand = true
    else
        timeInWater = 0
        sharkSpawnTimer = 0
    end
    
    -- Adjust movement speed and energy cost based on terrain
    local currentSpeed = player.speed
    local energyCost = 0
    
    -- Check if invincible (ignores terrain effects)
    if player.invincible then
        currentSpeed = player.speed  -- Full speed when invincible
        energyCost = 0  -- No energy cost when invincible
    elseif isInWater then
        currentSpeed = player.speed * 0.4  -- 60% slower in water
        energyCost = 15 * dt  -- High energy cost for swimming
    elseif isInQuicksand then
        currentSpeed = player.speed * 0.3  -- 70% slower in quicksand (even slower than water)
        energyCost = 25 * dt  -- Higher energy cost than swimming
    end
    
    -- Player movement with terrain effects
    if love.keyboard.isDown("left") then
        player.x = player.x - currentSpeed * dt
        wasMoving = true
        if player.invincible then
            -- Rainbow particles when invincible
            local hue = (effects.pulseTime * 5) % (math.pi * 2)
            local r = 0.5 + 0.5 * math.sin(hue)
            local g = 0.5 + 0.5 * math.sin(hue + math.pi * 2/3)
            local b = 0.5 + 0.5 * math.sin(hue + math.pi * 4/3)
            addParticle(player.x + player.size/2, player.y, {r, g, b}, 1.0, 5, {x = 40, y = math.random(-15, 15)})
        elseif isInWater then
            addParticle(player.x + player.size/2, player.y, {0.1, 0.4, 0.8}, 0.8, 3, {x = 20, y = math.random(-10, 10)})
        elseif isInQuicksand then
            addParticle(player.x + player.size/2, player.y, {0.9, 0.7, 0.3}, 1.2, 4, {x = 15, y = math.random(-5, 5)})
        else
            addParticle(player.x + player.size/2, player.y, {0.2, 0.6, 1.0}, 0.5, 2, {x = 30, y = 0})
        end
    end
    if love.keyboard.isDown("right") then
        player.x = player.x + currentSpeed * dt
        wasMoving = true
        if player.invincible then
            local hue = (effects.pulseTime * 5) % (math.pi * 2)
            local r = 0.5 + 0.5 * math.sin(hue)
            local g = 0.5 + 0.5 * math.sin(hue + math.pi * 2/3)
            local b = 0.5 + 0.5 * math.sin(hue + math.pi * 4/3)
            addParticle(player.x - player.size/2, player.y, {r, g, b}, 1.0, 5, {x = -40, y = math.random(-15, 15)})
        elseif isInWater then
            addParticle(player.x - player.size/2, player.y, {0.1, 0.4, 0.8}, 0.8, 3, {x = -20, y = math.random(-10, 10)})
        elseif isInQuicksand then
            addParticle(player.x - player.size/2, player.y, {0.9, 0.7, 0.3}, 1.2, 4, {x = -15, y = math.random(-5, 5)})
        else
            addParticle(player.x - player.size/2, player.y, {0.2, 0.6, 1.0}, 0.5, 2, {x = -30, y = 0})
        end
    end
    if love.keyboard.isDown("up") then
        player.y = player.y - currentSpeed * dt
        wasMoving = true
        if player.invincible then
            local hue = (effects.pulseTime * 5) % (math.pi * 2)
            local r = 0.5 + 0.5 * math.sin(hue)
            local g = 0.5 + 0.5 * math.sin(hue + math.pi * 2/3)
            local b = 0.5 + 0.5 * math.sin(hue + math.pi * 4/3)
            addParticle(player.x, player.y + player.size/2, {r, g, b}, 1.0, 5, {x = math.random(-15, 15), y = 40})
        elseif isInWater then
            addParticle(player.x, player.y + player.size/2, {0.1, 0.4, 0.8}, 0.8, 3, {x = math.random(-10, 10), y = 20})
        elseif isInQuicksand then
            addParticle(player.x, player.y + player.size/2, {0.9, 0.7, 0.3}, 1.2, 4, {x = math.random(-5, 5), y = 15})
        else
            addParticle(player.x, player.y + player.size/2, {0.2, 0.6, 1.0}, 0.5, 2, {x = 0, y = 30})
        end
    end
    if love.keyboard.isDown("down") then
        player.y = player.y + currentSpeed * dt
        wasMoving = true
        if player.invincible then
            local hue = (effects.pulseTime * 5) % (math.pi * 2)
            local r = 0.5 + 0.5 * math.sin(hue)
            local g = 0.5 + 0.5 * math.sin(hue + math.pi * 2/3)
            local b = 0.5 + 0.5 * math.sin(hue + math.pi * 4/3)
            addParticle(player.x, player.y - player.size/2, {r, g, b}, 1.0, 5, {x = math.random(-15, 15), y = -40})
        elseif isInWater then
            addParticle(player.x, player.y - player.size/2, {0.1, 0.4, 0.8}, 0.8, 3, {x = math.random(-10, 10), y = -20})
        elseif isInQuicksand then
            addParticle(player.x, player.y - player.size/2, {0.9, 0.7, 0.3}, 1.2, 4, {x = math.random(-5, 5), y = -15})
        else
            addParticle(player.x, player.y - player.size/2, {0.2, 0.6, 1.0}, 0.5, 2, {x = 0, y = -30})
        end
    end
    
    -- Apply energy cost for swimming or quicksand (unless invincible)
    if (isInWater or isInQuicksand) and wasMoving and not player.invincible then
        player.energy = player.energy - energyCost
        if player.energy < 0 then
            player.energy = 0
            isGameOver = true
            addScreenShake(15)
        end
    end
    
    -- Update trail when moving
    if wasMoving then
        updateTrail(dt)
    end
    
    -- Keep player within tilemap bounds and check for mountain collision
    local mapWidth = mapCols * tileSize
    local mapHeight = mapRows * tileSize
    local offsetX = (windowWidth - mapWidth) / 2
    local offsetY = (windowHeight - mapHeight) / 2
    
    -- Check for collision with impassable terrain (mountains and walls) - unless invincible
    local newPlayerTileX = math.floor(player.x / tileSize) + 1
    local newPlayerTileY = math.floor(player.y / tileSize) + 1
    
    if not player.invincible then
        -- Check if player hit impassable terrain or is outside bounds
        local hitImpassable = false
        if newPlayerTileX < 1 or newPlayerTileX > mapCols or newPlayerTileY < 1 or newPlayerTileY > mapRows then
            hitImpassable = true -- Outside world bounds (border)
        elseif tilemap[newPlayerTileY] and (tilemap[newPlayerTileY][newPlayerTileX] == "mountain" or tilemap[newPlayerTileY][newPlayerTileX] == "wall") then
            hitImpassable = true -- Hit mountain or wall
        end
        
        if hitImpassable then
            -- Player hit impassable terrain, revert to old position
            player.x = oldX
            player.y = oldY
            addParticle(player.x, player.y, {0.8, 0.8, 0.8}, 0.5, 4) -- Gray impact particle
        else
            -- Normal boundary checking (but stay within the tilemap)
            local minX = offsetX + tileSize + player.size/2  -- Inside first walkable tile
            local maxX = offsetX + (mapCols - 1) * tileSize - player.size/2  -- Inside last walkable tile
            local minY = offsetY + tileSize + player.size/2  -- Inside first walkable tile
            local maxY = offsetY + (mapRows - 1) * tileSize - player.size/2  -- Inside last walkable tile
            
            player.x = math.max(minX, math.min(player.x, maxX))
            player.y = math.max(minY, math.min(player.y, maxY))
        end
    else
        -- When invincible, only check world bounds (can go through mountains/walls)
        local minX = offsetX + player.size/2
        local maxX = offsetX + mapCols * tileSize - player.size/2
        local minY = offsetY + player.size/2
        local maxY = offsetY + mapRows * tileSize - player.size/2
        
        player.x = math.max(minX, math.min(player.x, maxX))
        player.y = math.max(minY, math.min(player.y, maxY))
    end
    
    -- Update camera to follow player
    camera.targetX = player.x - windowWidth / 2
    camera.targetY = player.y - windowHeight / 2
    camera.x = camera.x + (camera.targetX - camera.x) * dt * camera.smoothness
    camera.y = camera.y + (camera.targetY - camera.y) * dt * camera.smoothness
    
    -- Update enemies
    for _, enemy in ipairs(enemies) do
        enemy.pulse = enemy.pulse + dt * 2
        enemy.searchTimer = enemy.searchTimer + dt
        
        -- Check if player is in a cave (enemies can't see through caves)
        local playerTileX = math.floor(player.x / tileSize) + 1
        local playerTileY = math.floor(player.y / tileSize) + 1
        local playerInCave = tilemap[playerTileY] and tilemap[playerTileY][playerTileX] == "cave"
        
        if playerInCave then
            -- Player is in cave - enemies can't see them
            if not enemy.isSearching then
                -- Start searching behavior
                enemy.isSearching = true
                enemy.searchTimer = 0
                enemy.lastKnownPlayerX = player.x
                enemy.lastKnownPlayerY = player.y
            end
            
            -- Search behavior: move to last known player position, then wander
            if enemy.searchTimer < 3.0 then
                -- Move towards last known player position for 3 seconds
                local dx = (enemy.lastKnownPlayerX - (offsetX + enemy.x * tileSize)) / tileSize
                local dy = (enemy.lastKnownPlayerY - (offsetY + enemy.y * tileSize)) / tileSize
                local dist = math.sqrt(dx*dx + dy*dy)
                if dist > 0 then
                    enemy.dirX = dx / dist
                    enemy.dirY = dy / dist
                end
            else
                -- After 3 seconds, start wandering randomly
                if enemy.searchTimer > 5.0 then
                    enemy.searchTimer = 0
                    enemy.isSearching = false
                end
                -- Random wandering
                enemy.dirX = enemy.dirX + (math.random() - 0.5) * dt * 2
                enemy.dirY = enemy.dirY + (math.random() - 0.5) * dt * 2
                local dirLength = math.sqrt(enemy.dirX*enemy.dirX + enemy.dirY*enemy.dirY)
                if dirLength > 0 then
                    enemy.dirX = enemy.dirX / dirLength
                    enemy.dirY = enemy.dirY / dirLength
                end
            end
        else
            -- Player is visible - normal chase behavior
            enemy.isSearching = false
            enemy.searchTimer = 0
            
            local dx = (player.x - (offsetX + enemy.x * tileSize)) / tileSize
            local dy = (player.y - (offsetY + enemy.y * tileSize)) / tileSize
            local dist = math.sqrt(dx*dx + dy*dy)
            if dist > 0 then
                enemy.dirX = dx / dist
                enemy.dirY = dy / dist
            end
        end
        
        -- Move enemy (but not through caves)
        local newEnemyX = enemy.x + enemy.dirX * enemy.speed * dt
        local newEnemyY = enemy.y + enemy.dirY * enemy.speed * dt
        
        -- Check if enemy would move into a cave (blocked)
        local enemyTileX = math.floor(newEnemyX)
        local enemyTileY = math.floor(newEnemyY)
        
        if tilemap[enemyTileY] and tilemap[enemyTileY][enemyTileX] == "cave" then
            -- Enemy blocked by cave, try to move around it
            -- Try alternative directions
            if math.random() < 0.5 then
                enemy.dirX = -enemy.dirX
            else
                enemy.dirY = -enemy.dirY
            end
        else
            -- Move normally
            enemy.x = newEnemyX
            enemy.y = newEnemyY
        end
        
        -- Keep enemy in bounds (enemies can move through mountains but not caves)
        enemy.x = math.max(1, math.min(enemy.x, mapCols - 2))
        enemy.y = math.max(1, math.min(enemy.y, mapRows - 2))
        
        -- Check collision with player
        local enemyScreenX = enemy.x * tileSize
        local enemyScreenY = enemy.y * tileSize
        local distance = math.sqrt((player.x - enemyScreenX)^2 + (player.y - enemyScreenY)^2)
        
        if distance < (player.size + enemy.size) / 2 and not player.invulnerable and not player.invincible and not playerInCave then
            player.energy = player.energy - 20
            player.invulnerable = true
            player.invulnTime = 1.0
            addScreenShake(5)
            addParticle(enemyScreenX, enemyScreenY, {1.0, 0.2, 0.2}, 1.0, 8)
            
            if player.energy <= 0 then
                isGameOver = true
                addScreenShake(10)
            end
        end
    end
    
    -- Update sharks
    for i = #sharks, 1, -1 do
        local shark = sharks[i]
        shark.pulse = shark.pulse + dt * 3
        shark.timeAlive = shark.timeAlive + dt
        
        -- Remove sharks that are too old or not in water
        local sharkTileX = math.floor(shark.x)
        local sharkTileY = math.floor(shark.y)
        local sharkInWater = tilemap[sharkTileY] and tilemap[sharkTileY][sharkTileX] == "water"
        
        if shark.timeAlive > shark.maxLifetime or not sharkInWater then
            table.remove(sharks, i)
        else
            -- Shark AI: move towards player aggressively
            local dx = (player.x - (offsetX + shark.x * tileSize)) / tileSize
            local dy = (player.y - (offsetY + shark.y * tileSize)) / tileSize
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist > 0 then
                shark.dirX = dx / dist
                shark.dirY = dy / dist
            end
            
            -- Move shark
            shark.x = shark.x + shark.dirX * shark.speed * dt
            shark.y = shark.y + shark.dirY * shark.speed * dt
            
            -- Keep shark in bounds
            shark.x = math.max(1, math.min(shark.x, mapCols - 2))
            shark.y = math.max(1, math.min(shark.y, mapRows - 2))
            
            -- Check collision with player
            local sharkScreenX = shark.x * tileSize
            local sharkScreenY = shark.y * tileSize
            local distance = math.sqrt((player.x - sharkScreenX)^2 + (player.y - sharkScreenY)^2)
            
            if distance < (player.size + shark.size) / 2 and not player.invincible then
                -- Shark attack is instant death!
                isGameOver = true
                addScreenShake(20)
                addParticle(sharkScreenX, sharkScreenY, {1.0, 0.1, 0.1}, 2.0, 15)
                addParticle(player.x, player.y, {1.0, 0.0, 0.0}, 1.5, 12)
            end
        end
    end
    
    -- Check collectible collisions
    for _, collectible in ipairs(collectibles) do
        if not collectible.collected then
            collectible.pulse = collectible.pulse + dt * 3
            local collectibleScreenX = collectible.x * tileSize
            local collectibleScreenY = collectible.y * tileSize
            local distance = math.sqrt((player.x - collectibleScreenX)^2 + (player.y - collectibleScreenY)^2)
            
            if distance < player.size then
                collectible.collected = true
                score = score + 100
                setPlayerEnergy(player.energy + 10)
                addParticle(collectibleScreenX, collectibleScreenY, {1.0, 1.0, 0.2}, 1.0, 6)
                addScreenShake(2)
                
                -- Check for victory condition
                local remainingOrbs = 0
                for _, orb in ipairs(collectibles) do
                    if not orb.collected then
                        remainingOrbs = remainingOrbs + 1
                    end
                end
                
                if remainingOrbs == 0 then
                    isVictory = true
                    addScreenShake(15)
                    -- Victory particles
                    for i = 1, 20 do
                        addParticle(player.x + math.random(-50, 50), player.y + math.random(-50, 50), 
                                   {1.0, 1.0, 0.2}, 2.0, 8, 
                                   {x = math.random(-100, 100), y = math.random(-100, 100)})
                    end
                end
            end
        end
    end
    
    -- Check power-up collisions
    for _, powerup in ipairs(powerups) do
        if not powerup.collected then
            powerup.pulse = powerup.pulse + dt * 4
            powerup.rainbowPhase = powerup.rainbowPhase + dt * 6
            local powerupScreenX = powerup.x * tileSize
            local powerupScreenY = powerup.y * tileSize
            local distance = math.sqrt((player.x - powerupScreenX)^2 + (player.y - powerupScreenY)^2)
            
            if distance < player.size then
                powerup.collected = true
                player.invincible = true
                player.invincibleTime = player.maxInvincibleTime
                score = score + 500  -- Bonus points for power-up
                addParticle(powerupScreenX, powerupScreenY, {1.0, 1.0, 1.0}, 2.0, 12)
                addScreenShake(8)
            end
        end
    end
    
    -- Update particle effects
    updateParticles(dt)
    updateScreenShake(dt)
    
    -- Regenerate energy slowly
    if player.energy < player.maxEnergy then
        player.energy = player.energy + dt * 5
        if player.energy > player.maxEnergy then
            setPlayerEnergy(player.maxEnergy)
        end
    end
end

-- Function to draw a single tile
local function drawTile(tileType, x, y)
    if tileset[tileType] then
        local color = tileset[tileType]
        
        if tileType == "mountain" then
            -- Special mountain rendering with height effect
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", x, y, tileSize, tileSize)
            
            -- Add mountain peak effect
            love.graphics.setColor(color[1] + 0.2, color[2] + 0.2, color[3] + 0.2)
            love.graphics.rectangle("fill", x + tileSize/4, y + tileSize/4, tileSize/2, tileSize/2)
            
            -- Add dark shadow for depth
            love.graphics.setColor(color[1] - 0.2, color[2] - 0.2, color[3] - 0.2)
            love.graphics.rectangle("fill", x, y + tileSize*0.7, tileSize, tileSize*0.3)
            
            -- Mountain border
            love.graphics.setColor(0.4, 0.4, 0.4)
            love.graphics.rectangle("line", x, y, tileSize, tileSize)
        elseif tileType == "cave" then
            -- Special cave rendering - dark with subtle details
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", x, y, tileSize, tileSize)
            
            -- Add some depth with slightly lighter center
            love.graphics.setColor(color[1] + 0.05, color[2] + 0.05, color[3] + 0.05)
            love.graphics.rectangle("fill", x + tileSize/6, y + tileSize/6, tileSize*2/3, tileSize*2/3)
            
            -- Add cave entrance effect (darker edges)
            love.graphics.setColor(color[1] - 0.05, color[2] - 0.05, color[3] - 0.05)
            love.graphics.rectangle("fill", x, y, tileSize, tileSize/6)  -- Top edge
            love.graphics.rectangle("fill", x, y + tileSize*5/6, tileSize, tileSize/6)  -- Bottom edge
            love.graphics.rectangle("fill", x, y, tileSize/6, tileSize)  -- Left edge
            love.graphics.rectangle("fill", x + tileSize*5/6, y, tileSize/6, tileSize)  -- Right edge
            
            -- Cave border (very dark)
            love.graphics.setColor(0.05, 0.05, 0.05)
            love.graphics.rectangle("line", x, y, tileSize, tileSize)
        else
            -- Normal tile rendering
            love.graphics.setColor(color[1], color[2], color[3])
            love.graphics.rectangle("fill", x, y, tileSize, tileSize)
            
            -- Add a subtle border for better visibility
            love.graphics.setColor(0.8, 0.8, 0.8, 0.3)
            love.graphics.rectangle("line", x, y, tileSize, tileSize)
        end
    end
end

-- Function to draw the entire tilemap
local function drawTilemap()
    local windowWidth = love.graphics.getWidth()
    local windowHeight = love.graphics.getHeight()
    local mapWidth = mapCols * tileSize
    local mapHeight = mapRows * tileSize
    
    -- Center the tilemap on screen
    local offsetX = (windowWidth - mapWidth) / 2
    local offsetY = (windowHeight - mapHeight) / 2
    
    for row = 1, mapRows do
        for col = 1, mapCols do
            local tileType = tilemap[row][col]
            local x = offsetX + (col - 1) * tileSize
            local y = offsetY + (row - 1) * tileSize
            drawTile(tileType, x, y)
        end
    end
end

-- Function to draw the player
local function drawPlayer()
    local alpha = player.invulnerable and (0.5 + 0.5 * math.sin(player.invulnTime * 20)) or 1.0
    
    -- Check if player is in water or quicksand
    local playerTileX = math.floor(player.x / tileSize) + 1
    local playerTileY = math.floor(player.y / tileSize) + 1
    local isInWater = false
    local isInQuicksand = false
    
    if tilemap[playerTileY] and tilemap[playerTileY][playerTileX] == "water" then
        isInWater = true
    elseif tilemap[playerTileY] and tilemap[playerTileY][playerTileX] == "quicksand" then
        isInQuicksand = true
    end
    
    -- Draw trail first
    drawTrail()
    
    -- Draw outer glow with different color based on terrain
    if player.invincible then
        -- Rainbow glow when invincible
        local hue = (effects.pulseTime * 8) % (math.pi * 2)
        local r = 0.5 + 0.5 * math.sin(hue)
        local g = 0.5 + 0.5 * math.sin(hue + math.pi * 2/3)
        local b = 0.5 + 0.5 * math.sin(hue + math.pi * 4/3)
        love.graphics.setColor(r, g, b, 0.8 * effects.glowIntensity)
    elseif isInWater then
        love.graphics.setColor(0.1, 0.4, 0.8, 0.4 * effects.glowIntensity)
    elseif isInQuicksand then
        love.graphics.setColor(0.9, 0.7, 0.3, 0.5 * effects.glowIntensity)
    else
        love.graphics.setColor(0.2, 0.8, 1.0, 0.3 * effects.glowIntensity)
    end
    love.graphics.circle("fill", player.x, player.y, player.size/2 + 8)
    
    -- Draw main player body with pulsing effect
    local pulseSize = player.size/2 + math.sin(effects.pulseTime * 5) * 2
    if player.invincible then
        -- Rainbow player when invincible
        local hue = (effects.pulseTime * 10) % (math.pi * 2)
        local r = 0.5 + 0.5 * math.sin(hue)
        local g = 0.5 + 0.5 * math.sin(hue + math.pi * 2/3)
        local b = 0.5 + 0.5 * math.sin(hue + math.pi * 4/3)
        love.graphics.setColor(r, g, b, alpha)
        pulseSize = pulseSize + math.sin(effects.pulseTime * 12) * 5  -- Intense pulsing when invincible
    elseif isInWater then
        love.graphics.setColor(0.1, 0.5, 0.9, alpha)  -- Darker blue when swimming
        pulseSize = pulseSize + math.sin(effects.pulseTime * 8) * 3  -- More pulsing in water
    elseif isInQuicksand then
        love.graphics.setColor(0.9, 0.6, 0.2, alpha)  -- Brown/yellow when in quicksand
        pulseSize = pulseSize + math.sin(effects.pulseTime * 10) * 4  -- Even more pulsing in quicksand
    else
        love.graphics.setColor(0.2, 0.6, 1.0, alpha)  -- Normal blue
    end
    love.graphics.circle("fill", player.x, player.y, pulseSize)
    
    -- Draw energy ring
    local energyPercent = player.energy / player.maxEnergy
    if player.invincible then
        -- Rainbow energy ring when invincible
        local hue = (effects.pulseTime * 6) % (math.pi * 2)
        local r = 0.5 + 0.5 * math.sin(hue)
        local g = 0.5 + 0.5 * math.sin(hue + math.pi * 2/3)
        local b = 0.5 + 0.5 * math.sin(hue + math.pi * 4/3)
        love.graphics.setColor(r, g, b, alpha)
    elseif energyPercent < 0.3 or isInWater or isInQuicksand then
        love.graphics.setColor(1.0, 0.2, 0.2, alpha)  -- Red warning
    else
        love.graphics.setColor(0.2, 0.8, 0.2, alpha)  -- Green energy
    end
    love.graphics.arc("line", player.x, player.y, pulseSize + 4, 0, energyPercent * math.pi * 2, 20)
    
    -- Draw white border
    love.graphics.setColor(1.0, 1.0, 1.0, alpha)
    love.graphics.circle("line", player.x, player.y, pulseSize)
    
    -- Draw center core with different effect based on terrain
    love.graphics.setColor(1.0, 1.0, 1.0, alpha)
    if isInWater then
        love.graphics.circle("fill", player.x, player.y, 4 + math.sin(effects.pulseTime * 12) * 2)
    elseif isInQuicksand then
        love.graphics.circle("fill", player.x, player.y, 5 + math.sin(effects.pulseTime * 15) * 3)
    else
        love.graphics.circle("fill", player.x, player.y, 3 + math.sin(effects.pulseTime * 8) * 1)
    end
    
    -- Draw terrain indicators
    if isInWater then
        love.graphics.setColor(0.8, 0.8, 1.0, alpha)
        love.graphics.circle("line", player.x, player.y, player.size/2 + 12)
    elseif isInQuicksand then
        love.graphics.setColor(0.9, 0.7, 0.3, alpha)
        love.graphics.circle("line", player.x, player.y, player.size/2 + 15)
    end
end

-- Function to draw collectibles
local function drawCollectibles()
    for _, collectible in ipairs(collectibles) do
        if not collectible.collected then
            local x = collectible.x * tileSize
            local y = collectible.y * tileSize
            
            -- Pulsing glow with individual timing
            local pulse = 0.5 + 0.5 * math.sin(collectible.pulse)
            local size = collectible.size + pulse * 6
            local glowAlpha = 0.4 * pulse * collectible.glowIntensity
            
            -- Outer glow
            love.graphics.setColor(1.0, 1.0, 0.0, glowAlpha)
            love.graphics.circle("fill", x, y, size + 12)
            
            -- Middle glow
            love.graphics.setColor(1.0, 0.8, 0.2, glowAlpha * 0.7)
            love.graphics.circle("fill", x, y, size + 6)
            
            -- Main collectible with rainbow effect
            local hue = (collectible.pulse * 0.5) % (math.pi * 2)
            local r = 0.5 + 0.5 * math.sin(hue)
            local g = 0.5 + 0.5 * math.sin(hue + math.pi * 2/3)
            local b = 0.5 + 0.5 * math.sin(hue + math.pi * 4/3)
            
            love.graphics.setColor(r, g, b, pulse)
            love.graphics.circle("fill", x, y, size)
            
            -- Inner core with energy effect
            love.graphics.setColor(1.0, 1.0, 0.8, pulse)
            love.graphics.circle("fill", x, y, size * 0.6)
            
            -- Center sparkle
            love.graphics.setColor(1.0, 1.0, 1.0, pulse)
            love.graphics.circle("fill", x, y, 2)
        end
    end
end

-- Function to draw enemies
local function drawEnemies()
    for _, enemy in ipairs(enemies) do
        local x = enemy.x * tileSize
        local y = enemy.y * tileSize
        
        -- Pulsing red glow
        local pulse = 0.5 + 0.5 * math.sin(enemy.pulse)
        local size = enemy.size + pulse * 8
        
        -- Outer glow
        love.graphics.setColor(1.0, 0.1, 0.1, 0.5 * pulse)
        love.graphics.circle("fill", x, y, size + 15)
        
        -- Middle glow
        love.graphics.setColor(1.0, 0.2, 0.2, 0.3 * pulse)
        love.graphics.circle("fill", x, y, size + 8)
        
        -- Main enemy body with different colors for fast vs slow
        if enemy.isFast then
            love.graphics.setColor(0.8, 0.2, 0.0, pulse)  -- Orange-red for fast enemies
        else
            love.graphics.setColor(0.6, 0.0, 0.0, pulse)  -- Dark red for slow enemies
        end
        love.graphics.circle("fill", x, y, size)
        
        -- Inner dark core
        if enemy.isFast then
            love.graphics.setColor(0.4, 0.1, 0.0, pulse)  -- Darker orange for fast enemies
        else
            love.graphics.setColor(0.2, 0.0, 0.0, pulse)  -- Dark red for slow enemies
        end
        love.graphics.circle("fill", x, y, size * 0.7)
        
        -- Rotating spikes
        love.graphics.setColor(1.0, 0.4, 0.4, pulse)
        for i = 0, 11 do
            local angle = i * math.pi / 6 + enemy.pulse * 2
            local spikeX = x + math.cos(angle) * (size + 5)
            local spikeY = y + math.sin(angle) * (size + 5)
            love.graphics.circle("fill", spikeX, spikeY, 3)
        end
        
        -- Center eye with different colors based on state
        if enemy.isSearching then
            love.graphics.setColor(1.0, 0.5, 0.0)  -- Orange eye when searching
        else
            love.graphics.setColor(1.0, 0.8, 0.8)  -- Normal white eye
        end
        love.graphics.circle("fill", x, y, 3)
        
        -- Search indicator (question mark above searching enemies)
        if enemy.isSearching then
            love.graphics.setColor(1.0, 1.0, 0.0, 0.8)
            love.graphics.print("?", x - 3, y - size - 15)
        end
    end
end

-- Function to draw sharks
local function drawSharks()
    for _, shark in ipairs(sharks) do
        local x = shark.x * tileSize
        local y = shark.y * tileSize
        
        -- Aggressive pulsing red glow
        local pulse = 0.7 + 0.3 * math.sin(shark.pulse)
        local size = shark.size + pulse * 10
        
        -- Outer blood-red glow
        love.graphics.setColor(1.0, 0.0, 0.0, 0.6 * pulse)
        love.graphics.circle("fill", x, y, size + 20)
        
        -- Middle dark red glow
        love.graphics.setColor(0.8, 0.0, 0.0, 0.4 * pulse)
        love.graphics.circle("fill", x, y, size + 12)
        
        -- Main shark body - dark gray/black
        love.graphics.setColor(0.2, 0.2, 0.2, pulse)
        love.graphics.circle("fill", x, y, size)
        
        -- Shark fin
        love.graphics.setColor(0.4, 0.4, 0.4, pulse)
        love.graphics.circle("fill", x + size * 0.7, y - size * 0.7, size * 0.3)
        
        -- Menacing eyes
        love.graphics.setColor(1.0, 0.0, 0.0, pulse)
        love.graphics.circle("fill", x - size * 0.3, y - size * 0.2, 4)
        love.graphics.circle("fill", x + size * 0.3, y - size * 0.2, 4)
        
        -- Teeth
        love.graphics.setColor(1.0, 1.0, 1.0, pulse)
        for i = 0, 7 do
            local angle = i * math.pi / 4 + shark.pulse
            local toothX = x + math.cos(angle) * (size + 5)
            local toothY = y + math.sin(angle) * (size + 5)
            love.graphics.circle("fill", toothX, toothY, 2)
        end
        
        -- Warning rings when close to player
        local sharkScreenX = shark.x * tileSize
        local sharkScreenY = shark.y * tileSize
        local distance = math.sqrt((player.x - sharkScreenX)^2 + (player.y - sharkScreenY)^2)
        
        if distance < 100 then
            love.graphics.setColor(1.0, 0.0, 0.0, 0.3)
            love.graphics.circle("line", x, y, size + 25)
            love.graphics.circle("line", x, y, size + 35)
        end
    end
end

-- Function to draw power-ups (invincibility stars)
local function drawPowerups()
    for _, powerup in ipairs(powerups) do
        if not powerup.collected then
            local x = powerup.x * tileSize
            local y = powerup.y * tileSize
            
            -- Rainbow pulsing effect
            local pulse = 0.5 + 0.5 * math.sin(powerup.pulse)
            local size = powerup.size + pulse * 8
            
            -- Rainbow color cycling
            local hue = powerup.rainbowPhase % (math.pi * 2)
            local r = 0.5 + 0.5 * math.sin(hue)
            local g = 0.5 + 0.5 * math.sin(hue + math.pi * 2/3)
            local b = 0.5 + 0.5 * math.sin(hue + math.pi * 4/3)
            
            -- Outer rainbow glow
            love.graphics.setColor(r, g, b, 0.6 * pulse)
            love.graphics.circle("fill", x, y, size + 20)
            
            -- Middle glow
            love.graphics.setColor(r, g, b, 0.4 * pulse)
            love.graphics.circle("fill", x, y, size + 12)
            
            -- Draw star shape (8-pointed star)
            love.graphics.setColor(r, g, b, pulse)
            for i = 0, 7 do
                local angle = i * math.pi / 4
                local outerX = x + math.cos(angle) * size
                local outerY = y + math.sin(angle) * size
                local innerX = x + math.cos(angle + math.pi / 8) * (size * 0.5)
                local innerY = y + math.sin(angle + math.pi / 8) * (size * 0.5)
                
                love.graphics.line(x, y, outerX, outerY)
                love.graphics.line(outerX, outerY, innerX, innerY)
            end
            
            -- Center core
            love.graphics.setColor(1.0, 1.0, 1.0, pulse)
            love.graphics.circle("fill", x, y, size * 0.3)
        end
    end
end

function love.draw()
    -- Clear screen with dark background
    love.graphics.setColor(0.05, 0.05, 0.1)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    -- Apply screen shake
    local shakeX = (math.random() - 0.5) * effects.screenShake * effects.screenShakeIntensity
    local shakeY = (math.random() - 0.5) * effects.screenShake * effects.screenShakeIntensity
    love.graphics.translate(shakeX, shakeY)
    
    -- Apply camera transform
    love.graphics.translate(-camera.x, -camera.y)
    
    -- Draw the tilemap (background)
    drawTilemap()
    
    -- Draw collectibles
    drawCollectibles()
    
    -- Draw power-ups
    drawPowerups()
    
    -- Draw enemies
    drawEnemies()
    
    -- Draw sharks
    drawSharks()
    
    -- Draw particle effects
    drawParticles()
    
    -- Draw the player on top
    drawPlayer()
    
    -- Reset transforms for UI
    love.graphics.translate(camera.x, camera.y)
    love.graphics.translate(-shakeX, -shakeY)
    
    -- Draw UI
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 320, 170)
    
    -- Check if player is in dangerous terrain for status display
    local playerTileX = math.floor(player.x / tileSize) + 1
    local playerTileY = math.floor(player.y / tileSize) + 1
    local isInWater = tilemap[playerTileY] and tilemap[playerTileY][playerTileX] == "water"
    local isInQuicksand = tilemap[playerTileY] and tilemap[playerTileY][playerTileX] == "quicksand"
    local isInCave = tilemap[playerTileY] and tilemap[playerTileY][playerTileX] == "cave"
    local isOnMountain = tilemap[playerTileY] and tilemap[playerTileY][playerTileX] == "mountain"
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Earth Survival", 10, 10)
    love.graphics.print("Score: " .. score, 10, 30)
    love.graphics.print("Energy: " .. math.floor(player.energy) .. "/" .. player.maxEnergy, 10, 50)
    love.graphics.print("Time: " .. string.format("%.1f", gameTime) .. "s", 10, 70)
    
    -- Count remaining orbs
    local remainingOrbs = 0
    for _, orb in ipairs(collectibles) do
        if not orb.collected then
            remainingOrbs = remainingOrbs + 1
        end
    end
    
    love.graphics.setColor(1.0, 1.0, 0.2)  -- Golden color for orbs
    love.graphics.print("Orbs Remaining: " .. remainingOrbs, 10, 90)
    
    -- Show enemy count and types
    local fastEnemies = 0
    local searchingEnemies = 0
    for _, enemy in ipairs(enemies) do
        if enemy.isFast then
            fastEnemies = fastEnemies + 1
        end
        if enemy.isSearching then
            searchingEnemies = searchingEnemies + 1
        end
    end
    
    love.graphics.setColor(1.0, 0.2, 0.2)  -- Red for enemies
    love.graphics.print("Enemies: " .. fastEnemies .. " fast, " .. (#enemies - fastEnemies) .. " slow", 10, 110)
    if searchingEnemies > 0 then
        love.graphics.setColor(1.0, 0.5, 0.0)  -- Orange for searching
        love.graphics.print("Searching: " .. searchingEnemies .. " enemies looking for you!", 10, 130)
    end
    
    -- Show terrain status and warnings (adjusted for new UI layout)
    local terrainY = searchingEnemies > 0 and 150 or 130
    
    if isInWater then
        love.graphics.setColor(0.1, 0.5, 0.9)
        love.graphics.print("SWIMMING - Energy draining!", 10, terrainY)
        
        -- Show shark count and time in water
        love.graphics.setColor(1.0, 0.2, 0.2)
        love.graphics.print("SHARKS: " .. #sharks .. " | Time in water: " .. string.format("%.1f", timeInWater) .. "s", 10, terrainY + 20)
        
        if #sharks > 0 then
            love.graphics.setColor(1.0, 0.0, 0.0)
            love.graphics.print("DANGER! SHARKS APPROACHING!", 10, terrainY + 40)
        end
    elseif isInQuicksand then
        love.graphics.setColor(0.9, 0.7, 0.3)
        love.graphics.print("SINKING IN QUICKSAND!", 10, terrainY)
        love.graphics.setColor(1.0, 0.5, 0.0)
        love.graphics.print("Energy draining faster than swimming!", 10, terrainY + 20)
    elseif isInCave then
        love.graphics.setColor(0.3, 0.3, 0.3)
        love.graphics.print("IN CAVE TUNNEL - HIDING FROM ENEMIES!", 10, terrainY)
        love.graphics.setColor(0.5, 0.5, 0.5)
        love.graphics.print("Safe passage through mountains", 10, terrainY + 20)
    elseif isOnMountain then
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.print("BLOCKED BY MOUNTAIN!", 10, terrainY)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("Enemies can climb over mountains", 10, terrainY + 20)
    else
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.print("On Land - Energy regenerating", 10, terrainY)
    end
    
    -- Show invincibility status
    if player.invincible then
        love.graphics.setColor(1.0, 0.0, 1.0)  -- Magenta for invincibility
        love.graphics.print("INVINCIBLE! Time: " .. string.format("%.1f", player.invincibleTime) .. "s", 10, 170)
    end
    
    -- Draw energy bar (moved down to accommodate orbs counter)
    local barWidth = 200
    local barHeight = 10
    local energyPercent = player.energy / player.maxEnergy
    local barY = 170  -- Moved down from 90
    
    love.graphics.setColor(0.3, 0.3, 0.3)
    love.graphics.rectangle("fill", 10, barY, barWidth, barHeight)
    
    love.graphics.setColor(0.2, 0.8, 0.2, effects.glowIntensity)
    love.graphics.rectangle("fill", 10, barY, barWidth * energyPercent, barHeight)
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 10, barY, barWidth, barHeight)
    
    -- Game over screen
    if isGameOver then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        love.graphics.setColor(1, 0.2, 0.2)
        love.graphics.printf("GAME OVER!", 0, love.graphics.getHeight()/2 - 50, love.graphics.getWidth(), "center")
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("Final Score: " .. score, 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
        love.graphics.printf("Time Survived: " .. string.format("%.1f", gameTime) .. "s", 0, love.graphics.getHeight()/2 + 10, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R to Restart", 0, love.graphics.getHeight()/2 + 40, love.graphics.getWidth(), "center")
    end
    
    -- Victory screen
    if isVictory then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        
        love.graphics.setColor(1, 1, 0.2)  -- Golden victory color
        love.graphics.printf("VICTORY!", 0, love.graphics.getHeight()/2 - 80, love.graphics.getWidth(), "center")
        
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("All orbs collected!", 0, love.graphics.getHeight()/2 - 50, love.graphics.getWidth(), "center")
        love.graphics.printf("Final Score: " .. score, 0, love.graphics.getHeight()/2 - 20, love.graphics.getWidth(), "center")
        love.graphics.printf("Time: " .. string.format("%.1f", gameTime) .. "s", 0, love.graphics.getHeight()/2 + 10, love.graphics.getWidth(), "center")
        love.graphics.printf("Press R to Play Again", 0, love.graphics.getHeight()/2 + 40, love.graphics.getWidth(), "center")
    end
    
    -- Instructions
    if not isGameOver and not isVictory then
        love.graphics.setColor(0.8, 0.8, 0.8, 0.7)
        love.graphics.print("Arrow Keys: Move | F/F11: Fullscreen | ESC: Quit", 10, love.graphics.getHeight() - 100)
        love.graphics.print("Collect " .. #collectibles .. " rainbow orbs, avoid " .. #enemies .. " deadly enemies!", 10, love.graphics.getHeight() - 80)
        love.graphics.print("Water drains energy, quicksand drains even MORE energy!", 10, love.graphics.getHeight() - 60)
        love.graphics.print("STAY IN WATER TOO LONG = SHARKS SPAWN!", 10, love.graphics.getHeight() - 40)
        love.graphics.print("Black caves hide you from enemies - use them strategically!", 10, love.graphics.getHeight() - 20)
    end
end

-- Add restart functionality and fullscreen toggle
function love.keypressed(key)
    if key == "r" and (isGameOver or isVictory) then
        -- Reset game state
        isGameOver = false
        isVictory = false
        score = 0
        gameTime = 0
        setPlayerEnergy(player.maxEnergy)
        player.invulnerable = false
        player.invulnTime = 0
        effects.particles = {}
        effects.screenShake = 0
        
        -- Regenerate game content
        generateCollectibles()
        generateEnemies()
        generateSharks()
        generatePowerups()
        
        -- Reset water tracking and power-ups
        timeInWater = 0
        sharkSpawnTimer = 0
        powerupSpawnTimer = 0
        player.invincible = false
        player.invincibleTime = 0
        
        -- Reset player position
        player.x = (mapCols / 2) * tileSize
        player.y = (mapRows / 2) * tileSize
    elseif key == "f11" or key == "f" then
        -- Toggle fullscreen
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
    elseif key == "escape" then
        -- Exit game
        love.event.quit()
    end
end

-- Initialize game content after everything is defined
function love.load()
    -- Generate the world first
    generateWorld()
    
    -- Get screen dimensions for fullscreen
    local screenWidth, screenHeight = love.window.getDesktopDimensions()
    
    love.window.setMode(screenWidth, screenHeight, {
        resizable = true,
        minwidth = 800,
        minheight = 600,
        centered = true,
        fullscreen = true
    })
    
    -- Update map dimensions after world generation
    mapRows = #tilemap
    mapCols = #tilemap[1]
    
    -- Generate game content
    generateCollectibles()
    generateEnemies()
    generateSharks()
    generatePowerups()
    
    -- Set initial player position to center of the world
    player.x = (mapCols / 2) * tileSize
    player.y = (mapRows / 2) * tileSize
    
    -- Set camera to follow player
    camera.x = player.x - screenWidth / 2
    camera.y = player.y - screenHeight / 2
end
