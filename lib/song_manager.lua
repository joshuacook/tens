-- lib/song_manager.lua
local YAMLParser = include('lib/yaml_parser')

local SongManager = {}
SongManager.__index = SongManager

function SongManager.new()
    return setmetatable({}, SongManager)
end

function SongManager:init(params, sequenceManager)
    self.params = params
    self.sequenceManager = sequenceManager
    self.yamlParser = YAMLParser.new()
    self.currentSong = nil
    self.PATTERNS_DIRECTORY = _path.dust .. "code/tens/songs/"
end

function SongManager:loadSong(filename)
    local full_path = self.PATTERNS_DIRECTORY .. filename
    local file, err = io.open(full_path, "r")

    if not file then
        print("Error: Could not open file. Error: " .. (err or "unknown error"))
        return false
    end

    local content = file:read("*a")
    file:close()
    
    local song = self.yamlParser:parse_song(content)
    if not song then
        print("Error: Failed to parse song")
        return false
    end

    self.currentSong = song
    self.currentSong.filename = filename

    self.params:set("clock_tempo", self.currentSong.bpm or 120)

    if #self.currentSong.patterns > 0 then
        self.sequenceManager:loadPattern(self.currentSong.patterns[1])
    end

    return true
end

function SongManager:saveSong()
    if not self.currentSong then
        print("Error: No song to save")
        return false
    end

    local filename = self.currentSong.filename
    local full_path = self.PATTERNS_DIRECTORY .. filename
    local file, err = io.open(full_path, "w")
    if file then
        file:write(self.yamlParser:serialize_song(self.currentSong))
        file:close()
        return true
    else
        print("Error: Could not open file. Error: " .. (err or "unknown error"))
        return false
    end
end

return SongManager