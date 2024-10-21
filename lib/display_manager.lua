-- lib/display_manager.lua
local DisplayManager = {}
DisplayManager.__index = DisplayManager

function DisplayManager.new()
    return setmetatable({}, DisplayManager)
end

function DisplayManager:init(SONG_FILE_PATH, screen, params, sequenceManager, songManager, drumPatternManager)
    self.screen = screen
    self.sequenceManager = sequenceManager
    self.songManager = songManager
    self.drumPatternManager = drumPatternManager
    self.currentSequenceIndex = 1
    self.currentSequence = self.sequenceManager.sequences[self.currentSequenceIndex]
    self.params = params
    self.bpm = self.params:get("clock_tempo")
    self.measureCount = 1
    self.isPlaying = false

    self.pages = {"main", "song", "sequence","load_save", "drummer", "transitions"}
    self.currentPageIndex = 1

    self.currentFileName = SONG_FILE_PATH
    self.confirmationModal = {active = false, action = nil, message = ""}
    self.editingScene = 1
    self.editingSequence = nil
    self.editingPatternIndex = 1
    self.playingPatternIndex = 1
    self.currentTransitionIndex = 1
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

function DisplayManager:drawCopyPatternModal()
    self.screen.level(15)
    self.screen.rect(10, 20, 108, 30)
    self.screen.fill()
    
    self.screen.level(0)
    self.screen.move(15, 35)
    self.screen.text("Copy pattern " .. self.editingPatternIndex .. " to " .. self.copyToPatternIndex)
    
    self.screen.move(15, 45)
    self.screen.text("K2: Confirm  K3: Cancel")
end

function DisplayManager:drawDrummerPage()
    self.screen.level(15)
    self.screen.move(0, 10)
    self.screen.text("Drummer Page")
    
    self.screen.move(0, 30)
    self.screen.text("Editing: " .. self.editingPatternIndex .. " Playing: " .. self.playingPatternIndex)
        
    self.screen.move(0, 40)
    self.screen.text("E2: Edit // E3: Play")
    
    self.screen.move(0, 50)
    self.screen.text("K2: Copy Pattern")
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

function DisplayManager:drawMainPage()
    self.screen.level(15)
    self.screen.move(0, 10)
    self.screen.text("Playing: " .. (self.isPlaying and "Yes" or "No"))

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
    self.screen.text("Playing Scene: " .. (self.songManager:getCurrentSceneIndex() or "N/A"))

    self.screen.move(0, 40)
    self.screen.text("Measures/Seq: " .. (self.sequenceManager.measuresPerSequence or 1))


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
    
    self.screen.move(0, 20)
    local editingSceneIndex = self.songManager:getEditingSceneIndex()
    self.screen.text("Editing Scene: " .. editingSceneIndex)
    
    self.screen.move(0, 30)
    local currentSequence = self.sequenceManager.sequences[self.currentSequenceIndex]
    self.screen.text("Sequence: " .. (currentSequence or "None"))
    
    self.screen.move(0, 40)
    self.screen.text("K3: Add New Scene")
    
    self.screen.move(0, 50)
    self.screen.text("E2: scene // E3: sequence")
end

function DisplayManager:drawSongPage()
    self.screen.level(15)
    self.screen.move(0, 10)
    self.screen.text("Song Page")

    local songPosition = self.songManager.songPosition or 0
    self.screen.move(0, 40)
    self.screen.text("Position: " .. songPosition)

    local currentSceneIndex = self.songManager:getCurrentSceneIndex()
    self.screen.move(0, 20)
    self.screen.text("Current Scene: " .. (currentSceneIndex or "N/A"))

    local playCount = self.songManager.scenePlayCounter or 0
    self.screen.move(0, 30)
    self.screen.text("Play Count: " .. playCount + 1)

    self.screen.update()
end

function DisplayManager:drawTransitionsPage()
    self.screen.level(15)
    self.screen.move(0, 10)
    self.screen.text("Transitions Page")
    
    self.screen.move(0, 30)
    self.screen.text("Editing Transition: " .. self.currentTransitionIndex)
    
    self.screen.move(0, 40)
    self.screen.text("E2: Change Transition")
    
    self.screen.move(0, 50)
    self.screen.text("K2: Save Transitions")
end

function DisplayManager:hideConfirmationModal()
    self.confirmationModal.active = false
    self:redraw()
end

function DisplayManager:nextPage()
    self.currentPageIndex = (self.currentPageIndex % #self.pages) + 1
    self:redraw()
end

function DisplayManager:previousPage()
    self.currentPageIndex = ((self.currentPageIndex - 2) % #self.pages) + 1
    self:redraw()
end

function DisplayManager:showConfirmationModal(action, message)
    self.confirmationModal.active = true
    self.confirmationModal.action = action
    self.confirmationModal.message = message
    self:redraw()
end

function DisplayManager:redraw()
    self.screen.clear()
    self.screen.font_face(1)
    self.screen.font_size(8)

    local currentPage = self.pages[self.currentPageIndex]
    if currentPage == "main" then
        self:drawMainPage()
    elseif currentPage == "drummer" then
        self:drawDrummerPage()
    elseif currentPage == "metadata" then
        self:drawMetadataPage()
    elseif currentPage == "sequence" then
        self:drawSequencePage()
    elseif currentPage == "song" then
        self:drawSongPage()
    elseif currentPage == "load_save" then
        self:drawLoadSavePage()
    elseif currentPage == "transitions" then
        self:drawTransitionsPage()
    end

    if self.confirmationModal.active then
        self:drawConfirmationModal()
    elseif self.copyPatternModal then
        self:drawCopyPatternModal()
    end

    self.screen.move(0, 60)
    self.screen.text("Page: " .. currentPage .. " (" .. self.currentPageIndex .. "/" .. #self.pages .. ")")
    
    self.screen.update()
end

function DisplayManager:togglePlay()
    self.isPlaying = not self.isPlaying
    self:redraw()
end

function DisplayManager:updateBPM(bpm)
    self.bpm = self.params:get("clock_tempo")
    self:redraw()
end

function DisplayManager:updateCurrentSequence(sequence)
    self.currentSequence = sequence or "None"
    self.currentSequenceIndex = self.sequenceManager:getSequenceIndex(sequence)
    self:redraw()
end

function DisplayManager:updateCurrentSequenceIndex(index)
    self.currentSequenceIndex = index
    self.currentSequence = self.sequenceManager.sequences[self.currentSequenceIndex]
    self:redraw()
end

function DisplayManager:updateCurrentScene(scene)
    self.currentScene = scene
    self:redraw()
end

function DisplayManager:updateEditingScene(scene)
    self:redraw()
    self:updateCurrentSequenceIndex(self.currentSequenceIndex)
end

function DisplayManager:updateEditingSequence(sequence)
    self.editingSequence = sequence
    self:redraw()
end

function DisplayManager:updateFileName(delta)
    local num = tonumber(self.currentFileName:match("(%d+)"))
    num = (num + delta - 1) % 999 + 1
    self.currentFileName = string.format("%03d.xml", num)
    self:redraw()
end

function DisplayManager:updateMeasureCount(count)
    self.measureCount = count
end

return DisplayManager