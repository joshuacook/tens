-- lib/input_handler.lua
local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler.new()
    return setmetatable({}, InputHandler)
end

local my_grid = grid.connect()

function InputHandler:init(params, clockManager, displayManager, sequenceManager)
    self.params = params
    self.clockManager = clockManager
    self.displayManager = displayManager
    self.sequenceManager = sequenceManager

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
    if n == 3 and z == 1 then
        self.displayManager:showMetadataPage(not self.displayManager.isMetadataPage)
    elseif n == 2 and z == 1 then
        self.clockManager:togglePlay()
    end
end

function InputHandler:handleEnc(n, d)
    if n == 1 then
        self.params:delta("clock_tempo", d)
    elseif n == 2 then
        self.params:delta("current_pattern", d)
    elseif n == 3 then
        if d > 0 then
            self.sequenceManager:nextPage()
        else
            self.sequenceManager:previousPage()
        end
        self.displayManager:updateSequencePage(self.sequenceManager.sequencePage)
        self:redrawGrid()
    end
end

function InputHandler:handleGridPress(x, y, z)
    if z == 1 then  -- button pressed
        local currentSequence = self.sequenceManager:getCurrentSequence()
        local index = (y - 1) * 16 + x
        local currentValue = currentSequence[y].steps[x] or 0
        local newValue = (currentValue + 1) % 4  -- cycle through 0-3
        self.sequenceManager:setStep(y, x, newValue)

        self:updateGridLED(x, y, newValue)
    end
end

function InputHandler:updateGridLED(x, y, volume)
    local brightness = volume * 4  -- Scale 0-3 to 0-12 (assume 16 brightness levels)
    my_grid:led(x, y, brightness)
    my_grid:refresh()
end

function InputHandler:redrawGrid()
    print("Redrawing grid")
    if not my_grid then
        print("Grid not initialized")
        return
    end
    my_grid:all(0)  -- Clear the grid
    
    local currentSequence = self.sequenceManager:getCurrentSequence()
    local currentSequenceSteps = currentSequence.steps
    for row = 1, 8 do
        for step = 1, 16 do
            local index = (row - 1) * 16 + step
            local value = currentSequenceSteps[index] or 0
            my_grid:led(step, row, value * 5)
        end
    end
    
    my_grid:refresh()
end

return InputHandler