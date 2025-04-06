if os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" then
    require("lldebugger").start()
end
world = {}

local TILE_SIZE = 128
local tileset
local quads = {}

local camera = {
    x = 0,
    y = 0
}

planets = {}
blackholes = {}
movingObjects = {}

gameTime = 0
local lastHpLoseTime = 0

isGameRunning = false
restartState = false
isCarryingPrize = false
toBeSpawned = false
areYouWinningSon = false

local prizeStaticBody = nil

local methods = require("methods")
local selectedTile = 1

local playerHp = 3

local playerStartPos = {
    x = 2700,
    y = 2550
}
local playerInput = {
    x = 0,
    y = 0
}

joint = nil

-- Sayaç
-- Restart button
-- Win state / logic
-- Yakıt / yakıt doldurma
-- Yakıt göstergesi
-- 

function love.mousepressed(x, y, button)
    --[[
    x = x *10/8
    y = y *10/8
    x = x + camera.x
    y = y + camera.y
    if button == 1 then -- Left click
        local gridX = math.floor(x / TILE_SIZE) + 1
        local gridY = math.floor(y / TILE_SIZE) + 1

        if methods.level[gridY] and methods.level[gridY][gridX] then
            methods.level[gridY][gridX] = selectedTile
        end

    elseif button == 2 then -- Right click to erase
        local gridX = math.floor(x / TILE_SIZE) + 1
        local gridY = math.floor(y / TILE_SIZE) + 1

        if methods.level[gridY] and methods.level[gridY][gridX] then
            methods.level[gridY][gridX] = 0
        end
    end
    ]]
end

function love.keypressed(key)
    --[[
    if tonumber(key) then
        local num = tonumber(key)
        if num >= 1 and num <= 9 and num <= #quads then
            selectedTile = num
        end
    end

    if key == "p" then
        methods.saveTilemap("level1.lua", methods.level)
    elseif key == "u" then
        methods.level = methods.loadTilemap("level1.lua")
    end ]]
    if key == "return" then
        if isGameRunning == false and restartState == false then
            isGameRunning = true
        elseif restartState then
            isGameRunning = true
            restartState = false
            gameTime = 0
            playerHp = 3
            if isCarryingPrize then
                methods.level[19][172] = 9
                prizeBody:destroy()
                prizeBody = nil
                local prizeX = 172
                local prizeY = 19
                local body = love.physics.newBody(world, (prizeX - 1) * TILE_SIZE + TILE_SIZE / 2, (prizeY - 1) * TILE_SIZE + TILE_SIZE / 2, "static")
                local shape = love.physics.newRectangleShape(TILE_SIZE, TILE_SIZE)
                local fixture = love.physics.newFixture(body, shape)
                fixture:setUserData("prize")
                prizeStaticBody = body
            end
            isCarryingPrize = false
            playerBody:setPosition(playerStartPos.x, playerStartPos.y)
            playerBody:setLinearVelocity(0, 0)
            for i = 1, #movingObjects do
                movingObjects[i].body:setPosition(movingObjects[i].startX, movingObjects[i].startY)
                movingObjects[i].body:setLinearVelocity(0, 0)
            end
        end
    end
end

function methods.beginContact(a, b, coll)
    local dataA = a:getUserData()
    local dataB = b:getUserData()

    if (dataA == "player" and dataB == "planet") or
       (dataA == "planet" and dataB == "player") or 
       (dataA == "player" and dataB == "blackhole") or 
       (dataA == "blackhole" and dataB == "player") then
        loseHealth()
    elseif  (dataA == "prize" and dataB == "blackhole") or 
            (dataA == "blackhole" and dataB == "prize") or 
            (dataA == "prize" and dataB == "planet") or
            (dataA == "planet" and dataB == "prize") then
                loseHealth()
    elseif (dataA == "player" and dataB == "prize") or
        (dataA == "prize" and dataB == "player") then
            toBeSpawned = true
    elseif (dataA == "player" and dataB == "home") or
        (dataA == "home" and dataB == "player") then
            -- Game over logic here
            if isCarryingPrize then
                areYouWinningSon = true
                isGameRunning = false
                restartState = true
            end
    end

end

function loseHealth()
    if gameTime - lastHpLoseTime > 1 then
        playerHp = playerHp - 1
        lastHpLoseTime = gameTime
    end

    if playerHp <= 0 then
        isGameRunning = false
        restartState = true
        lastHpLoseTime = 0
        playerInput.x = 0
        playerInput.y = 0
    end
end

