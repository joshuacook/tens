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
        local result = {}
        for drum = 1, 8 do
            local index = (drum - 1) * 16 + step
            result[drum] = self.currentPattern[index] or 0
        end
        return result
    end
    return {}
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
    if self.currentPattern then
        for drum = 1, 8 do
            local index = (drum - 1) * 16 + step
            local velocity = self.currentPattern[index]
            if velocity and velocity > 0 then
                self.midiController:sendNote(drumMachineIndex, drum, math.floor(velocity * 127))
            end
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