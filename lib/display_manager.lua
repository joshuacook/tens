-- lib/display_manager.lua
local DisplayManager = {}
DisplayManager.__index = DisplayManager

function DisplayManager.new()
    return setmetatable({}, DisplayManager)
end

function DisplayManager:init(screen, sequenceManager, songManager)
    self.screen = screen
    self.sequenceManager = sequenceManager
    self.songManager = songManager
    self.sequencePage = self.sequenceManager.sequencePage
    self.bpm = 120
    self.measureCount = 1
    self.isMetadataPage = false
    self.dirty = true
end

function DisplayManager:updateMeasureCount(count)
    self.measureCount = count
    self:redraw()
    self.dirty = true
end

function DisplayManager:updateBPM(bpm)
    self.bpm = bpm
    self:redraw()
    self.dirty = true
end

function DisplayManager:updateSequencePage(page)
    self.sequencePage = page
    self:redraw()
    self.dirty = true
end

function DisplayManager:showMetadataPage(show)
    self.isMetadataPage = show
    self:redraw()
    self.dirty = true
end

function DisplayManager:redraw()
    if not self.dirty then return end

    self.screen.clear()
    self.screen.font_face(1)
    self.screen.font_size(8)

    if self.isMetadataPage then
        self:drawMetadataPage()
    else
        self:drawMainPage()
    end
    self.screen.update()
    self.dirty = false
end

function DisplayManager:drawMainPage()
    self.screen.move(0, 10)
    self.screen.text("Measure: " .. self.measureCount)

    self.screen.move(0, 20)
    self.screen.text("BPM: " .. self.bpm)

    self.screen.move(0, 30)
    self.screen.text("Page: " .. self.sequencePage)

    local beatPosition = (self.measureCount - 1) % 4 + 1
    for i = 1, 4 do
        self.screen.circle(30 + i * 15, 50, 3)
        if i == beatPosition then
            self.screen.fill()
        else
            self.screen.stroke()
        end
    end
end

function DisplayManager:drawMetadataPage()
    self.screen.move(0, 10)
    self.screen.text("Metadata Page")
    
    -- Add more metadata information here
    -- For example:
    self.screen.move(0, 30)
    self.screen.text("Song: My Awesome Track")
    self.screen.move(0, 40)
    self.screen.text("Created: 2023-08-17")
    -- ... add more metadata as needed
end

return DisplayManager