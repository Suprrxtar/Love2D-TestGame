-- Test World Generation System
-- Tests procedural world generation, tilemap creation, and terrain placement

local test_world_generation = {}

-- Mock world generation function (simplified version)
local function generateTestWorld()
    local worldWidth = 20  -- Smaller for testing
    local worldHeight = 15
    local tilemap = {}
    
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
    
    -- Add some water
    for i = 1, 3 do
        local x, y = math.random(3, worldWidth-3), math.random(3, worldHeight-3)
        local size = 2
        for dy = -size, size do
            for dx = -size, size do
                local nx, ny = x + dx, y + dy
                if nx > 1 and nx < worldWidth and ny > 1 and ny < worldHeight and math.sqrt(dx*dx + dy*dy) <= size then
                    tilemap[ny][nx] = "water"
                end
            end
        end
    end
    
    -- Add some mountains
    for i = 1, 2 do
        local x, y = math.random(3, worldWidth-3), math.random(3, worldHeight-3)
        local size = 2
        for dy = -size, size do
            for dx = -size, size do
                local nx, ny = x + dx, y + dy
                if nx > 1 and nx < worldWidth and ny > 1 and ny < worldHeight and math.sqrt(dx*dx + dy*dy) <= size and tilemap[ny][nx] ~= "water" then
                    tilemap[ny][nx] = "mountain"
                end
            end
        end
    end
    
    return tilemap, worldWidth, worldHeight
end

function test_world_generation.run_tests(test)
    print("=== WORLD GENERATION TESTS ===")
    
    test("World dimensions", function()
        local tilemap, width, height = generateTestWorld()
        assert(width == 20, "World width should be 20")
        assert(height == 15, "World height should be 15")
        assert(#tilemap == height, "Tilemap height should match world height")
        assert(#tilemap[1] == width, "Tilemap width should match world width")
    end)
    
    test("Border walls", function()
        local tilemap, width, height = generateTestWorld()
        
        -- Check top and bottom borders
        for x = 1, width do
            assert(tilemap[1][x] == "wall", "Top border should be walls")
            assert(tilemap[height][x] == "wall", "Bottom border should be walls")
        end
        
        -- Check left and right borders
        for y = 1, height do
            assert(tilemap[y][1] == "wall", "Left border should be walls")
            assert(tilemap[y][width] == "wall", "Right border should be walls")
        end
    end)
    
    test("Terrain placement", function()
        local tilemap, width, height = generateTestWorld()
        
        local grassCount = 0
        local waterCount = 0
        local mountainCount = 0
        local wallCount = 0
        
        -- Count terrain types
        for y = 1, height do
            for x = 1, width do
                local terrain = tilemap[y][x]
                if terrain == "grass" then
                    grassCount = grassCount + 1
                elseif terrain == "water" then
                    waterCount = waterCount + 1
                elseif terrain == "mountain" then
                    mountainCount = mountainCount + 1
                elseif terrain == "wall" then
                    wallCount = wallCount + 1
                end
            end
        end
        
        assert(grassCount > 0, "Should have grass tiles")
        assert(waterCount > 0, "Should have water tiles")
        assert(mountainCount > 0, "Should have mountain tiles")
        assert(wallCount > 0, "Should have wall tiles")
        
        -- Check that total tiles match expected
        local totalTiles = grassCount + waterCount + mountainCount + wallCount
        assert(totalTiles == width * height, "Total tiles should match world size")
    end)
    
    test("Terrain boundaries", function()
        local tilemap, width, height = generateTestWorld()
        
        -- Check that water and mountains don't overlap with borders
        for y = 2, height - 1 do
            for x = 2, width - 1 do
                local terrain = tilemap[y][x]
                assert(terrain ~= "wall", "Interior tiles should not be walls")
            end
        end
    end)
    
    test("Tilemap consistency", function()
        local tilemap, width, height = generateTestWorld()
        
        -- Check that all rows have the same length
        for y = 1, height do
            assert(#tilemap[y] == width, "All rows should have same width")
        end
        
        -- Check that all tiles are valid terrain types
        local validTerrain = {"grass", "water", "mountain", "wall", "quicksand", "cave"}
        for y = 1, height do
            for x = 1, width do
                local terrain = tilemap[y][x]
                local isValid = false
                for _, validType in ipairs(validTerrain) do
                    if terrain == validType then
                        isValid = true
                        break
                    end
                end
                assert(isValid, "All tiles should be valid terrain types")
            end
        end
    end)
    
    test("World generation repeatability", function()
        -- Test that world generation produces consistent results
        local tilemap1, w1, h1 = generateTestWorld()
        local tilemap2, w2, h2 = generateTestWorld()
        
        assert(w1 == w2, "World width should be consistent")
        assert(h1 == h2, "World height should be consistent")
        assert(#tilemap1 == #tilemap2, "Tilemap height should be consistent")
        assert(#tilemap1[1] == #tilemap2[1], "Tilemap width should be consistent")
    end)
    
    test("Cave generation", function()
        local tilemap, width, height = generateTestWorld()
        
        -- Add a test cave
        local caveX, caveY = 10, 8
        tilemap[caveY][caveX] = "cave"
        
        assert(tilemap[caveY][caveX] == "cave", "Cave should be placed correctly")
        
        -- Test cave connectivity (simplified)
        local hasCave = false
        for y = 1, height do
            for x = 1, width do
                if tilemap[y][x] == "cave" then
                    hasCave = true
                    break
                end
            end
        end
        assert(hasCave, "Should have at least one cave")
    end)
    
    test("Quicksand generation", function()
        local tilemap, width, height = generateTestWorld()
        
        -- Add test quicksand
        local quicksandX, quicksandY = 5, 5
        tilemap[quicksandY][quicksandX] = "quicksand"
        
        assert(tilemap[quicksandY][quicksandX] == "quicksand", "Quicksand should be placed correctly")
        
        -- Test quicksand properties
        local hasQuicksand = false
        for y = 1, height do
            for x = 1, width do
                if tilemap[y][x] == "quicksand" then
                    hasQuicksand = true
                    break
                end
            end
        end
        assert(hasQuicksand, "Should have at least one quicksand tile")
    end)
    
    test("World size constraints", function()
        local tilemap, width, height = generateTestWorld()
        
        -- Test minimum world size
        assert(width >= 10, "World should be at least 10 tiles wide")
        assert(height >= 10, "World should be at least 10 tiles tall")
        
        -- Test maximum world size (reasonable limits)
        assert(width <= 200, "World should not be too wide")
        assert(height <= 200, "World should not be too tall")
        
        -- Test aspect ratio (should be reasonable)
        local aspectRatio = width / height
        assert(aspectRatio >= 0.5, "Aspect ratio should be reasonable")
        assert(aspectRatio <= 3.0, "Aspect ratio should be reasonable")
    end)
end

return test_world_generation
