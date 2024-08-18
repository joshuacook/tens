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
    local result = {}
    for _, page in ipairs(self.pages) do
        local sequence = self.currentPattern[page]
        if sequence then
            result[page] = {}
            for i = 1, 8 do  -- 8 drums per sequence
                local index = (i - 1) * 16 + step
                result[page][i] = sequence.steps[index] or 0
            end
        end
    end
    return result
end

function SequenceManager:setStep(page, drum, step, value)
    local sequence = self.currentPattern[page]
    if sequence then
        local index = (drum - 1) * 16 + step
        sequence[index] = value
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