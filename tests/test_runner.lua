-- Test Runner for Earth Survival Game
-- Run this file to execute all tests

local test_results = {
    passed = 0,
    failed = 0,
    total = 0
}

-- Global output buffer for file writing
_G.test_output_buffer = {}

local function test(name, test_func)
    test_results.total = test_results.total + 1
    local test_line = "Testing: " .. name
    print(test_line)
    table.insert(_G.test_output_buffer, test_line)
    
    local success, error_msg = pcall(test_func)
    
    if success then
        test_results.passed = test_results.passed + 1
        local pass_line = "✓ PASSED: " .. name
        print(pass_line)
        table.insert(_G.test_output_buffer, pass_line)
    else
        test_results.failed = test_results.failed + 1
        local fail_line = "✗ FAILED: " .. name .. " - " .. tostring(error_msg)
        print(fail_line)
        table.insert(_G.test_output_buffer, fail_line)
    end
    print("")
    table.insert(_G.test_output_buffer, "")
end

local function run_all_tests()
    local header1 = "=" .. string.rep("=", 50)
    local header2 = "EARTH SURVIVAL GAME - TEST SUITE"
    local header3 = "=" .. string.rep("=", 50)
    
    print(header1)
    print(header2)
    print(header3)
    print("")
    
    table.insert(_G.test_output_buffer, header1)
    table.insert(_G.test_output_buffer, header2)
    table.insert(_G.test_output_buffer, header3)
    table.insert(_G.test_output_buffer, "")
    
    -- Load test modules from tests folder
local test_modules = {
    "tests.test_player",
    "tests.test_world_generation", 
    "tests.test_enemy_ai",
    "tests.test_collision_detection",
    "tests.test_game_mechanics",
    "tests.test_ui_systems",
    "tests.test_coverage"
}
    
    for _, module_name in ipairs(test_modules) do
        local success, module = pcall(require, module_name)
        if success and module then
            print("Running " .. module_name .. " tests...")
            if module.run_tests then
                module.run_tests(test)
            end
        else
            print("Warning: Could not load " .. module_name)
        end
    end
    
    -- Print final results
    print("=" .. string.rep("=", 50))
    print("TEST RESULTS SUMMARY")
    print("=" .. string.rep("=", 50))
    print("Total Tests: " .. test_results.total)
    print("Passed: " .. test_results.passed)
    print("Failed: " .. test_results.failed)
    print("Success Rate: " .. string.format("%.1f%%", (test_results.passed / test_results.total) * 100))
    
            if test_results.failed == 0 then
                print("🎉 ALL TESTS PASSED! 🎉")
                table.insert(_G.test_output_buffer, "🎉 ALL TESTS PASSED! 🎉")
            else
                print("⚠️  Some tests failed. Check the output above.")
                table.insert(_G.test_output_buffer, "⚠️  Some tests failed. Check the output above.")
            end
            
            -- Generate coverage report
            print("")
            print("Generating coverage report...")
            table.insert(_G.test_output_buffer, "")
            table.insert(_G.test_output_buffer, "Generating coverage report...")
            
            local coverage_module = require("tests.test_coverage")
            if coverage_module then
                coverage_module.init()
                coverage_module.analyze_main_lua()
                coverage_module.simulate_test_coverage()
                
                local coverage_report = coverage_module.generate_report()
                print(coverage_report)
                table.insert(_G.test_output_buffer, coverage_report)
            end
    
    -- Write results to file
    local file = io.open("test_results.txt", "w")
    if file then
        for _, line in ipairs(_G.test_output_buffer) do
            file:write(line .. "\n")
        end
        file:close()
        print("Results written to test_results.txt")
    end
end

-- Run tests when this file is executed
if arg and arg[0] and string.find(arg[0], "test_runner") then
    run_all_tests()
end

return {
    run_tests = run_all_tests,
    test = test,
    results = test_results
}
