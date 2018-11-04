-- This example uses the included Box2D (love.physics) plugin!!

local sti = require "sti"
require("Player")

local windowHeight
local windowWidth
local map
local world

local player

function love.load()
	-- Grab window size
	windowWidth  = love.graphics.getWidth()
	windowHeight = love.graphics.getHeight()

    local backgroundSound = love.audio.newSource("assets/sound/Kevin_MacLeod_-_Clean_Soul.mp3", "stream")
    backgroundSound:setLooping(true)
    backgroundSound:setVolume(0.7)
    backgroundSound:play()

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

    player = Player.new(
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
        player:moveLeft()
    end
    if(love.keyboard.isDown("right")) then
        player:moveRight()
    end

    world:update(dt)
    map:update(dt)
    player:update(dt)
end

function love.draw()        
	love.graphics.setColor(255, 255, 255)
	map:draw(player:getScreenX(), player:getScreenY())
    player:draw()

	--love.graphics.setColor(255, 0, 0)
    --map:box2d_draw(player:getScreenX(), player:getScreenY())

end

function love.keypressed(key)
    if(key == "up") then
        player:jump()
    end
end