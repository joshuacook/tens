-- lib/input_handler.lua
local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler.new()
    return setmetatable({}, InputHandler)
end

local my_grid = grid.connect()

function InputHandler:init(params, clockManager, displayManager, sequenceManager, songManager, drumPatternManager)
    self.params = params
    self.clockManager = clockManager
    self.displayManager = displayManager
    self.sequenceManager = sequenceManager
    self.songManager = songManager
    self.drumPatternManager = drumPatternManager
    self.isShiftPressed = false

    self.currentBeat = 1
    self.currentSixteenthNote = 1
    self.copyToPatternIndex = 1

    if my_grid then
        my_grid.key = function(x, y, z)
            self:handleGridPress(x, y, z)
        end
        print("Grid initialized successfully")
    else
        print("Warning: Grid not provided or nil")
    end
end

function InputHandler:addNewScene()
    local newScene = self.songManager:addNewScene()
    if newScene then
        local newSceneIndex = #self.songManager.currentSong.scenes
        self.songManager:loadScene(newSceneIndex)
        self.displayManager:updateCurrentScene(newSceneIndex)
        self:redrawGrid()
        print("New scene added and loaded")
    else
        print("Failed to add new scene")
    end
end

function InputHandler:handleKey(n, z)
    if self.displayManager.confirmationModal.active then
        self:handleConfirmationModalKey(n, z)
    elseif self.displayManager.copyPatternModal then
        self:handleCopyPatternModalKey(n, z)
    else
        self:handleRegularKey(n, z)
    end
end

function InputHandler:handleConfirmationModalKey(n, z)
    if z == 1 then
        if n == 2 then
            local action = self.displayManager.confirmationModal.action
            self.displayManager:hideConfirmationModal()
            if action == "load" then
                self.songManager:loadSong(self.displayManager.currentFileName)
                self:redrawGrid()
            elseif action == "save" then
                self.songManager:saveSong(self.displayManager.currentFileName)
            end
        elseif n == 3 then
            self.displayManager:hideConfirmationModal()
        end
    end
end

function InputHandler:handleCopyPatternModalKey(n, z)
    if z == 1 then
        if n == 2 then
            -- Confirm copy
            self.drumPatternManager:copyPattern(self.displayManager.editingPatternIndex, self.displayManager.copyToPatternIndex)
            self.displayManager.copyPatternModal = false
            self.displayManager:redraw()
        elseif n == 3 then
            -- Cancel copy
            self.displayManager.copyPatternModal = false
            self.displayManager:redraw()
        end
    end
end

function InputHandler:handleRegularKey(n, z)
    if z == 1 then
        if n == 2 then
            if self.displayManager.pages[self.displayManager.currentPageIndex] == "load_save" then
                self.displayManager:showConfirmationModal("load", "Load " .. self.displayManager.currentFileName .. "?")
            elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "song" then
                self.songManager:moveSelectedPairIndex(-1)
                self.displayManager:redraw()
            elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "drummer" then
                self.displayManager.copyPatternModal = true
                self.displayManager.copyToPatternIndex = self.displayManager.editingPatternIndex
                self.displayManager:redraw()
            else
                self.clockManager:togglePlay()
            end
        elseif n == 3 then
            if self.displayManager.pages[self.displayManager.currentPageIndex] == "load_save" then
                self.displayManager:showConfirmationModal("save", "Save to " .. self.displayManager.currentFileName .. "?")
            elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "song" then
                self.songManager:moveSelectedPairIndex(1)
                self.displayManager:redraw()
            elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "sequence" then
                self:addNewScene()
            end
        end
    end
end

