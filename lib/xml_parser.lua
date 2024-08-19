-- lib/xml_parser.lua
local XMLParser = {}
local DRUM_PARTS = {"drum1a", "drum1b", "drum2a", "drum2b"}

XMLParser.__index = XMLParser

function XMLParser.new()
    return setmetatable({}, XMLParser)
end

function XMLParser:parse_song(content)
    local song = {}
    local scenes = {}
    content = content:gsub("\n", "")
    content = content:gsub("> ", ">")
    content = content:gsub("  ", " ")

    song.title = content:match("<title>%s*(.-)%s*</title>")
    song.bpm = tonumber(content:match("<bpm>(%d+)</bpm>"))
    print("Song title:", song.title)
    print("Song bpm:", song.bpm)

    for scene_chunk in content:gmatch("<scene>(.-)</scene>") do
        local scene = {}
        
        print("Parsing scene")
        for _, drum_part in ipairs(DRUM_PARTS) do
            local drum_data = scene_chunk:match("<" .. drum_part .. ">(.-)</" .. drum_part .. ">")
            if drum_data then
                local steps = {}
                for step in drum_data:gmatch("%S+") do
                    table.insert(steps, tonumber(step) or 0)
                end
                if #steps == 128 then
                    scene[drum_part] = steps
                else
                    print("Warning: Expected 128 steps for " .. drum_part .. ", got " .. #steps)
                end
            end
        end

        table.insert(scenes, scene)
        print("Scene added. Current scene count:", #scenes)
    end

    song.scenes = scenes
    print("Total scenes in song:", #song.scenes)

    return song
end

function XMLParser:serialize_song(song)
    local output = string.format('<title>%s</title>\n<bpm>%d</bpm>\n<scenes>\n', song.title, song.bpm)
    
    for _, scene in ipairs(song.scenes) do
        output = output .. "<scene>\n"
        for _, drum_part in ipairs(DRUM_PARTS) do
            if scene[drum_part] then
                output = output .. string.format("  <%s>\n", drum_part)
                for i = 1, 8 do
                    output = output .. "    "
                    for j = 1, 16 do
                        local index = (i - 1) * 16 + j
                        output = output .. string.format("%d ", scene[drum_part][index])
                    end
                    output = output .. "\n"
                end
                output = output .. string.format("  </%s>\n", drum_part)
            end
        end
        output = output .. "</scene>\n"
    end
    
    output = output .. "</scenes>\n"
    return output
end

return XMLParser