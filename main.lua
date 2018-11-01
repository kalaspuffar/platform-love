local bump       = require 'bump'
local lurker     = require 'lurker'

local instructions = [[
  bump.lua simple demo

    arrows: move
    tab: toggle debug info
    delete: run garbage collector
]]

local cols_len = 0 -- how many collisions are happening

-- World creation
local world = bump.newWorld()


-- Message/debug functions
local function drawMessage()
  local msg = instructions:format(tostring(shouldDrawDebug))
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(msg, 550, 10)
end

local consoleBuffer = {}
local consoleBufferSize = 15
for i=1,consoleBufferSize do consoleBuffer[i] = "" end
local function consolePrint(msg)
  table.remove(consoleBuffer,1)
  consoleBuffer[consoleBufferSize] = msg
end

local function drawConsole()
  local str = table.concat(consoleBuffer, "\n")
  for i=1,consoleBufferSize do
    love.graphics.setColor(255,255,255, i*255/consoleBufferSize)
    love.graphics.printf(consoleBuffer[i], 10, 580-(consoleBufferSize - i)*12, 790, "left")
  end
end

-- helper function
local function drawBox(box, r,g,b)
  love.graphics.setColor(r,g,b,70)
  love.graphics.rectangle("fill", box.x, box.y, box.w, box.h)
  love.graphics.setColor(r,g,b)
  love.graphics.rectangle("line", box.x, box.y, box.w, box.h)
end



-- Player functions
local player = { x=50,y=600-70,w=20,h=20, speed = 80, jump = 100, jumping = 0 }

local function updatePlayer(dt)    
  local speed = player.speed
  local jump = player.jump

  local dx, dy = 0, 0
  if love.keyboard.isDown('right') then
    dx = speed * dt
  elseif love.keyboard.isDown('left') then
    dx = -speed * dt
  end
    
  if (player.jumping == 0 and love.keyboard.isDown('up')) then
    player.jumping = 30
  elseif player.jumping > 0 and not love.keyboard.isDown('up') then
    dy = -jump * dt
    player.jumping = player.jumping - 1
  else
    dy = jump * dt
  end

  if dx ~= 0 or dy ~= 0 then
    local cols
    player.x, player.y, cols, cols_len = world:move(player, player.x + dx, player.y + dy)
    for i=1, cols_len do
      local col = cols[i]
      consolePrint(("col.other = %s, col.type = %s, col.normal = %d,%d"):format(col.other, col.type, col.normal.x, col.normal.y))
    end
  end
end

local function drawPlayer()
  drawBox(player, 0, 255, 0)
end

-- Block functions

local blocks = {}

local function addBlock(x,y,w,h)
  local block = {x=x,y=y,w=w,h=h}
  blocks[#blocks+1] = block
  world:add(block, x,y,w,h)
end

local function drawBlocks()
  for _,block in ipairs(blocks) do
    drawBox(block, 255,0,0)
  end
end

function love.load()
  lurker.postswap = function(f) print("File " .. f .. " was swapped") end
  world:add(player, player.x, player.y, player.w, player.h)

  addBlock(0,       0,     800, 32)
  addBlock(0,      32,      32, 600-32*2)
  addBlock(800-32, 32,      32, 600-32*2)
  addBlock(0,      600-32, 800, 32)

  addBlock(200, 600-80, 50, 5)
  addBlock(300, 600-110, 50, 5)
  addBlock(400, 600-140, 50, 10)
end

function love.update(dt)
  lurker.update()
  cols_len = 0
  updatePlayer(dt)  
end

function love.draw()
  drawBlocks()
  drawPlayer()
  drawMessage()
end

-- Non-player keypresses
function love.keypressed(k)
  if k=="escape" then love.event.quit() end
  if k=="delete" then collectgarbage("collect") end
end