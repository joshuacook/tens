-- main.lua
local ClockManager = include('lib/clock_manager')
local DisplayManager = include('lib/display_manager')
local DrumPatternManager = include('lib/drum_pattern_manager')
local InputHandler = include('lib/input_handler')
local MIDIController = include('lib/midi_controller')
local SequenceManager = include('lib/sequence_manager')
local SongManager = include('lib/song_manager')
local SONG_FILE_PATH = "006.xml"

local function switch_scene()
    local current_scene = songManager:getCurrentSceneIndex()
    local new_scene = current_scene == 1 and 2 or 1
    songManager:loadScene(new_scene)
    displayManager:updateCurrentScene(new_scene)
    params:set("current_scene", new_scene)
end

function init()
    local my_grid = grid.connect()
    print("Grid connected:", my_grid.device)
    
    midiController = MIDIController.new()
    midiController:init()
    
    drumPatternManager = DrumPatternManager.new()
    drumPatternManager:init(midiController)
    
    sequenceManager = SequenceManager.new()
    sequenceManager:init(midiController)
    
    songManager = SongManager.new()
    songManager:init(params, sequenceManager, drumPatternManager, SONG_FILE_PATH)
    
    displayManager = DisplayManager.new()
    displayManager:init(SONG_FILE_PATH, screen, params, sequenceManager, songManager, drumPatternManager)
    
    clockManager = ClockManager.new()
    clockManager:init(clock, params, displayManager, songManager)
    
    inputHandler = InputHandler.new()
    inputHandler:init(params, clockManager, displayManager, sequenceManager, songManager, drumPatternManager, midiController)

    clockManager:addListener({
        tick = function()
            local measure, beat, sixteenthNote = clockManager:getCurrentPosition()
            local transitionIndex = math.max(1, (measure - 1) % 4 * 4 + beat)
            local transition = songManager.transitions[transitionIndex]
            local probabilities = {}
            local currentPattern = drumPatternManager.playingPatternIndex
            local cumulativeProbability = 0
            for i = 1, 8 do
                local probability = transition[(currentPattern - 1) * 8 + i]
                cumulativeProbability = cumulativeProbability + probability
                probabilities[i] = cumulativeProbability
            end
            local randomValue = math.random() * cumulativeProbability

            for i = 1, 8 do
                if randomValue <= probabilities[i] then
                    drumPatternManager:setPlayingPatternIndex(i)
                    if displayManager.pages[displayManager.currentPageIndex] == "drummer" then
                        displayManager.playingPatternIndex = i
                        displayManager:redraw()
                    end
                    break
                end
            end

            displayManager:updateMeasureCount(measure)
            if displayManager.pages[displayManager.currentPageIndex] == "main" then
                inputHandler:updateBeat(beat, sixteenthNote)
            end

            local stepInMeasure = (beat - 1) * 4 + sixteenthNote
    
            if measure % 4 == 1 then
                local stepData = sequenceManager:getCurrentStep(measure, beat, sixteenthNote)
                if stepData then
                    for seq, drums in pairs(stepData) do
                        local drumMachineIndex = tonumber(seq:sub(5, 5))
                        local isSequenceB = seq:sub(-1) == "b"
                        for drumIndex, value in ipairs(drums) do
                            if isSequenceB then
                                drumIndex = drumIndex + 8
                            end
                            if value > 0 then
                                local velocity = math.floor(value * 42)
                                midiController:sendNote(drumMachineIndex, drumIndex, velocity)
                            end
                        end
                    end
                end
            end

            if drumPatternManager:getPlayingPattern() then
                drumPatternManager:playStep(stepInMeasure, 2)
            end
            
            if sixteenthNote == 4 and beat == 4 then
                songManager.scenePlayCounter = songManager.scenePlayCounter + 1
                local currentSceneDuration = songManager:getCurrentSceneDuration()
                displayManager:redraw()
                if songManager.scenePlayCounter >= currentSceneDuration then
                    if songManager.autoAdvanceScenes then
                        songManager:advanceSongPosition()
                        displayManager:updateCurrentScene(songManager:getCurrentSceneIndex())
                        inputHandler:redrawGrid()
                    else
                        songManager.scenePlayCounter = 0
                    end
                    displayManager:redraw()
                end
            end
            
            if sixteenthNote == 1 then
            end
            
            if sixteenthNote == 1 and beat == 1 and measure % 4 == 0 then
            end
        end
    })

    params:add_number("current_scene", "Current Scene", 1, #songManager.currentSong.scenes, 1)
    params:set_action("current_scene", function(value)
        songManager:loadScene(value)
        displayManager:updateCurrentScene(value)
    end)

    params:add_number("editing_scene", "Editing Scene", 1, #songManager.currentSong.scenes, 1)
    params:set_action("editing_scene", function(value)
        songManager:setEditingSceneIndex(value)
        displayManager:updateEditingScene(value)
        inputHandler:redrawGrid()
    end)

    inputHandler:redrawGrid()
    params:set("current_scene", 1)
    params:set("editing_scene", 1)
end

function redraw() displayManager:redraw() end
function key(n, z) inputHandler:handleKey(n, z) end
function enc(n, d) inputHandler:handleEnc(n, d) end