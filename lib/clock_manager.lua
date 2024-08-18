-- lib/clock_manager.lua
local ClockManager = {}
ClockManager.__index = ClockManager

function ClockManager.new()
    return setmetatable({}, ClockManager)
end

function ClockManager:init(clock, params)
    self.clock = clock
    self.params = params
    self.currentMeasure = 1
    self.currentBeat = 1
    self.currentStep = 1
    self.isPlaying = false
    self.clockId = nil
    self.listeners = {}
    self.bpm = params:get("clock_tempo")

    params:set_action("clock_tempo", function(bpm)
        self.bpm = bpm
        self:onBPMChange(bpm)
    end)
end

function ClockManager:start()
    if not self.isPlaying then
        self.isPlaying = true
        self.clockId = self.clock.run(function() self:clockLoop() end)
    end
end

function ClockManager:stop()
    if self.isPlaying then
        self.isPlaying = false
        self.clock.cancel(self.clockId)
        self.currentMeasure = 1
        self.currentBeat = 1
        self.currentStep = 1
        self:notifyListeners("stop")
    end
end

function ClockManager:clockLoop()
    while self.isPlaying do
        self:tick()
        self.clock.sync(1/4)
    end
end

function ClockManager:tick()
    self:notifyListeners("tick")
    
    self.currentStep = self.currentStep + 1
    if self.currentStep > 4 then
        self.currentStep = 1
        self.currentBeat = self.currentBeat + 1
        if self.currentBeat > 4 then
            self.currentBeat = 1
            self.currentMeasure = self.currentMeasure + 1
            self:notifyListeners("measure")
        end
        self:notifyListeners("beat")
    end
end

function ClockManager:onBPMChange(bpm)
    self:notifyListeners("bpm", bpm)
end

function ClockManager:getCurrentPosition()
    return self.currentMeasure, self.currentBeat, self.currentStep
end

function ClockManager:getCurrentBPM()
    return self.params:get("clock_tempo")
end

function ClockManager:addListener(listener)
    table.insert(self.listeners, listener)
end

function ClockManager:removeListener(listener)
    for i, l in ipairs(self.listeners) do
        if l == listener then
            table.remove(self.listeners, i)
            break
        end
    end
end

function ClockManager:notifyListeners(event, data)
    for _, listener in ipairs(self.listeners) do
        if listener[event] then
            listener[event](data)
        end
    end
end

function ClockManager:togglePlay()
    if self.isPlaying then
        self:stop()
    else
        self:start()
    end
end

return ClockManager