function jointTriggered()
    local prizeX, prizeY = playerBody:getPosition()
    prizeBody = love.physics.newBody(world, prizeX, prizeY, "dynamic")
    prizeShape = love.physics.newCircleShape(10) -- Adjust the size as needed
    prizeFixture = love.physics.newFixture(prizeBody, prizeShape, 1)
    prizeFixture:setUserData("prize")

    joint = love.physics.newDistanceJoint(
        playerBody, 
        prizeBody, 
        playerBody:getX(), playerBody:getY(),
        prizeBody:getX(), prizeBody:getY(),
        false -- don't collide with each other
    )
    joint:setDampingRatio(1)
    joint:setFrequency(0.9)
    isCarryingPrize = true   
    methods.level[19][172] = 0

    prizeStaticBody:destroy()
    prizeStaticBody = nil

end

function love.load()
    love.window.setMode(1280, 720, { vsync = true })
    world = love.physics.newWorld(0, 0, true)
    world:setCallbacks(methods.beginContact, endContact)

    -- Create an empty methods.level grid
    methods.initLevel()

    -- Load the tileset image
    tileset = love.graphics.newImage("assets/tilemapTest2.png")
    backgroundImage = love.graphics.newImage("assets/tempBackground.png")
    backgroundImage:setWrap("repeat", "repeat")

    destinationImage = love.graphics.newImage("assets/destination.png")

    -- Create quads (parts of the tileset image)
    for i = 0, 3 do
        for j = 0, 3 do
            quads[i * 4 + j + 1] = love.graphics.newQuad(j * TILE_SIZE, i * TILE_SIZE, TILE_SIZE, TILE_SIZE, tileset:getDimensions())
        end
    end

    methods.level = methods.loadTilemap()
    -- assign newBody to each tile that is not 0
    local planetcount = 0
    local blackholeCount = 0
    local movingObjectCount = 0
    planets = {}
    for y = 1, methods.gridHeight do
        for x = 1, methods.gridWidth do
            local tile = methods.level[y][x]
            if tile == 2 then
                local body = love.physics.newBody(world, (x - 1) * TILE_SIZE + TILE_SIZE / 2, (y - 1) * TILE_SIZE + TILE_SIZE / 2, "dynamic")
                local shape = love.physics.newRectangleShape(TILE_SIZE/2, TILE_SIZE/2)
                local fixture = love.physics.newFixture(body, shape)
                body:setGravityScale( 0 )
                fixture:setUserData("movingObject")
                -- add the body to the movingObjects table
                table.insert(movingObjects, body)
                movingObjectCount = movingObjectCount + 1
                movingObjects[movingObjectCount] = {
                    body = body,
                    shape = shape,
                    fixture = fixture,
                    speed = 100, -- Speed of the moving object
                    tileType = 2, -- 1 for right, -1 for left
                    startX = body:getX(),
                    startY = body:getY(),
                    destinationX = body:getX() + 300,
                    destinationY = body:getY() + 300
                }
            elseif tile ~= 0 then
                local body = love.physics.newBody(world, (x - 1) * TILE_SIZE + TILE_SIZE / 2, (y - 1) * TILE_SIZE + TILE_SIZE / 2, "static")
                local shape = love.physics.newRectangleShape(TILE_SIZE, TILE_SIZE)
                local fixture = love.physics.newFixture(body, shape)
                if tile == 1 then
                    fixture:setUserData("planet")
                elseif tile == 9 then
                    fixture:setUserData("prize")
                    prizeStaticBody = body
                elseif tile == 3 or tile == 4 or tile == 7 or tile == 8 then
                    fixture:setUserData("home")
                elseif tile == 5 then
                    fixture:setUserData("blackhole")
                else
                    fixture:setUserData("object")
                end
            end
            if tile == 1 then
                planetcount = planetcount + 1
                planets[planetcount] = {
                    x = (x - 1) * TILE_SIZE + TILE_SIZE / 2,
                    y = (y - 1) * TILE_SIZE + TILE_SIZE / 2,
                }

            end

            if tile == 5 then
                blackholeCount = blackholeCount + 1
                blackholes[blackholeCount] = {
                    x = (x - 1) * TILE_SIZE + TILE_SIZE / 2,
                    y = (y - 1) * TILE_SIZE + TILE_SIZE / 2,
                }

            end
        end
    end



    -- Set the initial position of the circle
    playerStats = {
        x = playerStartPos.x,  -- Center of the screen (assuming 800x600 resolution)
        y = playerStartPos.y,
        speed = 200  -- Movement speed in pixels per second
    }

    -- Create player body
    playerBody = love.physics.newBody(world, playerStats.x, playerStats.y, "dynamic")
    -- Create player shape as a rectangle
    playerShape = love.physics.newRectangleShape(50, 50)
    -- Create fixture for the player body
    playerFixture = love.physics.newFixture(playerBody, playerShape)
    playerFixture:setUserData("player")

    testPlayer = love.graphics.newImage("assets/playerShip.png")

    
    
    -- Create a flame-like image
    local flame = love.image.newImageData(1, 1)
    flame:setPixel(0, 0, 1, 1, 1, 1) -- white
    flameImg = love.graphics.newImage(flame)

    -- Create particle system
    thruster = love.graphics.newParticleSystem(flameImg, 100)
    thruster:setParticleLifetime(0.2, 0.5)
    thruster:setEmissionRate(100)
    thruster:setSizes(2, 0) -- shrink to 0
    thruster:setColors(1, 0.5, 0, 1, 1, 1, 0, 0) -- orange to transparent
    thruster:setSpread(math.rad(20))
    thruster:setSpeed(50, 150)
    thruster:setDirection(math.rad(180)) -- emit backward

    backgroundQuad = love.graphics.newQuad(0, 0, 1280*7, 720*5, backgroundImage:getWidth(), backgroundImage:getHeight())

