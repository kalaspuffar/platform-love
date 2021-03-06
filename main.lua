local sti = require("lib/sti")
local json = require("lib/json")
local lurker = require("lib/lurker")

require("classes/player")
require("classes/enemy")
require("classes/collectable")
require("classes/dialog")
require("classes/barrel")

local windowHeight
local windowWidth
local map
local world
local backgroundSound
local sparkleSound

local enemies = {}
local collectables = {}
local spawnPoints = {}
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
    spawnPoints = {}
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

    sparkleSound = love.audio.newSource("assets/sound/sparkle.wav", "static")
    sparkleSound:setVolume(0.5)                

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
            table.insert(enemies, enemy.new(v.x, v.y, world))
        end

        if(v.type == "collectable") then
            table.insert(collectables, collectable.new(v.x, v.y, world, v.properties.value))
        end

        if(v.type == "spawn") then
            table.insert(spawnPoints, {
                x = v.x,
                y = v.y,
                spawn = true,
                type = v.properties.type
            })
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
        --if(f == 'assets/maps/firstmap.lua') then
            love:load()
        --end
    end
end

function love.update(dt)
    elapsedTime = elapsedTime + dt

    lurker.update()

    if(love.keyboard.isDown("left")) then
        hero:moveLeft()
    end
    if(love.keyboard.isDown("right")) then
        hero:moveRight()
    end

    hero:sprint(dt, love.keyboard.isDown("lshift"))

    world:update(dt)
    map:update(dt)
    hero:update(dt)

    local newEnemies = {}
    for k,v in pairs(enemies) do
        if(not v.destroyed()) then
            table.insert(newEnemies, v)
        end
        v:update(dt, map)
    end

    enemies = newEnemies

    if(elapsedTime > 10) then
        for k,v in pairs(spawnPoints) do
            table.insert(enemies, barrel.new(v.x, v.y, world))
        end
        elapsedTime = 0
    end
    mainDialog:update(dt)
end

function love.draw()
    if not map then
        love.load()
    end

    if(hero.gameOver) then
        love.graphics.setColor(255, 255, 255)
        love.graphics.print("Game over!", windowWidth / 2 - 150, windowHeight / 2 - 40, 0, 5, 5)
        return
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

    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, windowWidth, 40)

    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Score: " .. score, 20, 5, 0, 2, 2)

    love.graphics.setColor(0, 0, 255)
    love.graphics.rectangle("fill", 200, 10, hero:getSprintTimeLeft() * 100, 20)
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("line", 200, 10, 100, 20)

    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("fill", 350, 10, hero:getHealthLeft() * 100, 20)
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("line", 350, 10, 100, 20)
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
    if(a:isSensor()) then
        if(a:getUserData().properties) then
            if(a:getUserData().properties.type == 'dialog' and b:getUserData():type() == 'player') then
                mainDialog:startScript(a:getUserData().properties.script)
                a:destroy()
            end
            if(a:getUserData().properties.type == 'despawn' and b:getUserData():type() == 'spawnable') then
                b:getUserData():destroy()
            end
            if(a:getUserData().properties.type == 'reveal' and b:getUserData():type() == 'player') then
                map.layers.hidden.opacity = 0
                sparkleSound:play()
                for k,v in pairs(collectables) do
                    v:showHidden()
                end
            end
        end
        if(a:getUserData().type) then
            if(a:getUserData():type() == "collectable" and b:getUserData():type() == 'player') then
                a:getUserData():collect()
                a:destroy()
                score = score + 20
            end
        end
    end

    if(not b:isSensor() and a:getUserData().type and a:getUserData().type() == 'player') then
        if(b:getUserData().canHurt) then
            a:getUserData():hurt(coll, b:getUserData():canHurt(), true)
        end
    end

    if(not a:isSensor() and b:getUserData().type() == 'player') then
        if(a:getUserData().canHurt) then
            b:getUserData():hurt(coll, a:getUserData():canHurt(), false)
        else
            nx, ny = coll:getNormal()
            if(ny < 0) then
                b:getUserData():landed()
            end
        end
    end
end

function endContact(a, b, coll)
    if(a:isSensor() and a:getUserData().properties) then
        if(a:getUserData().properties.type == 'reveal' and b:getUserData():type() == 'player') then
            map.layers.hidden.opacity = 1
            for k,v in pairs(collectables) do
                v:hideHidden()
            end
        end
    end
end

function preSolve(a, b, coll)
end

function postSolve(a, b, coll, normalimpulse, tangentimpulse)
end