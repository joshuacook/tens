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
    self.currentPatternIndex = 1
    
    -- Initialize 8 empty patterns
    for i = 1, 8 do
        self.patterns[i] = {}
        for j = 1, 128 do
            self.patterns[i][j] = 0
        end
    end
end

function DrumPatternManager:loadPatterns(patterns)
    if patterns and #patterns > 0 then
        self.patterns = patterns
        self.currentPatternIndex = 1
        self.currentPattern = self.patterns[self.currentPatternIndex]
    else
        print("Warning: No patterns to load")
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

function DrumPatternManager:setPatternStep(patternIndex, step, value)
    if self.patterns[patternIndex] then
        self.patterns[patternIndex][step] = value
        if patternIndex == self.currentPatternIndex then
            self.currentPattern = self.patterns[patternIndex]
        end
    else
        print("Warning: Invalid pattern index")
    end
end

function DrumPatternManager:nextPattern()
    self.currentPatternIndex = (self.currentPatternIndex % #self.patterns) + 1
    self.currentPattern = self.patterns[self.currentPatternIndex]
end

function DrumPatternManager:previousPattern()
    self.currentPatternIndex = ((self.currentPatternIndex - 2) % #self.patterns) + 1
    self.currentPattern = self.patterns[self.currentPatternIndex]
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
    if self.patterns[patternIndex] then
        self.currentPatternIndex = patternIndex
        self.currentPattern = self.patterns[patternIndex]
    else
        print("Warning: Invalid pattern index")
    end
end

function DrumPatternManager:copyPattern(sourceIndex, destIndex)
    if self.patterns[sourceIndex] and self.patterns[destIndex] then
        for i = 1, 128 do
            self.patterns[destIndex][i] = self.patterns[sourceIndex][i]
        end
        print("Pattern copied from " .. sourceIndex .. " to " .. destIndex)
    else
        print("Warning: Invalid source or destination pattern index")
    end
end

return DrumPatternManager