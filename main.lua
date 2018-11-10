-- This example uses the included Box2D (love.physics) plugin!!

local sti = require("sti")
local json = require("json")
local Moan = require("Moan")
local lurker = require("lurker")

require("player")
require("enemy")
require("collectable")

local windowHeight
local windowWidth
local map
local world
local backgroundSound
local collectGemSound

local enemies = {}
local collectables = {}
local hero
local mute = false

local score = 0
local voiceLine
local mainScript
local currentScript
local currentScriptPlace = 1

function printPairs(val)
    for k, v in pairs(val) do
        print(k)
        print(v)
    end
    print("-----------------------")
end

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

    collectGemSound = love.audio.newSource("assets/sound/gem.wav", "static")
    collectGemSound:setVolume(0.4)

    backgroundSound = love.audio.newSource("assets/sound/Kevin_MacLeod_-_Clean_Soul.mp3", "stream")
    backgroundSound:setLooping(true)
    backgroundSound:setVolume(0.3)
    if(not mute) then
        backgroundSound:play()
    end

    math.randomseed(os.time())

    mainScript = json.decode(love.filesystem.read('assets/scripts/main.json'))

	-- Set world meter size (in pixels)
	love.physics.setMeter(64)

    -- Load a map exported to Lua from Tiled
	map = sti("assets/maps/firstmap.lua", { "box2d" })

    world = love.physics.newWorld(0, 8.91 * 64, true)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
	map:box2d_init(world)

    local startPosId = 0
    for k,v in pairs(map.objects) do
        if(v.name == "StartPos") then
            startPosId = k
        end

        if(v.type == "enemy") then
            table.insert(enemies, enemy.new(
                v.x,
                v.y,
                world,
                windowWidth / 2,
                windowHeight / 2
            ))
        end   

        if(v.type == "collectable") then
            table.insert(collectables, collectable.new(
                v.x,
                v.y,
                world
            ))
            
        end
    end

    hero = player.new(
        map.objects[startPosId].x,
        map.objects[startPosId].y,
        world,
        windowWidth / 2,
        windowHeight / 2,
        {
            name = map.objects[startPosId].name,
            type = map.objects[startPosId].type,
            properties = map.objects[startPosId].properties
        }
    )

    lurker.preswap = function(f)
        backgroundSound:stop()
    end

    lurker.postswap = function(f) 
        print(f .. " was swapped")
        if(f == 'assets/maps/firstmap.lua') then
            love:load()
        end
    end
end

local elapsedTime = 0
function love.update(dt)
    lurker.update()

    if(love.keyboard.isDown("left")) then
        hero:moveLeft()
    end
    if(love.keyboard.isDown("right")) then
        hero:moveRight()
    end
 
    world:update(dt)
    map:update(dt)
    hero:update(dt)

    for k,v in pairs(enemies) do
        v:update(dt)
        
        if(v:getX()) then
            tx, ty = map:convertPixelToTile(v:getX() + 32, v:getY() + 32)
            if(
                not map.layers.mainmap.data[math.floor(ty+0.5)+2][math.floor(tx+0.5)+1] and
                v:getVelocity() > 0
            ) then
                v:stop()
            elseif(
                not map.layers.mainmap.data[math.floor(ty+0.5)+2][math.floor(tx+0.5)-1] and
                v:getVelocity() < 0
            ) then
                v:stop()
            end
        end
    end

    Moan.update(dt)
end

function love.draw()
    if not map then
        love.load()
    end

    love.graphics.setColor(255, 255, 255)
    map:draw(hero:getScreenX(), hero:getScreenY())
    hero:draw()

    for k,v in pairs(collectables) do
        v:draw(hero:getScreenX(), hero:getScreenY())
    end
    for k,v in pairs(enemies) do
        v:draw(hero:getScreenX(), hero:getScreenY())
    end

    Moan.draw()
	--love.graphics.setColor(255, 0, 0)
    --map:box2d_draw(hero:getScreenX(), hero:getScreenY())

    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Score: " .. score, 20, 20, 0, 2, 2)
end

function sayNext()
    Moan.clearMessages()
    if(voiceLine) then
        voiceLine:stop()
    end

    if(not currentScript or not mainScript[currentScript]) then
        return
    end
    
    if(table.getn(mainScript[currentScript]) + 1 > currentScriptPlace) then
        local introSc = mainScript[currentScript][currentScriptPlace]

        avatar = love.graphics.newImage("assets/characters/" .. introSc.image)
        Moan.speak(introSc.speaker, {introSc.text}, {image=avatar})

        if(introSc.voice) then
            voiceLine = love.audio.newSource("assets/voice/" .. introSc.voice, "stream")
            voiceLine:setVolume(0.5)
            voiceLine:play()
        end

        currentScriptPlace = currentScriptPlace + 1
    end
end

function love.keypressed(key)
    if(key == "r") then        
        backgroundSound:stop()
        love:load()
    end
    if(key == "space") then
        sayNext()
    end

    if(key == "up") then
        hero:jump()
    end
    
    if(key == "down") then
        hero:stop()
    end

    if(key == "escape") then
        love.event.quit()
    end
end

function beginContact(a, b, coll)
    if(a:isSensor() and a:getUserData().properties) then
        if(a:getUserData().properties.type == 'dialog' and b:getUserData():type() == 'player') then
            a:destroy()
            currentScript = a:getUserData().properties.script
            currentScriptPlace = 1
            sayNext()
        end
    end    
            
    if(a:isSensor() and a:getUserData().type) then
        if(a:getUserData():type() == "collectable" and b:getUserData():type() == 'player') then
            a:getUserData():hide()
            score = score + 20
            collectGemSound:play()
        end
    end
end

function endContact(a, b, coll)
--    print('LOST')
--    persisting = 0    -- reset since they're no longer touching
--    if(a and b) then
--        print("\n"..a:getUserData().." uncolliding with "..b:getUserData())
--    end
end

function preSolve(a, b, coll)
--    if(b:getUserData().type == 'enemy') then
--        nx, ny = coll:getNormal()
--
--        if(nx > 0) then
--            enemies[1].moveRight()
--        elseif(nx < 0) then
--            enemies[1].moveLeft()
--        end
--        print(nx .. "x" .. ny)
--        print('SOLVED ' .. b:getUserData().type)
--    end

--    if persisting == 0 then    -- only say when they first start touching
--        print(a:getUserData().." touching "..b:getUserData())
--    elseif persisting < 20 then    -- then just start counting
--        print(persisting)
--    end
--    persisting = persisting + 1    -- keep track of how many updates they've been touching for
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
--    print('AFTER')
-- we won't do anything with this function
end