-- Test Project Main Entry Point
-- This file runs the test suite

-- Load the test runner from the parent directory
local test_runner = require("tests.test_runner")

-- Redirect print output to a file in the project root
local test_output = {}
local original_print = print
print = function(...)
    local args = {...}
    local line = table.concat(args, "\t")
    table.insert(test_output, line)
    original_print(...)
end

function love.load()
    print("Starting Earth Survival Game Tests...")
    test_runner.run_tests()
    print("Tests completed!")
    
    -- Write output to file in project root using io.open
    local file = io.open("../test_results.txt", "w")
    if file then
        for _, line in ipairs(test_output) do
            file:write(line .. "\n")
        end
        file:close()
        print("Results written to: test_results.txt")
    else
        print("Failed to write test results file")
    end
end

function love.draw()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Tests completed! Check test_results.txt", 10, 10)
    love.graphics.print("Press ESC to exit.", 10, 30)
    love.graphics.print("Total tests: " .. #test_output, 10, 50)
end

function love.keypressed(key)
    if key == "escape" then
        love.event.quit()
    end
end
