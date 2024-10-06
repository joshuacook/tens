-- lib/clock_manager.lua
local ClockManager = {}
ClockManager.__index = ClockManager

function ClockManager.new()
    return setmetatable({}, ClockManager)
end

function ClockManager:init(clock, params, displayManager)
    self.clock = clock
    self.params = params
    self.displayManager = displayManager
    self.listeners = {}
    self.currentMeasure = 1
    self.currentBeat = 1
    self.currentSixteenth = 1
    self.isPlaying = false

    self.clock.tempo_change_handler = function(bpm)
        self.displayManager:updateBPM(bpm)
    end

    self.clock.transport.start = function()
        self:start()
    end

    self.clock.transport.stop = function()
        self:stop()
    end

    self.displayManager:updateBPM(self.clock.get_tempo())

    self.clock.run(function() self:tickRoutine() end)
end

function ClockManager:addListener(listener)
    table.insert(self.listeners, listener)
end

function ClockManager:clockLoop()
    while self.isPlaying do
        self:tick()
        self.clock.sync(1/4)
    end
end

function ClockManager:getCurrentBPM()
    return self.params:get("clock_tempo")
end

function ClockManager:getCurrentPosition()
    return self.currentMeasure, self.currentBeat, self.currentSixteenth
end

function ClockManager:getTempo()
    return self.clock.get_tempo()
end

function ClockManager:notifyListeners(event, ...)
    for _, listener in ipairs(self.listeners) do
        if listener[event] then
            listener[event](...)
        end
    end
end

function ClockManager:onBPMChange(bpm)
    self:notifyListeners("bpm", bpm)
end

function ClockManager:removeListener(listener)
    for i, l in ipairs(self.listeners) do
        if l == listener then
            table.remove(self.listeners, i)
            break
        end
    end
end

function ClockManager:setSource(source)
    self.clock.set_source(source)
end

function ClockManager:setTempo(bpm)
    self.params:set("clock_tempo", bpm)
    self.clock.tempo = bpm
    self.displayManager:updateBPM(bpm)
end

function ClockManager:start()
    if not self.isPlaying then
        self.isPlaying = true
        self.displayManager:togglePlay()
        self:notifyListeners("start")
    end
end

function ClockManager:stop()
    if self.isPlaying then
        self.isPlaying = false
        self.displayManager:togglePlay()
        self.songManager:resetSongPosition() 
        self:notifyListeners("stop")
    end
end

function ClockManager:tick()
    self.currentSixteenth = self.currentSixteenth + 1
    if self.currentSixteenth > 4 then
        self.currentSixteenth = 1
        self.currentBeat = self.currentBeat + 1
        if self.currentBeat > 4 then
            self.currentBeat = 1
            self.currentMeasure = self.currentMeasure + 1
        end
    end
    self:notifyListeners("tick")
end

function ClockManager:tickRoutine()
    while true do
        self.clock.sync(1/4)
        if self.isPlaying then
            self:tick()
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