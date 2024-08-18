-- lib/display_manager.lua
local DisplayManager = {}
DisplayManager.__index = DisplayManager

function DisplayManager.new()
    return setmetatable({}, DisplayManager)
end

function DisplayManager:init(screen, params, sequenceManager, songManager)
    self.screen = screen
    self.sequenceManager = sequenceManager
    self.songManager = songManager
    self.currentSequence = self.sequenceManager.currentSequence
    self.params = params
    self.bpm = self.params:get("clock_tempo")
    self.measureCount = 1
    self.isMetadataPage = false
    self.dirty = true
end

function DisplayManager:updateMeasureCount(count)
    self.measureCount = count
    self:redraw()
end

function DisplayManager:updateBPM(bpm)
    self.bpm = self.params:get("clock_tempo")
    self:redraw()
end

function DisplayManager:updateCurrentSequence(sequence)
    self.currentSequence = sequence
    self.dirty = true
    self:redraw()
end

function DisplayManager:updateCurrentScene(scene)
    self.currentScene = scene
    self.dirty = true
    self:redraw()
end

function DisplayManager:showMetadataPage(show)
    self.isMetadataPage = show
    self:redraw()
end

function DisplayManager:redraw()
    if not self.dirty or norns.menu.status() then return end

    self.screen.clear()
    self.screen.font_face(1)
    self.screen.font_size(8)

    if self.isMetadataPage then
        self:drawMetadataPage()
    else
        self:drawMainPage()
    end
    self.screen.update()
    self.dirty = false
end

function DisplayManager:drawMainPage()
    self.screen.move(0, 10)
    self.screen.text("Measure: " .. self.measureCount)

    self.screen.move(0, 20)
    self.screen.text("BPM: " .. self.bpm)

    self.screen.move(0, 30)
    self.screen.text("Sequence: " .. self.currentSequence)

    local beatPosition = (self.measureCount - 1) % 4 + 1
    for i = 1, 4 do
        self.screen.circle(30 + i * 15, 45, 3)
        if i == beatPosition then
            self.screen.fill()
        else
            self.screen.stroke()
        end
    end

    local currentSceneIndex = self.songManager:getCurrentSceneIndex()
    self.screen.move(0, 40)
    self.screen.text("Scene: " .. (currentSceneIndex or "N/A"))
    self.screen.move(0, 60)
    self.screen.text("E2: scene // E3: sequence")
end

function DisplayManager:drawMetadataPage()
    self.screen.move(0, 10)
    self.screen.text("Metadata Page")
    
    if self.songManager.currentSong then
        self.screen.move(0, 30)
        self.screen.text("Song: " .. self.songManager.currentSong.title)
        self.screen.move(0, 40)
        self.screen.text("BPM: " .. self.songManager.currentSong.bpm)
        self.screen.move(0, 50)
        self.screen.text("Scenes: " .. #self.songManager.currentSong.scenes)
    else
        self.screen.move(0, 30)
        self.screen.text("No song loaded")
    end
end

return DisplayManager