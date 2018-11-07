-- This example uses the included Box2D (love.physics) plugin!!

local sti = require("sti")
local json = require("json")
local Moan = require("Moan")

require("player")

local windowHeight
local windowWidth
local map
local world

local hero

local voiceLine
local mainScript
local currentScript = "intro1"
local currentScriptPlace = 1

function love.load()
	-- Grab window size
	windowWidth  = love.graphics.getWidth()
	windowHeight = love.graphics.getHeight()

    -- The FontStruction “Pixel UniCode” (https://fontstruct.com/fontstructions/show/908795)
	-- by “ivancr72” is licensed under a Creative Commons Attribution license
	-- (http://creativecommons.org/licenses/by/3.0/)
    Moan.font = love.graphics.newFont("assets/fonts/Pixel.ttf", 32)

	-- Audio from bfxr (https://www.bfxr.net/)
    Moan.typeSound = love.audio.newSource("assets/sound/typeSound.wav", "static")
    Moan.typeSound:setVolume(0.01)
	Moan.optionOnSelectSound = love.audio.newSource("assets/sound/optionSelect.wav", "static")
	Moan.optionSwitchSound = love.audio.newSource("assets/sound/optionSwitch.wav", "static")
    local backgroundSound = love.audio.newSource("assets/sound/Kevin_MacLeod_-_Clean_Soul.mp3", "stream")
    backgroundSound:setLooping(true)
    backgroundSound:setVolume(0.3)
    backgroundSound:play()

    math.randomseed(os.time())

    mainScript = json.decode(love.filesystem.read('assets/scripts/main.json'))

	-- Set world meter size (in pixels)
	love.physics.setMeter(64)

	-- Load a map exported to Lua from Tiled
	map = sti("assets/maps/firstmap.lua", { "box2d" })

    local startPosId = 0
    for k,v in pairs(map.objects) do
        if(v.name == "StartPos") then
            startPosId = k
            break
        end
    end

	world = love.physics.newWorld(0, 8.91 * 64, true)
	map:box2d_init(world)

    hero = player.new(
        map.objects[startPosId].x,
        map.objects[startPosId].y,
        world,
        windowWidth / 2,
        windowHeight / 2
    )
end

local elapsedTime = 0
function love.update(dt)
    if(love.keyboard.isDown("left")) then
        hero:moveLeft()
    end
    if(love.keyboard.isDown("right")) then
        hero:moveRight()
    end

    world:update(dt)
    map:update(dt)
    hero:update(dt)
    Moan.update(dt)
end

function love.draw()
	love.graphics.setColor(255, 255, 255)
	map:draw(hero:getScreenX(), hero:getScreenY())
    hero:draw()

    Moan.draw()
	--love.graphics.setColor(255, 0, 0)
    --map:box2d_draw(hero:getScreenX(), hero:getScreenY())

end

function love.keypressed(key)
    if(key == "space") then
        Moan.clearMessages()
        if(voiceLine) then
            voiceLine:stop()
        end

        if(table.getn(mainScript[currentScript]) + 1 > currentScriptPlace) then
            local introSc = mainScript[currentScript][currentScriptPlace]

            avatar = love.graphics.newImage("assets/characters/" .. introSc.image)
            Moan.speak(introSc.speaker, {introSc.text}, {image=avatar})

            if(introSc.voice) then
                voiceLine = love.audio.newSource("assets/voice/" .. introSc.voice, "stream")
                voiceLine:setVolume(0.1)
                voiceLine:play()
            end

            currentScriptPlace = currentScriptPlace + 1
        end
    end

    if(key == "up") then
        hero:jump()
    end
end