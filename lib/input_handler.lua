-- lib/input_handler.lua
local InputHandler = {}
InputHandler.__index = InputHandler

function InputHandler.new()
    return setmetatable({}, InputHandler)
end

function InputHandler:init(params, clockManager, displayManager, sequenceManager)
    self.params = params
    self.clockManager = clockManager
    self.displayManager = displayManager
    self.sequenceManager = sequenceManager
    
    self.grid = grid.connect()
    self.grid.key = function(x, y, z)
        self:handleGridPress(x, y, z)
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
        self.displayManager:updateCurrentPage(self.sequenceManager:getCurrentPageName())
    end
end

function InputHandler:handleGridPress(x, y, z)
    if z == 1 then  -- button pressed
        local currentDevice = self.sequenceManager:getCurrentDevice()
        local currentPage = self.sequenceManager:getCurrentPage()
        local currentVolume = self.sequenceManager:getStep(currentDevice, currentPage, x, y)
        local newVolume = (currentVolume + 1) % 4  -- cycle through 0-3
        self.sequenceManager:setStep(currentDevice, currentPage, x, y, newVolume)
        
        -- Update grid LED
        self:updateGridLED(x, y, newVolume)
    end
end

function InputHandler:updateGridLED(x, y, volume)
    local brightness = volume * 4  -- Scale 0-3 to 0-12 (assume 16 brightness levels)
    self.grid:led(x, y, brightness)
    self.grid:refresh()
end

function InputHandler:redrawGrid()
    local currentDevice = self.sequenceManager:getCurrentDevice()
    local currentPage = self.sequenceManager:getCurrentPage()
    for x = 1, 16 do
        for y = 1, 8 do
            local volume = self.sequenceManager:getStep(currentDevice, currentPage, x, y)
            self:updateGridLED(x, y, volume)
        end
    end
end

return InputHandler