function InputHandler:handleEnc(n, d)
    if n == 1 then
        if d > 0 then
            self.displayManager:nextPage()
            self:redrawGrid()
        else
            self.displayManager:previousPage()
            self:redrawGrid()
        end
    elseif n == 2 then
        if self.displayManager.pages[self.displayManager.currentPageIndex] == "load_save" then
            self.displayManager:updateFileName(d)
        elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "song" then
            self.songManager:adjustSelectedPairScene(d)
            self.displayManager:redraw()
        elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "main" then
            local sceneCount = self.songManager.sceneCount
            if sceneCount > 0 then
                local currentScene = self.songManager:getCurrentSceneIndex()
                local newScene = (currentScene - 1 + d) % sceneCount + 1
                self.songManager:loadScene(newScene)
                self.displayManager:updateCurrentScene(newScene)
            end
        elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "sequence" then
            local sceneCount = self.songManager.sceneCount
            if sceneCount > 0 then
                local currentEditingScene = self.songManager:getEditingSceneIndex()
                local newEditingScene = (currentEditingScene - 1 + d) % sceneCount + 1
                self.songManager:setEditingSceneIndex(newEditingScene)
                self.displayManager:updateEditingScene(newEditingScene)
                self:redrawGrid()
            end
        elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "drummer" then
            if self.displayManager.copyPatternModal then
                self.displayManager.copyToPatternIndex = util.clamp(self.displayManager.copyToPatternIndex + d, 1, 8)
            else
                self.displayManager.editingPatternIndex = util.clamp(self.displayManager.editingPatternIndex + d, 1, 8)
                self.drumPatternManager:loadPattern(self.displayManager.editingPatternIndex)
            end
            self.displayManager:redraw()
            self:redrawGrid()
        end
    elseif n == 3 then
        if self.displayManager.pages[self.displayManager.currentPageIndex] == "main" then
            local newBPM = util.clamp(self.params:get("clock_tempo") + d, 20, 300)
            self.params:set("clock_tempo", newBPM)
            self.displayManager:updateBPM(newBPM)
        elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "song" then
            self.songManager:adjustSelectedPairDuration(d)
            self.displayManager:redraw()
        elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "sequence" then
            if d > 0 then
                self.sequenceManager:nextSequence()
            else
                self.sequenceManager:previousSequence()
            end
            self.displayManager:updateCurrentSequence(self.sequenceManager.currentSequence)
            self:redrawGrid()
        elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "drummer" then
            self.displayManager.playingPatternIndex = util.clamp(self.displayManager.playingPatternIndex + d, 1, 8)
            self.drumPatternManager:loadPattern(self.displayManager.playingPatternIndex)
            self.displayManager:redraw()
        end
    end
end

function InputHandler:handleGridPress(x, y, z)
    if z == 1 then
        if self.displayManager.pages[self.displayManager.currentPageIndex] == "drummer" then
            local index = (y - 1) * 16 + x
            local currentPattern = self.drumPatternManager:getCurrentPattern()
            if currentPattern then
                local currentValue = currentPattern[index] or 0
                local newValue = (currentValue + 1) % 4  -- cycle through 0-3
                self.drumPatternManager:setPatternStep(self.displayManager.editingPatternIndex, index, newValue)
                self:updateGridLED(x, y, newValue)
            end
        else
            local editingSceneIndex = self.songManager:getEditingSceneIndex()
            local editingScene = self.songManager.currentSong.scenes[editingSceneIndex]
            local currentSequenceIndex = self.displayManager.currentSequenceIndex
            local currentSequence = self.sequenceManager.sequences[currentSequenceIndex]
            local index = (y - 1) * 16 + x
            local currentValue = editingScene[currentSequence][index] or 0
            local newValue = (currentValue + 1) % 4  -- cycle through 0-3
            editingScene[currentSequence][index] = newValue

            self:updateGridLED(x, y, newValue)
            self.displayManager.dirty = true
        end
    end
end

function InputHandler:redrawGrid()
    if not my_grid then
        print("Grid not initialized")
        return
    end
    my_grid:all(0)
    
    if self.displayManager.pages[self.displayManager.currentPageIndex] == "main" then
        local gridColumn = ((self.currentBeat - 1) * 4 + self.currentSixteenthNote)
        for y = 1, 8 do
            my_grid:led(gridColumn, y, 15)  -- Full brightness
        end
    elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "drummer" then
        local currentPattern = self.drumPatternManager:getCurrentPattern()
        if currentPattern then
            for y = 1, 8 do
                for x = 1, 16 do
                    local index = (y - 1) * 16 + x
                    local value = currentPattern[index] or 0
                    my_grid:led(x, y, value * 5)  -- Scale 0-3 to 0-15
                end
            end
        end
    else
        local editingSceneIndex = self.songManager:getEditingSceneIndex()
        local editingScene = self.songManager.currentSong.scenes[editingSceneIndex]
        local currentSequence = self.displayManager.currentSequence
        local currentSequenceSteps = editingScene[currentSequence]
        
        for y = 1, 8 do
            for x = 1, 16 do
                local index = (y - 1) * 16 + x
                local value = currentSequenceSteps[index] or 0
                my_grid:led(x, y, value * 5)  -- Scale 0-3 to 0-12
            end
        end
    end
    
    my_grid:refresh()
end

function InputHandler:updateBeat(beat, sixteenthNote)
    self.currentBeat = beat
    self.currentSixteenthNote = sixteenthNote
    self:redrawGrid()
end

function InputHandler:updateGridLED(x, y, volume)
    local brightness = volume * 5  -- Scale 0-3 to 0-15
    my_grid:led(x, y, brightness)
    my_grid:refresh()
end

return InputHandler