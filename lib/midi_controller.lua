-- lib/midi_controller.lua

MIDI_TARGET_NAMES = {"Midihub MH-13F7475 1"}

MC101_NOTE_MAP = {
    36, 38, 42, 46, 41, 45, 48, 49, 62, 63, 64, 37, 39, 51, 54, 56
}
T8_NOTE_MAP = {
    36, 38, 42, 46, 48, 50
}
RAZZ_NOTE_MAP = {
    36, 37, 38, 39, 40, 41, 42, 43
}
BB_NOTE_MAP = {
    36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51
}

local MIDIController = {}
MIDIController.__index = MIDIController

local MIDIDevice = {}
MIDIDevice.__index = MIDIDevice

local DrumMachine = {}
DrumMachine.__index = DrumMachine

function MIDIDevice.new(id, name)
    local self = setmetatable({}, MIDIDevice)
    self.id = id
    self.name = name
    self.connection = nil
    return self
end

function MIDIDevice:connect()
    self.connection = midi.connect(self.id)
    if self.connection then
        print("Connected to MIDI device " .. self.name)
    else
        print("Failed to connect to MIDI device " .. self.name)
    end
end

function MIDIDevice:sendAllNotesOff(channel)
    if self.connection then
        for note = 0, 127 do
            self.connection:note_off(note, 0, channel)
        end
    else
        print("Error: MIDI device not connected")
    end
end

function MIDIDevice:sendNote(note, velocity, channel)
    if self.connection then
        self.connection:note_on(note, velocity, channel)
        
        clock.run(function()
            clock.sleep(0.1)
            self.connection:note_off(note, 0, channel)
        end)
    else
        print("Error: MIDI device not connected")
    end
end

function DrumMachine.new(device, channel, noteMap)
    local self = setmetatable({}, DrumMachine)
    self.device = device
    self.channel = channel
    self.noteMap = noteMap
    return self
end

function DrumMachine:sendNote(sampleIndex, velocity)
    local note = self.noteMap[sampleIndex]
    if note then
        self.device:sendNote(note, velocity, self.channel)
    else
        print("Error: Invalid sample index for this drum machine")
    end
end

function MIDIController.new()
    local self = setmetatable({}, MIDIController)
    self.devices = {}
    self.drumMachines = {}
    return self
end

function MIDIController:init()
    
    for i = 1, #MIDI_TARGET_NAMES do
        local device = MIDIDevice.new(i, MIDI_TARGET_NAMES[i])
        device:connect()
        self.devices[i] = device
    end

    -- Create drum machines
    self.drumMachines[1] = DrumMachine.new(self.devices[1], 11, BB_NOTE_MAP)
    self.drumMachines[2] = DrumMachine.new(self.devices[1], 2, MC101_NOTE_MAP)
    self.drumMachines[3] = DrumMachine.new(self.devices[1], 10, RAZZ_NOTE_MAP)
    self.drumMachines[4] = DrumMachine.new(self.devices[1], 11, BB_NOTE_MAP)
end

function MIDIController:sendAllNotesOff(drumMachineIndex)
    local drumMachine = self.drumMachines[drumMachineIndex]
    if drumMachine then
        drumMachine.device:sendAllNotesOff(drumMachine.channel)
    else
        print("Error: Invalid drum machine index")
    end
end

function MIDIController:sendNote(drumMachineIndex, sampleIndex, velocity)
    local drumMachine = self.drumMachines[drumMachineIndex]
    if drumMachine then
        drumMachine:sendNote(sampleIndex, velocity)
    else
        print("Error: Invalid drum machine index")
    end
end

function MIDIController:updateTempo(bpm)
    -- TODO: Implement MIDI tempo update for each device
    for _, device in ipairs(self.devices) do
        -- Send MIDI clock or other tempo-related messages
    end
end

return MIDIController