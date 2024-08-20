-- lib/input_handler.lua
local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler.new()
    return setmetatable({}, InputHandler)
end

local my_grid = grid.connect()

function InputHandler:init(params, clockManager, displayManager, sequenceManager, songManager)
    self.params = params
    self.clockManager = clockManager
    self.displayManager = displayManager
    self.sequenceManager = sequenceManager
    self.songManager = songManager

    if my_grid then
        my_grid.key = function(x, y, z)
            self:handleGridPress(x, y, z)
        end
        print("Grid initialized successfully")
    else
        print("Warning: Grid not provided or nil")
    end
end

function InputHandler:handleKey(n, z)
    if self.displayManager.confirmationModal.active then
        self:handleConfirmationModalKey(n, z)
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

function InputHandler:handleRegularKey(n, z)
    if z == 1 then
        if n==1 then 
            self.displayManager:markDirty()
        elseif n == 2 then
            if self.displayManager.pages[self.displayManager.currentPageIndex] == "load_save" then
                self.displayManager:showConfirmationModal("load", "Load " .. self.displayManager.currentFileName .. "?")
            else
                self.clockManager:togglePlay()
            end
        elseif n == 3 then
            if self.displayManager.pages[self.displayManager.currentPageIndex] == "load_save" then
                self.displayManager:showConfirmationModal("save", "Save to " .. self.displayManager.currentFileName .. "?")
            end
        end
    end
end

function InputHandler:handleEnc(n, d)
    if n == 1 then
        if d > 0 then
            self.displayManager:nextPage()
        else
            self.displayManager:previousPage()
        end
    elseif n == 2 then
        if self.displayManager.pages[self.displayManager.currentPageIndex] == "load_save" then
            self.displayManager:updateFileName(d)
        else
            local sceneCount = self.songManager.sceneCount
            if sceneCount > 0 then
                local currentScene = self.songManager:getCurrentSceneIndex()
                local newScene = (currentScene - 1 + d) % sceneCount + 1
                self.songManager:loadScene(newScene)
                self.displayManager:updateCurrentScene(newScene)
                self:redrawGrid()
            end
        end
    elseif n == 3 then
        if self.displayManager.pages[self.displayManager.currentPageIndex] == "main" then
            local newBPM = util.clamp(self.params:get("clock_tempo") + d, 20, 300)
            self.params:set("clock_tempo", newBPM)
            self.displayManager:markDirty()
            self.displayManager:redraw()
        elseif self.displayManager.pages[self.displayManager.currentPageIndex] == "sequence" then
            if d > 0 then
                self.sequenceManager:nextSequence()
            else
                self.sequenceManager:previousSequence()
            end
            self.displayManager:updateCurrentSequence(self.sequenceManager.currentSequence)
            self:redrawGrid()
        end
    end
end

function InputHandler:handleGridPress(x, y, z)
    if z == 1 then
        local currentSequence = self.sequenceManager.currentSequence
        local currentSequenceSteps = self.sequenceManager:getCurrentSequenceSteps()
        local index = (y - 1) * 16 + x
        local currentValue = currentSequenceSteps[index] or 0
        local newValue = (currentValue + 1) % 4  -- cycle through 0-3
        self.sequenceManager:setStep(currentSequence, y, x, newValue)

        self:updateGridLED(x, y, newValue)
        self.displayManager.dirty = true
    end
end

function InputHandler:updateGridLED(x, y, volume)
    local brightness = volume * 4  -- Scale 0-3 to 0-15
    my_grid:led(x, y, brightness)
    my_grid:refresh()
end

function InputHandler:redrawGrid()
    if not my_grid then
        print("Grid not initialized")
        return
    end
    my_grid:all(0)
    
    local currentSequence = self.sequenceManager.currentSequence
    local currentSequenceSteps = self.sequenceManager:getCurrentSequenceSteps()
    for y = 1, 8 do
        for x = 1, 16 do
            local index = (y - 1) * 16 + x
            local value = currentSequenceSteps[index] or 0
            my_grid:led(x, y, value * 4)  -- Scale 0-3 to 0-12
        end
    end
    
    my_grid:refresh()
end

return InputHandler