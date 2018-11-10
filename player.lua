player = {}

player.new = function(x, y, physicsWorld, windowHalfWidth, windowHalfHeight, userData)
    local self = self or {}
    self.windowHalfWidth = windowHalfWidth
    self.windowHalfHeight = windowHalfHeight
    self.x = x
    self.y = y

    self.screenX = 0
    self.screenY = 0
    self.playerX = 0
    self.playerY = 0
    self.scale = 0

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
    self.playerFile = love.graphics.newImage("assets/characters/sara/sara-cal.png")
    self.frames = {}
    self.frames[1] = love.graphics.newQuad(0, 8, 32, 48, self.playerFile:getDimensions())
    self.frames[2] = love.graphics.newQuad(0, 136, 32, 48, self.playerFile:getDimensions())
    self.frames[3] = love.graphics.newQuad(0, 72, 32, 48, self.playerFile:getDimensions())
    self.frames[4] = love.graphics.newQuad(36, 72, 32, 48, self.playerFile:getDimensions())
    self.frames[5] = love.graphics.newQuad(72, 72, 32, 48, self.playerFile:getDimensions())
    self.activeFrame = self.frames[self.currentFrame]

    self.draw = function()
        love.graphics.draw(
            self.playerFile,
            self.activeFrame,
            self.playerX,
            self.playerY,
            0,
            self.scale,
            2
        )
    end

    self.moveLeft = function()
        local velocity = ({self.physics.body:getLinearVelocity()})[1];

        self.goingRight = false

        if(velocity > -100) then
            self.physics.body:applyLinearImpulse(-10, 0)
        end
    end

    self.moveRight = function()
        local velocity = ({self.physics.body:getLinearVelocity()})[1];

        self.goingRight = true
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

    self.getScreenX = function()
        return self.screenX
    end

    self.getScreenY = function()
        return self.screenY
    end

    self.update = function(a, dt)
        self.elapsedTime = self.elapsedTime + dt

        local velocity = ({self.physics.body:getLinearVelocity()})[1];

        if(velocity < 10 and velocity > -10) then
            if(self.walkSound:isPlaying()) then
                self.walkSound:stop()
            end

            if(self.currentFrame == 1 and self.elapsedTime > 2) then
                self.currentFrame = 2
                self.elapsedTime = 0
            elseif(self.currentFrame == 2 and self.elapsedTime > 0.3) then
                self.currentFrame = 1
                self.elapsedTime = 0
            elseif(self.currentFrame > 2) then
                self.currentFrame = 1
            end
        else
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
        end
        self.activeFrame = self.frames[self.currentFrame]

        self.scale = 2
        local offset = -32
        if(self.goingRight) then
            offset = 32
            self.scale = -2
        end

        if(self.physics.body:getX() > self.windowHalfWidth) then
            self.playerX = self.windowHalfWidth + offset
            self.screenX = -(self.physics.body:getX() - self.windowHalfWidth)
        else
            self.playerX = self.physics.body:getX() + offset
        end

        if(self.physics.body:getY() > self.windowHalfHeight) then
            self.playerY = self.windowHalfHeight - 64
            self.screenY = -(self.physics.body:getY() - self.windowHalfHeight)
        else
            self.playerY = self.physics.body:getY() - 64
        end
    end

    return self
end