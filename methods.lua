local methods = {}
methods.gridWidth = 180
methods.gridHeight = 40
methods.level = {}

function methods.initLevel()
    for y = 1, methods.gridHeight do
        methods.level[y] = {}
        for x = 1, methods.gridWidth do
            methods.level[y][x] = 0 -- 0 means empty
        end
    end
end

function resetGravity()
    -- Reset gravity to zero
    world:setGravity(0, 0)

    -- Loop through all the planets and add gravity to the player
    local playerX, playerY = playerBody:getPosition()
    for i = 1, #planets do
        local planetX = planets[i].x
        local planetY = planets[i].y

        -- Calculate distance to the player
        local distanceX = planetX - playerX
        local distanceY = planetY - playerY
        local distanceSquared = distanceX * distanceX + distanceY * distanceY

        -- Calculate gravity effect based on distance (example: inverse square law)
        local AddGravityX = 0
        local AddGravityY = 0

        if distanceSquared < 250 * 250 then
            AddGravityX = (distanceX) / math.sqrt(distanceSquared) * 250 -- Adjust the multiplier as needed
            AddGravityY = (distanceY) / math.sqrt(distanceSquared) * 250 -- Adjust the multiplier as needed
        end

        local gravityX, gravityY = world:getGravity()
        world:setGravity(gravityX + AddGravityX, gravityY + AddGravityY)
    end

    for i = 1, #blackholes do
        local blackholesX = blackholes[i].x
        local blackholesY = blackholes[i].y

        -- Calculate distance to the player
        local distanceX = blackholesX - playerX
        local distanceY = blackholesY - playerY
        local distanceSquared = distanceX * distanceX + distanceY * distanceY

        -- Calculate gravity effect based on distance (example: inverse square law)
        local AddGravityX = 0
        local AddGravityY = 0

        if distanceSquared < 450 * 450 then
            AddGravityX = (distanceX) / math.sqrt(distanceSquared) * 450 -- Adjust the multiplier as needed
            AddGravityY = (distanceY) / math.sqrt(distanceSquared) * 450 -- Adjust the multiplier as needed
        end

        local gravityX, gravityY = world:getGravity()
        world:setGravity(gravityX + AddGravityX, gravityY + AddGravityY)
    end
end



function methods.tableToString(tbl)
    local str = "{"
    for y = 1, #tbl do
        str = str .. "{"
        for x = 1, #tbl[y] do
            str = str .. tostring(tbl[y][x])
            if x < #tbl[y] then
                str = str .. ","
            end
        end
        str = str .. "}"
        if y < #tbl then
            str = str .. ","
        end
    end
    str = str .. "}"
    return str
end

function methods.saveTilemap(filename, tilemap)
    local data = "return " .. methods.tableToString(tilemap)
    love.filesystem.write(filename, data)
end

local level1file = require("assets/level1")

function methods.loadTilemap()
    -- Load the level1file module
    local filename = "assets/level1.lua"
    if love.filesystem.getInfo(filename) then
        local chunk = love.filesystem.load(filename)
        return chunk()
    else
        print("File not found: " .. filename)
        return nil
    end

end

return methods