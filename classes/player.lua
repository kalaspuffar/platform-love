player = {}

player.new = function(x, y, physicsWorld, windowHalfWidth, windowHalfHeight)
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
    self.jumps = 0
    self.maxJumps = 1
    self.maxSprint = 3
    self.sprintTime = self.maxSprint
    self.maxHealth = 10
    self.health = self.maxHealth
    self.maxVelocity = 100
    self.walkAnimTime = 0.2

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
    self.physics.body:setFixedRotation(true)
    self.physics.body:setLinearDamping(0.1)

    self.walkSound = love.audio.newSource("assets/sound/stepdirt_1.wav", "static")
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

    self.type = function()
        return "player"
    end

    self.stop = function()
        self.physics.body:setLinearVelocity(0, 0)
    end

    self.moveLeft = function()
        local velocity = self.getVelocity()

        self.goingRight = false

        if(velocity > -self.maxVelocity) then
            self.physics.body:applyLinearImpulse(-10, 0)
        end
    end

    self.moveRight = function()
        local velocity = self.getVelocity()

        self.goingRight = true
        if(velocity < self.maxVelocity) then
            self.physics.body:applyLinearImpulse(10, 0)
        end
    end

    self.landed = function()
        self.jumps = 0
    end

    self.hurt = function(self, coll, loss)
        print("AOH")
        self.health = self.health - loss
    end

    self.getHealthLeft = function()
        return self.health / self.maxHealth
    end

    self.getSprintTimeLeft = function()
        return self.sprintTime / self.maxSprint
    end

    self.clampVelocity = function()
        if(self.getVelocity() > 100) then
            self.physics.body:applyLinearImpulse(-50, 0)
        end
        if(self.getVelocity() < -100) then
            self.physics.body:applyLinearImpulse(50, 0)
        end
        self.maxVelocity = 100
        self.walkAnimTime = 0.2
    end

    self.sprint = function(self, dt, sprinting)
        if(sprinting) then
            if(self.sprintTime > 0) then
                self.maxVelocity = 200
                self.walkAnimTime = 0.1
                self.sprintTime = self.sprintTime - dt
            else
                if(self.sprintTime < self.maxSprint) then
                    self.sprintTime = self.sprintTime + dt
                end
                self.clampVelocity()
            end
        else
            if(self.sprintTime < self.maxSprint) then
                self.sprintTime = self.sprintTime + dt
            end
            self.clampVelocity()
        end
    end

    self.jump = function()
        if(self.jumps < self.maxJumps) then
            self.jumps = self.jumps + 1
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

    self.getVelocity = function()
        return ({self.physics.body:getLinearVelocity()})[1];
    end

    self.update = function(self, dt)
        self.elapsedTime = self.elapsedTime + dt

        local velocity = self.getVelocity()

        if(velocity < 10 and velocity > -10) then
            if(self.walkSound:isPlaying()) then
                self.walkSound:pause()
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
            if(self.currentFrame == 3 and self.elapsedTime > self.walkAnimTime) then
                self.currentFrame = 4
                self.elapsedTime = 0
            elseif(self.currentFrame == 4 and self.elapsedTime > self.walkAnimTime) then
                self.currentFrame = 5
                self.elapsedTime = 0
            elseif(self.currentFrame == 5 and self.elapsedTime > self.walkAnimTime) then
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