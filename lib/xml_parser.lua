-- lib/xml_parser.lua
local XMLParser = {}
local DRUM_PARTS = {"drum1a", "drum1b", "drum2a", "drum2b", "drum3a", "drum3b"}

XMLParser.__index = XMLParser

function XMLParser.new()
    return setmetatable({}, XMLParser)
end

function XMLParser:parse_song(content)
    local song = {}
    local patterns = {}
    content = content:gsub("\n", "")
    content = content:gsub("> ", ">")
    content = content:gsub("  ", " ")

    song.title = content:match("<title>%s*(.-)%s*</title>")

    song.bpm = tonumber(content:match("<bpm>%s*(%d+)%s*</bpm>"))

    for pattern_chunk in content:gmatch("<pattern>(.-)</pattern>") do
        local pattern = {}
        
        print("Parsing pattern")
        for _, drum_part in ipairs(DRUM_PARTS) do
            local drum_data = pattern_chunk:match("<" .. drum_part .. ">(.-)</" .. drum_part .. ">")
            if drum_data then
                local steps = {}
                for step in drum_data:gmatch("%S+") do
                    table.insert(steps, tonumber(step) or 0)
                end
                if #steps == 128 then
                    pattern[drum_part] = {
                        steps = steps,
                        sample_name = drum_part,
                        volume = 1
                    }
                else
                    print("Warning: Expected 128 steps for " .. drum_part .. ", got " .. #steps)
                end
            end
        end

        table.insert(patterns, pattern)
        print("Pattern added. Current pattern count:", #patterns)
    end

    song.patterns = patterns
    print("Total patterns in song:", #song.patterns)

    return song
end

function XMLParser:serialize_song(song)
    local output = string.format('<title>%s</title>\n<bpm>%d</bpm>\n<patterns>\n', song.title, song.bpm)
    
    for _, pattern in ipairs(song.patterns) do
        output = output .. "<pattern>\n"
        for drum, rows in pairs(pattern) do
            if drum:match("drum%da") or drum:match("drum%db") then
                output = output .. string.format("  <%s>\n", drum)
                for _, row in ipairs(rows) do
                    output = output .. "    "
                    for _, step in ipairs(row.steps) do
                        output = output .. string.format("%d ", step)
                    end
                    output = output .. "\n"
                end
                output = output .. string.format("  </%s>\n", drum)
            end
        end
        output = output .. "</pattern>\n"
    end
    
    output = output .. "</patterns>\n"
    return output
end

return XMLParser
