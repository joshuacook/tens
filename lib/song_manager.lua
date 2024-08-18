-- lib/song_manager.lua
local XMLParser = include('lib/xml_parser')

local SongManager = {}
SongManager.__index = SongManager

function SongManager.new()
    return setmetatable({}, SongManager)
end

function SongManager:init(params, sequenceManager)
    self.params = params
    self.sequenceManager = sequenceManager
    self.xmlParser = XMLParser.new()
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
    
    local song = self.xmlParser:parse_song(content)
    if not song then
        print("Error: Failed to parse song")
        return false
    end

    self.currentSong = song
    self.currentSong.filename = filename

    self.params:set("clock_tempo", self.currentSong.bpm or 120)

    if #self.currentSong.patterns > 0 then
        print("Loading first pattern:")
        print(#self.currentSong.patterns)
        first_pattern = self.currentSong.patterns[1]
        print(#first_pattern)
        print(#first_pattern["drum1a"])
        self.sequenceManager:loadPattern(first_pattern)
    else
        print("No patterns found in the song")
    end

    return true
end

function SongManager:loadPattern(patternIndex)
    if not self.currentSong or not self.currentSong.patterns[patternIndex] then
        print("Error: Invalid pattern index")
        return false
    end

    local pattern = self.currentSong.patterns[patternIndex]
    self.sequenceManager:loadPattern(pattern)
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
        file:write(self.xmlParser:serialize_song(self.currentSong))
        file:close()
        return true
    else
        print("Error: Could not open file. Error: " .. (err or "unknown error"))
        return false
    end
end

function SongManager:getCurrentPatternIndex()
    for i, pattern in ipairs(self.currentSong.patterns) do
        if pattern == self.sequenceManager.currentPattern then
            return i
        end
    end
    return nil
end

function SongManager:nextPattern()
    local currentIndex = self:getCurrentPatternIndex()
    if currentIndex and currentIndex < #self.currentSong.patterns then
        return self:loadPattern(currentIndex + 1)
    end
    return false
end

function SongManager:previousPattern()
    local currentIndex = self:getCurrentPatternIndex()
    if currentIndex and currentIndex > 1 then
        return self:loadPattern(currentIndex - 1)
    end
    return false
end

return SongManager