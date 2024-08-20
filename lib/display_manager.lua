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
    self.dirty = true
    self.isPlaying = false

    self.pages = {"main", "metadata", "sequence", "load_save"}
    self.currentPageIndex = 1

    self.currentFileName = "001.xml"
    self.confirmationModal = {active = false, action = nil, message = ""}
end

function DisplayManager:nextPage()
    self.currentPageIndex = (self.currentPageIndex % #self.pages) + 1
    self.dirty = true
    self:redraw()
end

function DisplayManager:previousPage()
    self.currentPageIndex = ((self.currentPageIndex - 2) % #self.pages) + 1
    self.dirty = true
    self:redraw()
end

function DisplayManager:updateMeasureCount(count)
    self.dirty = true
    self.measureCount = count
    self:redraw()
end

function DisplayManager:updateBPM(bpm)
    self.bpm = self.params:get("clock_tempo")
    self:redraw()
end

function DisplayManager:updateCurrentSequence(sequence)
    self.currentSequence = sequence or "None"
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

function DisplayManager:togglePlay()
    self.isPlaying = not self.isPlaying
    self.dirty = true
    self:redraw()
end

function DisplayManager:redraw()
    if not self.dirty or norns.menu.status() then return end

    self.screen.clear()
    self.screen.font_face(1)
    self.screen.font_size(8)

    local currentPage = self.pages[self.currentPageIndex]
    if currentPage == "main" then
        self:drawMainPage()
    elseif currentPage == "metadata" then
        self:drawMetadataPage()
    elseif currentPage == "sequence" then
        self:drawSequencePage()
    elseif currentPage == "load_save" then
        self:drawLoadSavePage()
    end

    if self.confirmationModal.active then
        self:drawConfirmationModal()
    end

    self.screen.move(0, 60)
    self.screen.text("Page: " .. currentPage .. " (" .. self.currentPageIndex .. "/" .. #self.pages .. ")")
    
    self.screen.update()
    self.dirty = false
end

function DisplayManager:drawLoadSavePage()
    self.screen.level(15)
    self.screen.move(0, 10)
    self.screen.text("Load/Save Page")
    
    self.screen.move(0, 30)
    self.screen.text("File: " .. self.currentFileName)
    
    self.screen.move(0, 40)
    self.screen.text("K2: Load  K3: Save")
    
    self.screen.move(0, 50)
    self.screen.text("E2: Change filename")
end

function DisplayManager:drawConfirmationModal()
    self.screen.level(15)
    self.screen.rect(10, 20, 108, 30)
    self.screen.fill()
    
    self.screen.level(0)
    self.screen.move(15, 35)
    self.screen.text(self.confirmationModal.message)
    
    self.screen.move(15, 45)
    self.screen.text("K2: Confirm  K3: Cancel")
end

function DisplayManager:hideConfirmationModal()
    self.confirmationModal.active = false
    self.dirty = true
    self:redraw()
end

function DisplayManager:markDirty()
    self.dirty = true
end

function DisplayManager:updateFileName(delta)
    local num = tonumber(self.currentFileName:match("(%d+)"))
    num = (num + delta - 1) % 999 + 1
    self.currentFileName = string.format("%03d.xml", num)
    self.dirty = true
    self:redraw()
end

function DisplayManager:showConfirmationModal(action, message)
    self.confirmationModal.active = true
    self.confirmationModal.action = action
    self.confirmationModal.message = message
    self.dirty = true
    self:redraw()
end

function DisplayManager:drawMainPage()
    self.screen.level(15)
    self.screen.move(0, 10)
    self.screen.text("Measure: " .. self.measureCount)
    self.screen.text(" Playing: " .. (self.isPlaying and "Yes" or "No"))

    self.screen.circle(60, 10, 5)
    if self.isPlaying then
        self.screen.circle(60, 10, 4)
        self.screen.circle(60, 10, 3)
        self.screen.circle(60, 10, 2)
        self.screen.circle(60, 10, 1)
    end

    self.screen.move(0, 20)
    self.screen.text("BPM: " .. self.bpm)

    local currentSceneIndex = self.songManager:getCurrentSceneIndex()
    self.screen.move(0, 30)
    self.screen.text("Scene: " .. (currentSceneIndex or "N/A"))

    self.screen.move(0, 40)
    self.screen.text("Sequence: " .. (self.currentSequence or "None"))

    self.screen.move(0, 50)
    self.screen.text("E2: scene // E3: BPM")
end

function DisplayManager:drawMetadataPage()
    self.screen.level(15)
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

function DisplayManager:drawSequencePage()
    self.screen.level(15)
    self.screen.move(0, 10)
    self.screen.text("Sequence Page")
    
    local currentSceneIndex = self.songManager:getCurrentSceneIndex()
    self.screen.move(0, 20)
    self.screen.text("Scene: " .. (currentSceneIndex or "N/A"))
    
    self.screen.move(0, 30)
    self.screen.text("Current Sequence: " .. (self.currentSequence or "None"))
    
    self.screen.move(0, 50)
    self.screen.text("E2: scene // E3: sequence")
end

return DisplayManager