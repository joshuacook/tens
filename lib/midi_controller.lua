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
        -- Roland 808 drum note mapping
        -- //------------- 1a ----------//
        -- | Note | Sound | Pad | Level |
        -- |------|-------|-----|-------|
        -- | 36   | Kick  |  9  |   69  |
        -- | 38   | Snare | 10  |  127  |
        -- | 42   | Cl HH |  3  |  127  |
        -- | 46   | Op HH |  4  |  127  |
        -- | 41   | LTom  | 11  |   48  |
        -- | 45   | MTom  | 12  |   48  |
        -- | 48   | HTom  | 13  |   48  |
        -- | 49   | Cymbl |  5  |  127  |
        -- //------------- 1b ----------//
        -- | Note | Sound | Pad | Level |
        -- |------|-------|-----|-------|
        -- | 62   | HCong | 14  |   60  |
        -- | 63   | MCong | 15  |   87  |
        -- | 64   | LCong | 16  |   64  |
        -- | 37   | Rim   |  1  |   77  |
        -- | 39   | Clap  |  2  |   97  |
        -- | 51   | Clave |  6  |  127  |
        -- | 54   | Mrcas |  7  |  117  |
        -- | 56   | Cbell |  8  |  127  |
        -- //---------------------------//
        36, 38, 42, 46, 41, 45, 48, 49, 62, 63, 64, 37, 39, 51, 54, 56
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
    self.channels[deviceIndex] = channel
end

function MIDIController:sendNote(deviceIndex, sampleIndex, velocity)
    local channel = self.channels[deviceIndex]
    local note = self.DRUM_NOTE_MAP[sampleIndex]

    self.devices[deviceIndex]:note_on(note, velocity, channel)

    clock.run(function()
        clock.sleep(0.1)
        self.devices[deviceIndex]:note_off(note, 0, channel)
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
    -- TODO: Implement MIDI tempo update
end

return MIDIController