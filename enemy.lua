local json = require("json")

enemy = {}

enemy.new = function(x, y, physicsWorld, windowHalfWidth, windowHalfHeight)
    local self = {}
    self.windowHalfWidth = windowHalfWidth
    self.windowHalfHeight = windowHalfHeight
    self.x = x
    self.y = y

    self.playerX = 0
    self.playerY = 0
    self.scale = 0
    self.enemySize = 0.5
    self.enemyOffsetX = 28
    self.enemyOffsetY = 56
    self.goingRight = false

    self.physics = {}
    self.physics.world = physicsWorld
    self.physics.body = love.physics.newBody(
        self.physics.world,
        self.x,
        self.y,
        "dynamic")
    self.physics.shape = love.physics.newCircleShape(32)
    self.physics.fixture = love.physics.newFixture(
        self.physics.body,
        self.physics.shape,
        1
    )
    self.physics.fixture:setFriction(1.0)
    self.physics.fixture:setUserData(self)


    self.walkSound = love.audio.newSource("assets/sound/stepdirt_1.wav", "static")
    self.walkSound:setVolume(0.05)
    self.jumpSound = love.audio.newSource("assets/sound/jump_03.wav", "static")
    self.jumpSound:setVolume(0.05)

    self.elapsedTime = 0
    self.currentFrame = 1
    self.enemySprites = love.graphics.newImage("assets/characters/mush/running.png")
    self.frames = {}

    self.enemySpritesJson = json.decode(love.filesystem.read('assets/characters/mush/running.json'))
    for k, v in pairs(self.enemySpritesJson.frames) do
        self.frames[k] = love.graphics.newQuad(
            v.frame.x, v.frame.y, v.frame.w, v.frame.h, 
            self.enemySprites:getDimensions()
        )
    end

    self.activeFrame = self.frames[self.currentFrame]

    self.draw = function(self, screenX, screenY)
        love.graphics.draw(
            self.enemySprites,
            self.activeFrame,
            self.playerX + screenX,
            self.playerY + screenY,
            0,
            self.scale,
            self.enemySize
        )
    end

    self.type = function()
        return "enemy"
    end

    self.getX = function()
        return self.playerX
    end

    self.getY = function()
        return self.playerY
    end

    self.stop = function()
        self.physics.body:setLinearVelocity(0, 0)
    end

    self.moveLeft = function()
        local velocity = ({self.physics.body:getLinearVelocity()})[1];
        if(velocity > -10) then
            self.physics.body:applyLinearImpulse(-200, 0)
        end
        self.goingRight = true
    end

    self.moveRight = function()
        local velocity = ({self.physics.body:getLinearVelocity()})[1];
        if(velocity < 10) then
            self.physics.body:applyLinearImpulse(200, 0)
        end
        self.goingRight = false
    end

    self.jump = function()
        local velocity = ({self.physics.body:getLinearVelocity()})[2];

        if(velocity < 2 and velocity > -2) then
            self.jumpSound:play()
            self.physics.body:applyLinearImpulse(0, -400)
        end
    end

    self.getVelocity = function() 
        return ({self.physics.body:getLinearVelocity()})[1];
    end

    self.update = function(self, dt)
        self.elapsedTime = self.elapsedTime + dt

        local velocity = self.getVelocity()
        if(velocity < 10 and velocity > -10) then
            if(self.goingRight) then
                self.moveRight()
            else
                self.moveLeft()
            end
        end

        if(self.walkSound:isPlaying()) then
            self.walkSound:stop()            
        end
        if(self.elapsedTime > 0.01) then            
            self.currentFrame = self.currentFrame + 1
            if(self.currentFrame > table.getn(self.frames)) then
                self.currentFrame = 1
            end
            self.elapsedTime = 0
        end

        self.activeFrame = self.frames[self.currentFrame]

        self.scale = -self.enemySize
        local offset = self.enemyOffsetX
        if(velocity > 0) then
            offset = -self.enemyOffsetX
            self.scale = self.enemySize
        end

        self.playerX = self.physics.body:getX() + offset
        self.playerY = self.physics.body:getY() - self.enemyOffsetY
    end

    return self
end