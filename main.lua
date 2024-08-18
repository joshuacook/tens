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
            local measure, beat, sixteenthNote = clockManager:getCurrentPosition()
            displayManager:updateMeasureCount(measure)
    
            local stepInMeasure = (beat - 1) * 4 + sixteenthNote
    
            local stepData = sequenceManager:getCurrentStep(stepInMeasure)
            for page, drums in pairs(stepData) do
                local deviceIndex = math.ceil(tonumber(page:sub(5, 5)) / 2)
                local isPageB = page:sub(-1) == "b"
                for drumIndex, value in ipairs(drums) do
                    if isPageB then
                        drumIndex = drumIndex + 8
                    end
                    if value > 0 then
                        print(deviceIndex, drumIndex, value)
                        local velocity = math.floor(value * 42)  -- Assuming value is between 0 and 1
                        midiController:sendNote(deviceIndex, drumIndex, velocity)
                    end
                end
            end
            
            if sixteenthNote == 1 and beat == 1 then
                -- Add any per-measure logic here
            end
            
            if sixteenthNote == 1 then
                -- Add any per-beat logic here
            end
            
            if sixteenthNote == 1 and beat == 1 and measure % 4 == 0 then
                -- This executes every 4 measures
                -- Add your logic here
            end
        end,
        
        bpm = function(newBpm)
            displayManager:updateBPM()
            midiController:updateTempo(newBpm) -- If your MIDI controller needs to know about tempo changes
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