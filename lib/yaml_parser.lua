-- lib/yaml_parser.lua
local YAMLParser = {}
YAMLParser.__index = YAMLParser

function YAMLParser.new()
    return setmetatable({}, YAMLParser)
end

function YAMLParser:parse_song(content)
    local song = {}
    local patterns = {}
    
    -- Parse title and bpm
    song.title = content:match("title:%s*\"(.-)\"")
    song.bpm = tonumber(content:match("bpm:%s*(%d+)"))
    
    -- Parse patterns
    for pattern_content in content:gmatch("%-name:%s*\"(.-)\"(.-)\n[%s%-]") do
        local pattern = {}
        pattern.name = pattern_content:match("\"(.-)\"")
        
        for drum, drum_content in pattern_content:gmatch("(drum%da):%s*|(.-)\n[%s%w]") do
            pattern[drum] = {}
            for line in drum_content:gmatch("[^\n]+") do
                local steps = {}
                for step in line:gmatch("%d+") do
                    table.insert(steps, tonumber(step))
                end
                local sample_name, volume = line:match("(%w+)%s+(%d+)$")
                table.insert(pattern[drum], {
                    steps = steps,
                    sample_name = sample_name,
                    volume = tonumber(volume)
                })
            end
        end
        
        table.insert(patterns, pattern)
    end
    
    song.patterns = patterns
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