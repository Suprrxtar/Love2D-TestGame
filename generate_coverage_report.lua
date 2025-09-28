-- Standalone Coverage Report Generator
-- Run with: lua generate_coverage_report.lua

-- Set package.path to find modules in the tests folder
package.path = package.path .. ";./tests/?.lua"

local test_coverage = require("tests.test_coverage")

print("Generating Test Coverage Report for Earth Survival Game...")
print("")

-- Initialize and analyze
test_coverage.init()
test_coverage.analyze_main_lua()
test_coverage.simulate_test_coverage()

-- Generate and display report
local coverage_report = test_coverage.generate_report()
print(coverage_report)

-- Write report to file
local file = io.open("coverage_report.txt", "w")
if file then
    file:write(coverage_report)
    file:close()
    print("")
    print("Coverage report saved to: coverage_report.txt")
else
    print("")
    print("Failed to save coverage report to file")
end

print("")
print("Press Enter to exit...")
local _ = io.read()  -- Capture the return value to avoid linter warning
