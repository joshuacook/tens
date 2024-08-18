-- lib/yaml_parser.lua
local YAMLParser = {}
YAMLParser.__index = YAMLParser

function YAMLParser.new()
    return setmetatable({}, YAMLParser)
end

function YAMLParser:parse_song(content)
    local song = {}
    local patterns = {}

    song.title = content:match("title:%s*\"(.-)\"")
    print("Title:", song.title)
    song.bpm = tonumber(content:match("bpm:%s*(%d+)"))
    print("BPM:", song.bpm)

    -- Parse patterns
    for pattern_chunk in content:gmatch("  -%s*name:%s*\"(.-)\"(.-)\n  %-") do
        local pattern_name, pattern_content = pattern_chunk:match("(.-)\"(.+)")
        
        print("Parsing pattern:", pattern.name)
        print("Pattern content (first 100 characters):", pattern_content:sub(1, 100))

        for drum_section in pattern_content:gmatch("    (drum%d[ab]):%s*|(.-)\n    %w") do
            local drum_key, drum_data = drum_section:match("(drum%d[ab]):%s*|(.+)")
            pattern[drum_key] = {}
            print("  Parsing drum section:", drum_key)
            print("  Drum data (first 50 characters):", drum_data:sub(1, 50))

            for line in drum_data:gmatch("[^\n]+") do
                line = line:gsub("^%s+", "") -- Remove leading spaces
                local parts = {}
                for part in line:gmatch("%S+") do
                    table.insert(parts, part)
                end
                
                if #parts >= 18 then
                    local steps = {}
                    for i = 1, 16 do
                        steps[i] = tonumber(parts[i]) or 0
                    end
                    local sample = parts[17]
                    local level = tonumber(parts[18]) or 1

                    table.insert(pattern[drum_key], {
                        steps = steps,
                        sample_name = sample,
                        volume = level
                    })
                    print("    Parsed line:", sample, level, table.concat(steps, " "))
                end
            end
        end

        table.insert(patterns, pattern)
        print("Pattern added. Current pattern count:", #patterns)
    end

    song.patterns = patterns
    print("Total patterns in song:", #song.patterns)

    -- Debug: Print structure of first pattern
    if #song.patterns > 0 then
        print("Structure of first pattern:")
        for k, v in pairs(song.patterns[1]) do
            if type(v) == "table" then
                print("  " .. k .. ": (table with " .. #v .. " entries)")
                for i, entry in ipairs(v) do
                    print("    Entry " .. i .. ":")
                    print("      Sample: " .. tostring(entry.sample_name))
                    print("      Volume: " .. tostring(entry.volume))
                    print("      Steps: " .. table.concat(entry.steps, " "))
                end
            else
                print("  " .. k .. ": " .. tostring(v))
            end
        end
    else
        print("No patterns parsed!")
    end

    return song
end

function YAMLParser:parse_patterns(patterns_section)
    local patterns = {}
    local current_pattern = nil
    local line_count = 0

    for line in patterns_section:gmatch("[^\r\n]+") do
        if line:find("%- |") then
            if current_pattern then
                table.insert(patterns, self:parse_single_pattern(current_pattern))
            end
            current_pattern = ""
            line_count = 0
        elseif current_pattern then
            current_pattern = current_pattern .. line .. "\n"
            line_count = line_count + 1
            if line_count == 16 then
                table.insert(patterns, self:parse_single_pattern(current_pattern))
                current_pattern = nil
            end
        end
    end

    if current_pattern then
        table.insert(patterns, self:parse_single_pattern(current_pattern))
    end

    return patterns
end

function YAMLParser:parse_single_pattern(pattern_str)
    local pattern = {}
    for row in string.gmatch(pattern_str, "[^\n]+") do
        local row_data = {}
        local col = 1
        for step in string.gmatch(row, "%S+") do
            if col <= 16 then
                row_data[col] = tonumber(step) or 0
            elseif col == 17 then
                row_data.drum_key = step
            elseif col == 18 then
                row_data.drum_level = tonumber(step) or 1
            end
            col = col + 1
        end
        table.insert(pattern, row_data)
    end
    return pattern
end

function YAMLParser:serialize_song(song)
    local output = string.format('title: "%s"\nbpm: %d\npatterns:\n', song.title, song.bpm)
    
    for _, pattern in ipairs(song.patterns) do
        output = output .. string.format('  - name: "%s"\n', pattern.name)
        for drum, rows in pairs(pattern) do
            if drum:match("drum%da") or drum:match("drum%db") then
                output = output .. string.format("    %s: |\n", drum)
                for _, row in ipairs(rows) do
                    output = output .. "      "
                    for _, step in ipairs(row.steps) do
                        output = output .. string.format("%d ", step)
                    end
                    output = output .. string.format("%s %d\n", row.sample_name, row.volume)
                end
            end
        end
    end
    
    return output
end

function YAMLParser:serialize_single_pattern(pattern)
    local pattern_str = ""
    for _, row in ipairs(pattern) do
        for col = 1, 16 do
            if col == 1 then
                pattern_str = pattern_str .. "    "
            end
            pattern_str = pattern_str .. row[col] .. " "
        end
        pattern_str = pattern_str .. (row.drum_key or "default_key") .. " "
        pattern_str = pattern_str .. (row.drum_level or "0") .. "\n"
    end
    return pattern_str
end

return YAMLParser