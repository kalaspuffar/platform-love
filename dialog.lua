local json = require("json")
local Moan = require("Moan")

dialog = {}

dialog.new = function()
    local self = {}
    
    self.mainScript = json.decode(love.filesystem.read('assets/scripts/main.json'))
    self.currentScript = ""
    self.currentScriptPlace = 1

    self.collectGemSound = love.audio.newSource("assets/sound/gem.wav", "static")
    self.collectGemSound:setVolume(0.4)

    -- The FontStruction “Pixel UniCode” (https://fontstruct.com/fontstructions/show/908795)
	-- by “ivancr72” is licensed under a Creative Commons Attribution license
	-- (http://creativecommons.org/licenses/by/3.0/)
    Moan.font = love.graphics.newFont("assets/fonts/Pixel.ttf", 32)

	-- Audio from bfxr (https://www.bfxr.net/)
    Moan.typeSound = love.audio.newSource("assets/sound/typeSound.wav", "static")
    Moan.typeSound:setVolume(0.01)
	Moan.optionOnSelectSound = love.audio.newSource("assets/sound/optionSelect.wav", "static")
	Moan.optionSwitchSound = love.audio.newSource("assets/sound/optionSwitch.wav", "static")

    self.update = function(self, dt)
        Moan.update(dt)
    end

    self.draw = function()
        Moan.draw()
    end

    self.startScript = function(self, script)
        self.currentScript = script
        self.currentScriptPlace = 1
        self.sayNext()
    end

    self.clear = function()
        Moan.clearMessages()
        if(self.voiceLine) then
            self.voiceLine:stop()
        end
    end

    self.sayNext = function()
        self.clear()
    
        if(
            not self.currentScript or 
            not self.mainScript[self.currentScript]
        ) then
            return
        end
        
        if(table.getn(self.mainScript[self.currentScript]) + 1 > self.currentScriptPlace) then
            local dialogObj = self.mainScript[self.currentScript][self.currentScriptPlace]
    
            local avatar = love.graphics.newImage("assets/characters/" .. dialogObj.image)
            Moan.speak(dialogObj.speaker, {dialogObj.text}, {image=avatar})
    
            if(dialogObj.voice) then
                self.voiceLine = love.audio.newSource("assets/voice/" .. dialogObj.voice, "stream")
                self.voiceLine:setVolume(0.5)
                self.voiceLine:play()
            end
    
            self.currentScriptPlace = self.currentScriptPlace + 1
        end
    end

    return self
end