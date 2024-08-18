-- main.lua
local ClockManager = include('lib/clock_manager')
local DisplayManager = include('lib/display_manager')
local InputHandler = include('lib/input_handler')
local MIDIController = include('lib/midi_controller')
local SequenceManager = include('lib/sequence_manager')
local SongManager = include('lib/song_manager')

function init()

    local my_grid = grid.connect()
    print("Grid connected:", my_grid.device)

    clockManager = ClockManager.new()
    clockManager:init(clock, params)
    
    midiController = MIDIController.new()
    midiController:init(midi)
    midiController:connect()
    
    sequenceManager = SequenceManager.new()
    sequenceManager:init(midiController)
    
    songManager = SongManager.new()
    songManager:init(params, sequenceManager)
    
    displayManager = DisplayManager.new()
    displayManager:init(screen, params, sequenceManager, songManager)
    
    inputHandler = InputHandler.new()
    inputHandler:init(params, clockManager, displayManager, sequenceManager)

    songManager:loadSong("default_song.xml")

    redraw_metro = metro.init()
    redraw_metro.time = 1/15
    redraw_metro.event = function() displayManager:redraw() end
    redraw_metro:start()
    
    clockManager:addListener({
        tick = function()
            local measure, beat = clockManager:getCurrentPosition()
            displayManager:updateMeasureCount(measure)
            
            local currentStep = (beat - 1) % 16 + 1
            local stepData = sequenceManager:getCurrentStep(currentStep)
            
            for i, data in ipairs(stepData) do
                if data.value > 0 then
                    local midiNote = midiController:getMIDINoteForSample(data.sample_name)
                    local velocity = math.floor(data.value * data.volume * 127)
                    midiController:sendNote(i, midiNote, velocity)
                end
            end
            
            if beat == 1 and measure % 4 == 0 then -- Adjust this logic as needed
                sequenceManager:nextPattern()
            end
        end,
        bpm = function(newBPM)
            displayManager:updateBPM()
            midiController:updateTempo(newBPM) -- If your MIDI controller needs to know about tempo changes
        end
    })

    params:add_number("current_pattern", "Current Pattern", 1, #songManager.currentSong.patterns, 1)
    params:set_action("current_pattern", function(value)
        sequenceManager:loadPattern(songManager.currentSong.patterns[value])
        displayManager:updateCurrentPattern(value)
        inputHandler:redrawGrid()
    end)
    inputHandler:redrawGrid()
    params:set("current_pattern", 1) 
end


function redraw() displayManager:redraw() end
function key(n, z) inputHandler:handleKey(n, z) end
function enc(n, d) inputHandler:handleEnc(n, d) end