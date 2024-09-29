-- lib/sequence_manager.lua
local SequenceManager = {}
SequenceManager.__index = SequenceManager

function SequenceManager.new()
    return setmetatable({}, SequenceManager)
end

function SequenceManager:init(midiController)
    self.midiController = midiController
    self.currentScene = nil
    self.sequences = nil
    self.currentSequenceIndex = nil
    self.currentSequence = nil
end

function SequenceManager:getCurrentSequenceSteps()
    return self.currentScene[self.currentSequence]
end

function SequenceManager:getCurrentStep(step)
    local result = {}
    for _, seq in ipairs(self.sequences) do
        local sequenceSteps = self.currentScene[seq]
        if sequenceSteps then
            result[seq] = {}
            for i = 1, 8 do  -- 8 drums per sequence
                local index = (i - 1) * 16 + step
                result[seq][i] = sequenceSteps[index] or 0
            end
        end
    end
    return result
end

function SequenceManager:getSequences()
    return self.sequences
end

function SequenceManager:getSequenceIndex(sequence)
    for i, seq in ipairs(self.sequences) do
        if seq == sequence then
            return i
        end
    end
    return nil
end

function SequenceManager:loadScene(scene)
    self.currentScene = scene
    self.currentSequenceIndex = 1
    self.currentSequence = self.sequences[self.currentSequenceIndex]
end

function SequenceManager:nextSequence()
    self.currentSequenceIndex = (self.currentSequenceIndex % #self.sequences) + 1
    self.currentSequence = self.sequences[self.currentSequenceIndex]
end

function SequenceManager:previousSequence()
    self.currentSequenceIndex = ((self.currentSequenceIndex - 2 + #self.sequences) % #self.sequences) + 1
    self.currentSequence = self.sequences[self.currentSequenceIndex]
end

function SequenceManager:setSequences(sequences)
    self.sequences = sequences
end

function SequenceManager:setStep(sequence, drum, step, value)
    local sequenceSteps = self.currentScene[sequence]
    if sequenceSteps then
        local index = (drum - 1) * 16 + step
        sequenceSteps[index] = value
    end
end

return SequenceManager