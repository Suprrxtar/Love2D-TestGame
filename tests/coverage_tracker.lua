-- Test Coverage Tracker
-- Tracks which lines of code are executed during tests

local coverage_tracker = {}

-- Coverage data storage
local coverage_data = {}
local original_functions = {}
local file_lines = {}

-- Initialize coverage tracking for a file
function coverage_tracker.init_file(filename)
    coverage_data[filename] = {}
    file_lines[filename] = {}
    
    -- Read the file and count lines
    local file = io.open(filename, "r")
    if file then
        local line_num = 1
        for line in file:lines() do
            file_lines[filename][line_num] = line
            coverage_data[filename][line_num] = false
            line_num = line_num + 1
        end
        file:close()
    end
end

-- Mark a line as executed
function coverage_tracker.mark_executed(filename, line_num)
    if coverage_data[filename] and coverage_data[filename][line_num] ~= nil then
        coverage_data[filename][line_num] = true
    end
end

-- Get coverage statistics for a file
function coverage_tracker.get_file_coverage(filename)
    if not coverage_data[filename] then
        return 0, 0, 0
    end
    
    local total_lines = 0
    local covered_lines = 0
    
    for line_num, covered in pairs(coverage_data[filename]) do
        local line = file_lines[filename][line_num]
        -- Skip empty lines and comments for coverage calculation
        if line and line:match("^%s*$") == nil and line:match("^%s*%-%-") == nil then
            total_lines = total_lines + 1
            if covered then
                covered_lines = covered_lines + 1
            end
        end
    end
    
    return covered_lines, total_lines, total_lines > 0 and (covered_lines / total_lines) * 100 or 0
end

-- Get overall coverage statistics
function coverage_tracker.get_overall_coverage()
    local total_covered = 0
    local total_lines = 0
    local file_stats = {}
    
    for filename, _ in pairs(coverage_data) do
        local covered, total, percentage = coverage_tracker.get_file_coverage(filename)
        file_stats[filename] = {
            covered = covered,
            total = total,
            percentage = percentage
        }
        total_covered = total_covered + covered
        total_lines = total_lines + total
    end
    
    local overall_percentage = total_lines > 0 and (total_covered / total_lines) * 100 or 0
    
    return {
        total_covered = total_covered,
        total_lines = total_lines,
        overall_percentage = overall_percentage,
        file_stats = file_stats
    }
end

-- Generate detailed coverage report
function coverage_tracker.generate_report()
    local stats = coverage_tracker.get_overall_coverage()
    local report = {}
    
    table.insert(report, "=" .. string.rep("=", 60))
    table.insert(report, "TEST COVERAGE REPORT")
    table.insert(report, "=" .. string.rep("=", 60))
    table.insert(report, "")
    
    -- Overall statistics
    table.insert(report, string.format("Overall Coverage: %.1f%% (%d/%d lines)", 
        stats.overall_percentage, stats.total_covered, stats.total_lines))
    table.insert(report, "")
    
    -- Per-file statistics
    table.insert(report, "File-by-File Coverage:")
    table.insert(report, string.rep("-", 60))
    
    for filename, file_stat in pairs(stats.file_stats) do
        local status = file_stat.percentage >= 80 and "✓" or 
                      file_stat.percentage >= 60 and "⚠" or "✗"
        table.insert(report, string.format("%s %s: %.1f%% (%d/%d lines)", 
            status, filename, file_stat.percentage, file_stat.covered, file_stat.total))
    end
    
    table.insert(report, "")
    
    -- Detailed line-by-line coverage for main.lua
    if coverage_data["main.lua"] then
        table.insert(report, "Detailed Coverage for main.lua:")
        table.insert(report, string.rep("-", 60))
        
        for line_num = 1, #file_lines["main.lua"] do
            local line = file_lines["main.lua"][line_num]
            local covered = coverage_data["main.lua"][line_num]
            local status = covered and "✓" or "✗"
            
            -- Only show non-empty, non-comment lines
            if line and line:match("^%s*$") == nil and line:match("^%s*%-%-") == nil then
                table.insert(report, string.format("%s %3d: %s", 
                    status, line_num, line:gsub("^%s*", ""):sub(1, 50)))
            end
        end
    end
    
    return table.concat(report, "\n")
end

-- Reset coverage data
function coverage_tracker.reset()
    coverage_data = {}
    file_lines = {}
end

-- Instrument a function to track coverage
function coverage_tracker.instrument_function(func, filename, line_num)
    return function(...)
        coverage_tracker.mark_executed(filename, line_num)
        return func(...)
    end
end

return coverage_tracker
