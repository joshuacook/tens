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
    
    midiController = MIDIController.new()
    midiController:init()
    
    sequenceManager = SequenceManager.new()
    sequenceManager:init(midiController)
    
    songManager = SongManager.new()
    songManager:init(params, sequenceManager)
    
    displayManager = DisplayManager.new()
    displayManager:init(screen, params, sequenceManager, songManager)
    
    clockManager = ClockManager.new()
    clockManager:init(clock, params, displayManager)
    
    inputHandler = InputHandler.new()
    inputHandler:init(params, clockManager, displayManager, sequenceManager, songManager)

    songManager:loadSong("001.xml")

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
            for seq, drums in pairs(stepData) do
                local drumMachineIndex = tonumber(seq:sub(5, 5))
                local isSequenceB = seq:sub(-1) == "b"
                for drumIndex, value in ipairs(drums) do
                    if isSequenceB then
                        drumIndex = drumIndex + 8
                    end
                    if value > 0 then
                        local velocity = math.floor(value * 42)  -- Assuming value is between 0 and 3
                        midiController:sendNote(drumMachineIndex, drumIndex, velocity)
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
            midiController:updateTempo(newBpm)
        end
    })

    params:add_number("current_scene", "Current Scene", 1, #songManager.currentSong.scenes, 1)
    params:set_action("current_scene", function(value)
        songManager:loadScene(value)
        displayManager:updateCurrentSequence(sequenceManager.currentSequence)
        inputHandler:redrawGrid()
    end)
    inputHandler:redrawGrid()
    params:set("current_scene", 1) 
end

function redraw() displayManager:redraw() end
function key(n, z) inputHandler:handleKey(n, z) end
function enc(n, d) inputHandler:handleEnc(n, d) end