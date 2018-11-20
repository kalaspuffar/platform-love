local json = require("lib/json")

collectable = {}

collectable.new = function(x, y, physicsWorld, valueType)
    local self = {}
    self.x = x + 32
    self.y = y - 32
    self.valueType = valueType

    self.collectGemSound = love.audio.newSource("assets/sound/gem.wav", "static")
    self.collectGemSound:setVolume(0.4)

    self.physics = {}
    self.physics.world = physicsWorld
    self.physics.body = love.physics.newBody(
        self.physics.world,
        self.x,
        self.y,
        "static")
    self.physics.shape = love.physics.newCircleShape(20)
    self.physics.fixture = love.physics.newFixture(
        self.physics.body,
        self.physics.shape,
        1
    )
    self.physics.fixture:setSensor(true)
    self.physics.fixture:setUserData(self)

    self.collectableSprites = love.graphics.newImage("assets/maps/Tiles_64x64.png")
    self.activeFrame = love.graphics.newQuad(64 * 2 + 1, 64 * 6 + 1, 63, 63, self.collectableSprites:getDimensions())
    self.visible = not (self.valueType == "hidden_gem")

    self.type = function() 
        return "collectable"
    end    

    self.showHidden = function()
        if(not (self.valueType == "hidden_gem")) then
            return
        end
        if(self.physics.fixture) then
            self.visible = true
        end
    end

    self.hideHidden = function()
        if(not (self.valueType == "hidden_gem")) then
            return
        end
        self.visible = false
    end

    self.collect = function() 
        self.collectGemSound:play()
        self.visible = false
        self.physics.fixture:destroy()
        self.physics.fixture = false  
    end

    self.draw = function(self, screenX, screenY)
        if not self.visible then
            return
        end
        love.graphics.draw(
            self.collectableSprites,
            self.activeFrame,
            self.physics.body:getX() + screenX - 32,
            self.physics.body:getY() + screenY - 32,
            0,
            1,
            1
        )
    end

    return self
end