end

function love.update(dt)
    local target_fps = 1 / 60
    local sleep_time = target_fps - dt
    if sleep_time > 0 then
        love.timer.sleep(sleep_time)
    end

    world:update(dt)
    thruster:update(dt)
    if isGameRunning then
        gameTime = gameTime + dt
            -- Update player position based on physics body
        playerStats.x, playerStats.y = playerBody:getPosition()

        -- Apply forces to the player body based on arrow key inputs
        local force = playerStats.speed * dt * 500
        if love.keyboard.isDown("right") then
            playerBody:applyForce(force, 0)
            thruster:emit(5)
            playerInput.y = -1
        elseif love.keyboard.isDown("left") then
            playerBody:applyForce(-force, 0)
            thruster:emit(5)
            playerInput.y = 1
        else
            playerInput.y = 0
        end

        if love.keyboard.isDown("down") then
            playerBody:applyForce(0, force)
            thruster:emit(5)
            playerInput.x = 1
        elseif love.keyboard.isDown("up") then
            playerBody:applyForce(0, -force)
            thruster:emit(5)
            playerInput.x = -1
        else
            playerInput.x = 0
        end
    end
    

    for i = 1, #movingObjects do
        local destX, destY = movingObjects[i].destinationX, movingObjects[i].destinationY
        local startX, startY = movingObjects[i].startX, movingObjects[i].startY
        local dx = destX - startX
        local dy = destY - startY
        if math.abs(movingObjects[i].body:getX() - startX) < 50 and math.abs(movingObjects[i].body:getY() - startY) < 50 then
            movingObjects[i].body:setLinearVelocity(dx/5,dy/5)
        end
        -- check if the moving object is at the destination
        if math.abs(movingObjects[i].body:getX() - destX) < 50 and math.abs(movingObjects[i].body:getY() - destY) < 50 then
            movingObjects[i].body:setLinearVelocity(-dx/5,-dy/5)
        end

    end

    -- Smooth camera movement with interpolation
    local cameraSpeed = 6 -- Adjust this value for the delay effect
    camera.x = camera.x + (playerStats.x - love.graphics.getWidth() / 2 * 10 / 8 - camera.x) * cameraSpeed * dt
    camera.y = camera.y + (playerStats.y - love.graphics.getHeight() / 2 * 10 / 8 - camera.y) * cameraSpeed * dt

    resetGravity()

    if toBeSpawned then
        jointTriggered()
        toBeSpawned = false
    end
end

