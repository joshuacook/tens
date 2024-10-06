-- lib/drum_pattern_manager.lua
local DrumPatternManager = {}
DrumPatternManager.__index = DrumPatternManager

function DrumPatternManager.new()
    return setmetatable({}, DrumPatternManager)
end

function DrumPatternManager:init(midiController)
    self.midiController = midiController
    self.currentPattern = nil
    self.patterns = {}
    self.currentPatternIndex = nil
end

function DrumPatternManager:loadPatterns(patterns)
    if patterns and #patterns > 0 then
        self.patterns = patterns
        self.currentPatternIndex = 1
        self.currentPattern = self.patterns[self.currentPatternIndex]
    else
        print("Warning: No patterns to load")
        self.patterns = {}
        self.currentPatternIndex = nil
        self.currentPattern = nil
    end
end

function DrumPatternManager:getCurrentPattern()
    return self.currentPattern
end

function DrumPatternManager:getPatternStep(step)
    if self.currentPattern then
        return self.currentPattern[step]
    end
    return 0
end

function DrumPatternManager:nextPattern()
    if #self.patterns > 0 then
        self.currentPatternIndex = (self.currentPatternIndex % #self.patterns) + 1
        self.currentPattern = self.patterns[self.currentPatternIndex]
    end
end

function DrumPatternManager:previousPattern()
    if #self.patterns > 0 then
        self.currentPatternIndex = ((self.currentPatternIndex - 2 + #self.patterns) % #self.patterns) + 1
        self.currentPattern = self.patterns[self.currentPatternIndex]
    end
end

function DrumPatternManager:playStep(step, drumMachineIndex)
    if self.currentPattern and self.currentPattern[step] then
        local velocity = self.currentPattern[step]
        if velocity > 0 then
            print("Playing step " .. step .. " with velocity " .. velocity .. " on drum machine " .. drumMachineIndex)
            self.midiController:sendNote(drumMachineIndex, 1, math.floor(velocity * 127/4))
        end
    end
end

function DrumPatternManager:setPatterns(patterns)
    self:loadPatterns(patterns)
end

function DrumPatternManager:loadPattern(patternIndex)
    if self.patterns and self.patterns[patternIndex] then
        self.currentPatternIndex = patternIndex
        self.currentPattern = self.patterns[patternIndex]
    else
        print("Warning: Invalid pattern index")
    end
end

return DrumPatternManager