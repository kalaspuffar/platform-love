enemy = {}

enemy.new = function(x, y, physicsWorld, windowHalfWidth, windowHalfHeight, userData)
    local self = {}
    self.windowHalfWidth = windowHalfWidth
    self.windowHalfHeight = windowHalfHeight
    self.x = x
    self.y = y

    self.playerX = 0
    self.playerY = 0
    self.scale = 0
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
    self.physics.fixture:setUserData(userData)


    self.walkSound = love.audio.newSource("assets/sound/stepdirt_1.wav", "static")
    self.walkSound:setLooping(true)
    self.walkSound:setVolume(0.05)
    self.jumpSound = love.audio.newSource("assets/sound/jump_03.wav", "static")
    self.jumpSound:setVolume(0.05)

    self.elapsedTime = 0
    self.currentFrame = 1
    self.playerFile = love.graphics.newImage("assets/characters/sara-cal.png")
    self.frames = {}
    self.frames[1] = love.graphics.newQuad(0, 8, 32, 48, self.playerFile:getDimensions())
    self.frames[2] = love.graphics.newQuad(0, 136, 32, 48, self.playerFile:getDimensions())
    self.frames[3] = love.graphics.newQuad(0, 72, 32, 48, self.playerFile:getDimensions())
    self.frames[4] = love.graphics.newQuad(36, 72, 32, 48, self.playerFile:getDimensions())
    self.frames[5] = love.graphics.newQuad(72, 72, 32, 48, self.playerFile:getDimensions())
    self.activeFrame = self.frames[self.currentFrame]

    self.draw = function(self, screenX, screenY)
        love.graphics.draw(
            self.playerFile,
            self.activeFrame,
            self.playerX + screenX,
            self.playerY + screenY,
            0,
            self.scale,
            2
        )
    end

    self.getX = function()
        return playerX
    end

    self.moveLeft = function()
        local velocity = ({self.physics.body:getLinearVelocity()})[1];
        if(velocity > -100) then
            self.physics.body:applyLinearImpulse(-10, 0)
        end
    end

    self.moveRight = function()
        local velocity = ({self.physics.body:getLinearVelocity()})[1];
        if(velocity < 100) then
            self.physics.body:applyLinearImpulse(10, 0)
        end
    end

    self.jump = function()
        local velocity = ({self.physics.body:getLinearVelocity()})[2];

        if(velocity < 2 and velocity > -2) then
            self.jumpSound:play()
            self.physics.body:applyLinearImpulse(0, -400)
        end
    end

    self.update = function(self, dt)
        self.elapsedTime = self.elapsedTime + dt

        local velocity = ({self.physics.body:getLinearVelocity()})[1];

        if(velocity < 10 and velocity > -10) then
            if(self.goingRight) then
                self.physics.body:applyLinearImpulse(200, 0)
            else
                self.physics.body:applyLinearImpulse(-200, 0)
            end
            self.goingRight = not self.goingRight
        end

        if(not self.walkSound:isPlaying()) then
            self.walkSound:play()
        end
        if(self.currentFrame == 3 and self.elapsedTime > 0.2) then
            self.currentFrame = 4
            self.elapsedTime = 0
        elseif(self.currentFrame == 4 and self.elapsedTime > 0.2) then
            self.currentFrame = 5
            self.elapsedTime = 0
        elseif(self.currentFrame == 5 and self.elapsedTime > 0.2) then
            self.currentFrame = 3
            self.elapsedTime = 0
        elseif(self.currentFrame < 3) then
            self.currentFrame = 3
        end

        self.activeFrame = self.frames[self.currentFrame]

        self.scale = 2
        local offset = -32
        if(velocity > 0) then
            offset = 32
            self.scale = -2
        end

        self.playerX = self.physics.body:getX() + offset
        self.playerY = self.physics.body:getY() - 64
    end

    return self
end