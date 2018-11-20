local json = require("lib/json")

barrel = {}
barrel.new = function(x, y, physicsWorld)
    local self = {}
    self.x = x
    self.y = y

    self.playerX = 0
    self.playerY = 0
    self.scale = 0
    self.enemySize = 1
    self.enemyOffsetX = 32
    self.enemyOffsetY = 32
    self.visible = true

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
    self.physics.fixture:setUserData(self)

    self.elapsedTime = 0
    self.currentFrame = 1
    self.enemySprites = love.graphics.newImage("assets/characters/barrel/barrel.png")
    self.frames = {}

    self.enemySpritesJson = json.decode(love.filesystem.read('assets/characters/barrel/barrel.json'))
    for k, v in pairs(self.enemySpritesJson.frames) do
        self.frames[k] = love.graphics.newQuad(
            v.frame.x, v.frame.y, v.frame.w, v.frame.h,
            self.enemySprites:getDimensions()
        )
    end

    self.destroy = function()
        self.visible = false
        self.physics.fixture:destroy()
    end

    self.destroyed = function()
        return not self.visible
    end

    self.activeFrame = self.frames[self.currentFrame]

    self.draw = function(self, screenX, screenY)
        if not self.visible then
            return
        end
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
        return "spawnable"
    end

    self.canHurt = function()
        return 1
    end

    self.getX = function()
        return self.playerX
    end

    self.getY = function()
        return self.playerY
    end

    self.update = function(self, dt, map)
        self.elapsedTime = self.elapsedTime + dt

        if(self.elapsedTime > 0.01) then
            self.currentFrame = self.currentFrame + 1
            if(self.currentFrame > table.getn(self.frames)) then
                self.currentFrame = 1
            end
            self.elapsedTime = 0
        end

        self.activeFrame = self.frames[self.currentFrame]

        local velocity = ({self.physics.body:getLinearVelocity()})[1];

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