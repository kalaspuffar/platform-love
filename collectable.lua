local json = require("json")

collectable = {}

collectable.new = function(x, y, physicsWorld)
    local self = {}
    self.x = x + 32
    self.y = y - 32

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
    self.visible = true

    self.type = function() 
        return "collectable"
    end

    self.hide = function() 
        self.visible = false
        self.physics.fixture:destroy()        
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