-- lib/sequence_manager.lua
local SequenceManager = {}
SequenceManager.__index = SequenceManager

function SequenceManager.new()
    return setmetatable({}, SequenceManager)
end

function SequenceManager:init(midiController)
    self.midiController = midiController
    self.currentPattern = nil
    self.currentDrum = 1
    self.currentPage = "a"
end

function SequenceManager:loadPattern(pattern)
    self.currentPattern = pattern
    self.currentDrum = 1
    self.currentPage = "a"
end

function SequenceManager:getCurrentSubPattern()
    local key = string.format("drum%d%s", self.currentDrum, self.currentPage)
    return self.currentPattern[key]
end

function SequenceManager:getCurrentStep(step)
    local subPattern = self:getCurrentSubPattern()
    local result = {}
    for i, row in ipairs(subPattern) do
        result[i] = {
            value = row[step],
            sample_name = row.sample_name,
            volume = row.volume
        }
    end
    return result
end

function SequenceManager:setStep(row, step, value)
    local subPattern = self:getCurrentSubPattern()
    if subPattern[row] then
        subPattern[row][step] = value
    end
end

function SequenceManager:nextPage()
    if self.currentPage == "a" then
        self.currentPage = "b"
    else
        self.currentDrum = (self.currentDrum % 3) + 1
        self.currentPage = "a"
    end
end

function SequenceManager:previousPage()
    if self.currentPage == "b" then
        self.currentPage = "a"
    else
        self.currentDrum = ((self.currentDrum - 2 + 3) % 3) + 1
        self.currentPage = "b"
    end
end

function SequenceManager:getCurrentPageName()
    return string.format("Drum %d%s", self.currentDrum, self.currentPage)
end

return SequenceManager