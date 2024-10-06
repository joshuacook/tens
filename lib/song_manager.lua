-- lib/song_manager.lua
local XMLParser = include('lib/xml_parser')

local SongManager = {}
SongManager.__index = SongManager

function SongManager.new()
    return setmetatable({}, SongManager)
end

function SongManager:init(params, sequenceManager, song_file)
    self.params = params
    self.sequenceManager = sequenceManager
    self.xmlParser = XMLParser.new()
    self.currentSong = nil
    self.SONGS_DIRECTORY = _path.dust .. "code/tens/songs/"
    self.sceneCount = 0
    self.editingSceneIndex = 1
    self.songPosition = 1
    self.scenePlayCounter = 0
    self.selectedPairIndex = 1

    self:loadSong(song_file)
end

function SongManager:addNewScene()
    if not self.currentSong then
        print("Error: No song loaded")
        return nil
    end

    local newScene = {}
    for _, part in ipairs(self.currentSong.drum_parts) do
        newScene[part] = {}
        for i = 1, 128 do
            newScene[part][i] = 0
        end
    end

    table.insert(self.currentSong.scenes, newScene)
    self.sceneCount = #self.currentSong.scenes

    self.sequenceManager:loadScene(newScene)

    return newScene
end

function SongManager:getCurrentSceneIndex()
    if not self.currentSong then
        return nil
    end
    for i, scene in ipairs(self.currentSong.scenes) do
        if scene == self.sequenceManager.currentScene then
            return i
        end
    end
    return nil
end

function SongManager:getEditingSceneIndex()
    return self.editingSceneIndex
end

function SongManager:loadScene(sceneIndex)
    if not self.currentSong or not self.currentSong.scenes[sceneIndex] then
        print("Error: Invalid scene index")
        return false
    end

    local scene = self.currentSong.scenes[sceneIndex]
    self.sequenceManager:loadScene(scene)
    return true
end

function SongManager:loadSong(filename)
    print("Loading song: " .. filename)
    local full_path = self.SONGS_DIRECTORY .. filename
    local file, err = io.open(full_path, "r")

    print("Full path: " .. full_path)
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
    self.sceneCount = #self.currentSong.scenes

    self.params:set("clock_tempo", self.currentSong.bpm or 120)
    self.sequenceManager:setSequences(self.currentSong.drum_parts)

    if self.sceneCount > 0 then
        print("Loading first scene:")
        print("Number of scenes: " .. self.sceneCount)
        local first_scene = self.currentSong.scenes[1]
        self.sequenceManager:loadScene(first_scene)
        self.editingSceneIndex = 1 
    else
        print("No scenes found in the song")
    end

    self.songPosition = 1
    self.scenePlayCounter = 0
    self.selectedPairIndex = 1

    if #self.currentSong.song_structure > 0 then
        local pair = self.currentSong.song_structure[1]
        self:loadScene(pair.scene)
    end

    return true
end

function SongManager:nextScene()
    local currentIndex = self:getCurrentSceneIndex()
    if currentIndex and currentIndex < #self.currentSong.scenes then
        return self:loadScene(currentIndex + 1)
    end
    return false
end

function SongManager:previousScene()
    local currentIndex = self:getCurrentSceneIndex()
    if currentIndex and currentIndex > 1 then
        return self:loadScene(currentIndex - 1)
    end
    return false
end

function SongManager:saveSong(filename)
    if not self.currentSong then
        print("Error: No song to save")
        return false
    end

    if not self.currentSong.drum_parts then
        self.currentSong.drum_parts = self.sequenceManager:getSequences()
    end

    local full_path = self.SONGS_DIRECTORY .. filename
    local file, err = io.open(full_path, "w")
    if file then
        file:write(self.xmlParser:serialize_song(self.currentSong))
        file:close()
        print("Song saved successfully as " .. filename)
        return true
    else
        print("Error: Could not open file. Error: " .. (err or "unknown error"))
        return false
    end
end

function SongManager:setEditingSceneIndex(index)
    if self.currentSong and self.currentSong.scenes[index] then
        self.editingSceneIndex = index
        return true
    end
    return false
end

function SongManager:getCurrentSceneDuration()
    local pair = self.currentSong.song_structure[self.songPosition]
    return pair.duration
end

function SongManager:getCurrentSceneIndex()
    local pair = self.currentSong.song_structure[self.songPosition]
    return pair.scene
end

function SongManager:advanceSongPosition()
    self.songPosition = self.songPosition + 1
    if self.songPosition > #self.currentSong.song_structure then
        self.songPosition = 1
    end
    self.scenePlayCounter = 0
    local pair = self.currentSong.song_structure[self.songPosition]
    self:loadScene(pair.scene)
end

function SongManager:moveSelectedPairIndex(delta)
    self.selectedPairIndex = util.clamp(self.selectedPairIndex + delta, 1, #self.currentSong.song_structure)
end

function SongManager:adjustSelectedPairScene(delta)
    local pair = self.currentSong.song_structure[self.selectedPairIndex]
    if pair then
        pair.scene = util.clamp(pair.scene + delta, 1, self.sceneCount)
    end
end

function SongManager:adjustSelectedPairDuration(delta)
    local pair = self.currentSong.song_structure[self.selectedPairIndex]
    if pair then
        pair.duration = math.max(1, pair.duration + delta)
    end
end

function SongManager:resetSongPosition()
    self.currentSongPosition = 1
    self.scenePlayCounter = 0
    self:loadScene(self.currentSong.song_structure[1].scene)
end

return SongManager