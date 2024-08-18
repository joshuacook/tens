-- main.lua
local ClockManager = include('lib/clock_manager')
local DisplayManager = include('lib/display_manager')
local InputHandler = include('lib/input_handler')
local MIDIController = include('lib/midi_controller')
local SequenceManager = include('lib/sequence_manager')
local SongManager = include('lib/song_manager')

function init()
    clockManager = ClockManager.new()
    clockManager:init(clock, params)

    displayManager = DisplayManager.new()
    displayManager:init(screen)
    
    midiController = MIDIController.new()
    midiController:init(midi)
    midiController:connect()
    
    sequenceManager = SequenceManager.new()
    sequenceManager:init(midiController)
    
    songManager = SongManager.new()
    songManager:init(params, sequenceManager)
    
    inputHandler = InputHandler.new()
    inputHandler:init(params, clockManager, displayManager, sequenceManager, grid)

    songManager:loadSong("default_song.yaml")

    redraw_metro = metro.init()
    redraw_metro.time = 1/15
    redraw_metro.event = function()
        if displayManager then displayManager:redraw() end
    end
    redraw_metro:start()
    
    clockManager:addListener({
        tick = function()
            local measure, beat = clockManager:getCurrentPosition()
            displayManager:updateMeasureCount(measure)
            
            -- Update sequence based on current beat
            local currentStep = (beat - 1) % 16 + 1
            local stepData = sequenceManager:getCurrentStep(currentStep)
            
            -- Trigger MIDI notes based on stepData
            for i, data in ipairs(stepData) do
                if data.value > 0 then
                    local midiNote = midiController:getMIDINoteForSample(data.sample_name)
                    local velocity = math.floor(data.value * data.volume * 127)
                    midiController:sendNote(i, midiNote, velocity)
                end
            end
            
            -- Move to next pattern if needed
            if beat == 1 and measure % 4 == 0 then -- Adjust this logic as needed
                sequenceManager:nextPattern()
            end
        end,
        bpm = function(newBPM)
            displayManager:updateBPM(newBPM)
            midiController:updateTempo(newBPM) -- If your MIDI controller needs to know about tempo changes
        end
    })

    params:add_number("current_pattern", "Current Pattern", 1, #songManager.currentSong.patterns, 1)
    params:set_action("current_pattern", function(value)
        sequenceManager:loadPattern(songManager.currentSong.patterns[value])
        displayManager:updateCurrentPattern(value)
        inputHandler:redrawGrid()
    end)
end

function redraw()
    if displayManager then displayManager:redraw() end
end

function key(n, z)
    inputHandler:handleKey(n, z)
end

function enc(n, d)
    inputHandler:handleEnc(n, d)
end

function cleanup()
    if midiController then
        midiController:cleanup()
    end
end