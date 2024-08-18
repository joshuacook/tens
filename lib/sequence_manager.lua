-- lib/sequence_manager.lua
local SequenceManager = {}
SequenceManager.__index = SequenceManager

function SequenceManager.new()
    return setmetatable({}, SequenceManager)
end

function SequenceManager:init(midiController)
    self.midiController = midiController
    self.currentPattern = nil
    self.pages = {"drum1a", "drum1b", "drum2a", "drum2b", "drum3a", "drum3b"}
    self.currentPageIndex = 1
    self.sequencePage = self.pages[self.currentPageIndex]
end

function SequenceManager:loadPattern(pattern)
    self.currentPattern = pattern
    self.currentPageIndex = 1
    self.sequencePage = self.pages[self.currentPageIndex]
end

function SequenceManager:getCurrentSequence()
    return self.currentPattern[self.sequencePage]
end

function SequenceManager:getCurrentStep(step)
    local sequence = self:getCurrentSequence()
    if not sequence then return {} end
    
    local result = {}
    for i, row in ipairs(sequence) do
        result[i] = {
            value = row.steps[step],
            sample_name = row.sample_name,
            volume = row.volume
        }
    end
    return result
end

function SequenceManager:setStep(row, step, value)
    local sequence = self:getCurrentSequence()
    if sequence and sequence[row] then
        sequence[row].steps[step] = value
    end
end

function SequenceManager:nextPage()
    self.currentPageIndex = (self.currentPageIndex % #self.pages) + 1
    self.sequencePage = self.pages[self.currentPageIndex]
end

function SequenceManager:previousPage()
    self.currentPageIndex = ((self.currentPageIndex - 2 + #self.pages) % #self.pages) + 1
    self.sequencePage = self.pages[self.currentPageIndex]
end

return SequenceManager