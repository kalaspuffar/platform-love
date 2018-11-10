local sti = require("sti")
local json = require("json")
local lurker = require("lurker")

require("player")
require("enemy")
require("collectable")
require("dialog")

local windowHeight
local windowWidth
local map
local world
local backgroundSound

local enemies = {}
local collectables = {}
local hero
local mute = false

local elapsedTime = 0
local score = 0

function printTable(val)
    for k, v in pairs(val) do
        print(k)
        print(v)
    end
    print("-----------------------")
end

function reset() 
    backgroundSound:stop()
    collectables = {}
    enemies = {}
    mainDialog:clear()
    score = 0
end

function love.load()
	-- Grab window size
	windowWidth  = love.graphics.getWidth()
	windowHeight = love.graphics.getHeight()

    backgroundSound = love.audio.newSource("assets/sound/Kevin_MacLeod_-_Clean_Soul.mp3", "stream")
    backgroundSound:setLooping(true)
    backgroundSound:setVolume(0.3)
    if(not mute) then
        backgroundSound:play()
    end

    math.randomseed(os.time())

	-- Set world meter size (in pixels)
	love.physics.setMeter(64)

    mainDialog = dialog.new()

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
        windowHeight / 2
    )

    lurker.preswap = function(f)
        reset()
    end

    lurker.postswap = function(f) 
        print(f .. " was swapped")
        if(f == 'assets/maps/firstmap.lua') then
            love:load()
        end
    end
end

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
        v:update(dt, map)
    end

    mainDialog:update(dt)
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

    mainDialog:draw()
    
	--love.graphics.setColor(255, 0, 0)
    --map:box2d_draw(hero:getScreenX(), hero:getScreenY())

    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Score: " .. score, 20, 20, 0, 2, 2)
end

function love.keypressed(key)
    if(key == "r") then        
        reset()
        love:load()
    end
    if(key == "space") then
        mainDialog:sayNext()
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
            mainDialog:startScript(a:getUserData().properties.script)
            a:destroy()
        end
    end    

    if(a:isSensor() and a:getUserData().type) then
        if(a:getUserData():type() == "collectable" and b:getUserData():type() == 'player') then
            a:getUserData():collect()
            a:destroy()
            score = score + 20
        end
    end
end

function endContact(a, b, coll)
end

function preSolve(a, b, coll)
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end