function love.draw()
    

    local parallaxFactor = 0.3  -- Smaller = slower, feels further away

    local bgX = math.floor(-camera.x * parallaxFactor)
    local bgY = math.floor(-camera.y * parallaxFactor)

    -- Option 1: Using quad for a tiled image
    
    love.graphics.draw(backgroundImage, backgroundQuad, bgX, bgY)

    if prizeStaticBody then
        local prizeX, prizeY = prizeStaticBody:getPosition()
        local dx = prizeX - playerStats.x
        local dy = prizeY - playerStats.y
        local angle = math.atan2(dy, dx)

        local screenWidth = love.graphics.getWidth()
        local screenHeight = love.graphics.getHeight()
        local imageWidth = destinationImage:getWidth()
        local imageHeight = destinationImage:getHeight()

        local offsetX = math.cos(angle) * (screenWidth / 2 - imageWidth / 2)
        local offsetY = math.sin(angle) * (screenHeight / 2 - imageHeight / 2)

        love.graphics.draw(destinationImage, screenWidth / 2, screenHeight / 2 - 100, angle, 0.5, 0.5, imageWidth / 4, imageHeight / 4)
    end
    
    -- Apply camera transform
    love.graphics.push()
    love.graphics.scale(0.8, 0.8)

    love.graphics.translate(-camera.x, -camera.y)
    -- Draw placed tiles
    -- Find the input based rotation
    --- define the input based rotation based on the playerInput x and y values
    local inputBasedRotation = math.atan2(playerInput.y, playerInput.x) + math.pi / 2

    if playerInput.x == 0 and playerInput.y == 0  then
    else
        love.graphics.draw(thruster, playerStats.x + 8, playerStats.y + 8, inputBasedRotation, 5, 5, 0, 0)
    end

    for y = 1, methods.gridHeight do
        for x = 1, methods.gridWidth do
            local tile = methods.level[y][x]
            if tile ~= 0 and tile ~= 2 then
                love.graphics.draw(tileset, quads[tile], (x - 1) * TILE_SIZE, (y - 1) * TILE_SIZE)
            end
        end
    end

    for i = 1, #movingObjects do
        love.graphics.draw(tileset, quads[movingObjects[i].tileType], movingObjects[i].body:getX() - TILE_SIZE / 2, movingObjects[i].body:getY() - TILE_SIZE / 2)
    end

    if isCarryingPrize then
        -- draw the price object
        love.graphics.draw(tileset, quads[9], (prizeBody:getX() - TILE_SIZE / 2) + 50, (prizeBody:getY() - TILE_SIZE / 2) + 20, 0.5, 0.5)

        -- Draw a direct line between the player and the prize
        love.graphics.setColor(1, 0, 0, 1) -- Set color to red
        love.graphics.setLineWidth(10)
        love.graphics.line(playerBody:getX(), playerBody:getY(), prizeBody:getX(), prizeBody:getY())
        love.graphics.setColor(1, 1, 1, 1) -- Reset color to white
    end



    love.graphics.draw(testPlayer, playerBody:getX() - 25, playerBody:getY() - 25, nil, 0.5, 0.5)


    love.graphics.pop()
    -- print a text that says "BTW. You cant hear any sound in the space!" on top left corner of the screen
    love.graphics.setFont(love.graphics.newFont(20))
    love.graphics.print("BTW. You cant hear any sound in the space! It is totally for realism and all!", 10, 10)
    -- change color to light red
    love.graphics.setFont(love.graphics.newFont(40))
    love.graphics.setColor(1, 0.5, 0.5, 1)
    -- print the health number to the mid center bottom of the screen

    love.graphics.print("Lives: " .. playerHp, 600, 620)
    --reset color to white
    love.graphics.setColor(1, 1, 1, 1)

    -- Draw a label showing a text that says press enter for start the game
    local function drawCenteredText(text, y, fontSize, color)
        local font = love.graphics.newFont(fontSize)
        love.graphics.setFont(font)
        local textWidth = font:getWidth(text)
        local screenWidth = love.graphics.getWidth()
        love.graphics.setColor(color)
        love.graphics.print(text, (screenWidth - textWidth) / 2, y)
    end

    if isGameRunning == false and restartState == false then
        drawCenteredText("Press Enter to start the game", 50, 30, {1, 1, 1, 1})
    end

    drawCenteredText("Game Time: " .. string.format("%.2f", gameTime), 100, 20, {1, 1, 1, 1})

    if restartState and areYouWinningSon == false then
        drawCenteredText("Press Enter to restart the game", 50, 30, {1, 1, 1, 1})
    end

    if areYouWinningSon then
        drawCenteredText("You win!", 50, 40, {0, 1, 0, 1})
        -- reset the color
        love.graphics.setColor(1, 1, 1, 1)
    end

    if isCarryingPrize and isGameRunning then
        drawCenteredText("Return To The Home Planet!", 50, 30, {1, 1, 0, 1})
        love.graphics.setColor(1, 1, 1, 1)
    elseif isCarryingPrize == false and isGameRunning then
        drawCenteredText("Follow the arrow sign! Find and retrieve the power supply!", 50, 30, {1, 1, 0, 1})
        love.graphics.setColor(1, 1, 1, 1)
    end
    
end