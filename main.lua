local function clamp(n)
    return math.max(1, math.min(mapSize, n))
end

local function checkVal(n)
    if (n > 1.25) then
        return 1
    else
        return 0
    end
end

function remap()
    for xx = 1, mapSize do
        if Map[xx] == nil then
            Map[xx] = {}
            for yy = 1, mapSize do
                Map[xx][yy] = checkVal(love.math.random() * 2)
            end
        end
    end
end

local deg2rad = math.pi / 100

function redrawGrad()
    love.graphics.setCanvas(gradient)
    local halfy = math.floor(Resl[2] * 0.5)
    for i = 1, Resl[2] do
        local clr = (i - halfy) / halfy
        if clr < 0 then clr = -clr end
        love.graphics.setColor(clr * 0.4, clr * 0.4, 0)
        love.graphics.line(1, i, Resl[1], i)
    end
    love.graphics.setCanvas()
end

function redrawMinimap()
    love.graphics.setCanvas(minimap)
    for i = 1, mapSize do
        for j = 1, mapSize do
            if Map[i][j] == 1 then
                love.graphics.setColor(0.5,0.5,0,0.75)
            else
                love.graphics.setColor(0,0,0,0.25)
            end
            love.graphics.rectangle("fill", ((i - 1) * (2048 / mapSize)), ((j - 1) * (2048 / mapSize)), 2048 / mapSize, 2048 / mapSize)
        end
    end
    love.graphics.setColor(0.75, 0, 0)
    local plposx = ((posx - 1) * (2048 / mapSize))
    local plposy = ((posy - 1) * (2048 / mapSize))
    local offsetx = math.sin(dir * deg2rad) * 128
    local offsety = math.cos(dir * deg2rad) * 128
    love.graphics.line(plposx, plposy, plposx + offsetx, plposy + offsety)
    love.graphics.circle("fill", plposx, plposy, 32)
    love.graphics.setCanvas()
end

function love.load()
    Resl = {love.graphics.getWidth(), love.graphics.getHeight()}
    if Resl[1] < Resl[2] then
        sqs = Resl[1]
    else
        sqs = Resl[2]
    end
    Map = {}
    mapSize = 16
    fov = 75
    remap()
    time = 0
    speed = 0.25
    dir = 0
    posx = math.floor(mapSize * 0.5)
    posy = math.floor(mapSize * 0.5)
    Map[posx][posy] = 0
    accur = 1920
    walkK = 1 / (256 / mapSize)
    Keys = {
        {"left", function() dir = dir - 2.5; dir = dir % 200 end},
        {"right", function() dir = dir + 2.5; dir = dir % 200 end},
        {"up", function()
            local xo = (math.sin(dir * deg2rad) * walkK)
            local yo = (math.cos(dir * deg2rad) * walkK)
            local xopf = math.floor(posx + xo)
            local yf = math.floor(posy)
            local yopf = math.floor(posy + yo)
            if (Map[xopf] ~= nil and Map[xopf][yf] ~= 1 and xopf >= 1 and math.floor(xopf) <= mapSize) then
                posx = posx + xo
            end
            local xf = math.floor(posx)
            if (Map[xf] ~= nil and Map[xf][yopf] ~= 1 and yopf >= 1 and math.floor(yopf) <= mapSize) then
                posy = posy + yo
            end
        end},
        {"down", function()
            local xo = (math.sin(dir * deg2rad) * walkK)
            local yo = (math.cos(dir * deg2rad) * walkK)
            local xopf = math.floor(posx - xo)
            local yf = math.floor(posy)
            local yopf = math.floor(posy - yo)
            if (Map[xopf] ~= nil and Map[xopf][yf] ~= 1 and xopf >= 1 and math.floor(xopf) <= mapSize) then
                posx = posx - xo
            end
            local xf = math.floor(posx)
            if (Map[xf] ~= nil and Map[xf][yopf] ~= 1 and yopf >= 1 and math.floor(yopf) <= mapSize) then
                posy = posy - yo
            end
        end},
        {"u", function() print(posx, posy) end}
    }
    Colors = {
        ["INFO"] = {1, 1, 1},
        ["WARN"] = {1, 1, 0},
        ["ERR"] = {1, 0, 0}
    }
    debugInfo = {
        ["Pos"] = {"INFO", "Camera position: " .. posx .. " : " .. posy},
        ["Dir"] = {"INFO", "Camera direction: " .. dir},
        ["FPS"] = {"INFO", 0}
    }
    gradient = love.graphics.newCanvas(Resl[1], Resl[2])
    redrawGrad()
    minimap = love.graphics.newCanvas(2048, 2048)
    redrawMinimap()
end

function love.draw()
    love.graphics.draw(gradient)
    local multResl = 1 / (accur / mapSize)
    for i = 1, Resl[1] do
        local tx = posx
        local ty = posy
        local dist = 0
        local normCamX = 2 * i / Resl[1] - 1
        local d = (dir * deg2rad) + math.atan(normCamX * math.tan((fov * deg2rad) / 2.0));
        local stx = math.sin(d) * multResl
        local sty = math.cos(d) * multResl
        while true do
            if (tx > mapSize + 1 or tx < 1 or ty > mapSize + 1 or ty < 1) then
                break
            elseif (Map[math.floor(tx)] ~= nil and Map[math.floor(tx)][math.floor(ty)] == 1) then
                break
            end
            tx = tx + stx
            ty = ty + sty
            dist = dist + multResl
        end
        local clr = (1 - ((dist * 1.1) / mapSize))
        dist = dist * math.cos(d - (dir * deg2rad))
        local len = (Resl[2] / dist) * 0.75
        local y1 = (Resl[2] - len) * 0.5
        local y2 = y1 + len
        love.graphics.setColor(clr * 0.5, clr * 0.5, 0)
        love.graphics.line(i, y1, i, y2)
    end
    redrawMinimap()
    local minimapScale = (Resl[1] / 8) / 2048
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(minimap, Resl[1] - (2048 * minimapScale), 1, 0, minimapScale, minimapScale)
    love.graphics.setColor(1, 1, 1)
    local i = 0
    for _, v in pairs(debugInfo) do
        love.graphics.print(v[2], 1, (i * 12) + 1)
        i = i + 1
    end
end

function love.update(dt)
    for i, k in ipairs(Keys) do
        if (love.keyboard.isDown(k[1])) then
            k[2]()
        end
    end
    local fpsStatus = "INFO"
    local fps = love.timer.getFPS()
    if fps < 24 then
        fpsStatus = "ERR"
    elseif fps < 45 then
        fpsStatus = "WARN"
    end
    debugInfo["FPS"] = {fpsStatus, "FPS: " .. fps}
    debugInfo["Pos"] = {"INFO", "Camera position: " .. posx .. " : " .. posy}
    debugInfo["Dir"] = {"INFO", "Camera direction: " .. dir}
end

function love.resize(x, y)
    Resl = {x, y}
    if x < y then
        sqs = x
    else
        sqs = y
    end
    gradient = love.graphics.newCanvas(x, y)
    redrawGrad()
end

function love.keypressed(key, scancode, isrepeat)
    if key == "escape" or key == "q" then
        os.exit(0)
    end
end
