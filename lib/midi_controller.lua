-- lib/midi_controller.lua
local MIDIController = {}
MIDIController.__index = MIDIController

function MIDIController.new()
    return setmetatable({}, MIDIController)
end

function MIDIController:init(midi)
    self.midi = midi
    self.devices = {}
    self.channels = {1, 2, 3}  -- Default MIDI channels for each drum device
    self.DRUM_NOTE_MAP = {
        -- Roland drum note mapping
        36, 38, 40, 41, 43, 45, 47, 48, 50, 52, 53, 55, 57, 59, 60, 62
    }
end

function MIDIController:connect()
    for i = 1, 3 do
        self.devices[i] = midi.connect(i)
        if self.devices[i] then
            if self.devices[i].name == "Midihub MH-13F7475 " .. i then  
                print("Connected to MIDI device " .. self.devices[i].name)
            else
                print("Error: Expected MIDI device 'Midihub MH-13F7475 " .. i .. "', but found '" .. self.devices[i].name .. "'")
                os.exit(1)
            end
        else
            print("Failed to connect to MIDI device " .. i)
        end
    end
end

function MIDIController:setChannel(deviceIndex, channel)
    if deviceIndex >= 1 and deviceIndex <= 3 then
        self.channels[deviceIndex] = channel
    else
        print("Invalid device index. Must be between 1 and 3.")
    end
end

function MIDIController:sendNote(deviceIndex, sampleIndex, velocity)
    if deviceIndex < 1 or deviceIndex > 3 then
        print("Invalid device index. Must be between 1 and 3.")
        return
    end

    if sampleIndex < 1 or sampleIndex > 16 then
        print("Invalid sample index. Must be between 1 and 16.")
        return
    end

    local device = self.devices[deviceIndex]
    if not device then
        print("MIDI device " .. deviceIndex .. " is not connected.")
        return
    end

    local channel = self.channels[deviceIndex]
    local note = self.DRUM_NOTE_MAP[sampleIndex]

    device:note_on(note, velocity, channel)

    -- Schedule note off
    clock.run(function()
        clock.sleep(0.1)  -- 100ms note duration
        device:note_off(note, 0, channel)
    end)
end

function MIDIController:sendAllNotesOff(deviceIndex)
    if deviceIndex < 1 or deviceIndex > 3 then
        print("Invalid device index. Must be between 1 and 3.")
        return
    end

    local device = self.devices[deviceIndex]
    if not device then
        print("MIDI device " .. deviceIndex .. " is not connected.")
        return
    end

    local channel = self.channels[deviceIndex]
    
    for _, note in ipairs(self.DRUM_NOTE_MAP) do
        device:note_off(note, 0, channel)
    end
end

function MIDIController:updateTempo(bpm)
    print("MIDI Tempo updated to " .. bpm)
end

return MIDIController