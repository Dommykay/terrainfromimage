love = require("love")

function love.load()
    RES_X = love.graphics.getWidth()
    RES_Y = love.graphics.getHeight()
    love.graphics.setBackgroundColor(0,0,0)
    _G.resolution = 100
    heightmap = {}
    heightmap.filepath = "Assets/Heightmap.png"
    heightmap.texture = love.graphics.newImage(heightmap.filepath)
    heightmap.data = love.image.newImageData(heightmap.filepath)
    heightmap.xpoints = {}
    heightmap.ypoints = {}
    heightmap.points3d = {}
    heightmap.screenspacepoints = {}
    love.graphics.setPointSize(5)

    GenerateCoords()
    GeneratePoints()
    GenerateScreenPoints()

end

function love.resize(w,h)
    RES_X = w
    RES_Y = h
end


function GenerateCoords()

    local width = heightmap.data:getWidth()
    heightmap.xpoints = {}
    for i=1,resolution do
        print(math.floor((width/resolution)*(i-1)))
        table.insert(heightmap.xpoints,math.floor((width/resolution)*(i-1)))
    end

    local height = heightmap.data:getHeight()
    heightmap.ypoints = {}
    for i=1,resolution do
        table.insert(heightmap.ypoints,math.floor((height/resolution)*(i-1)))
    end
end


function GeneratePoints()
    heightmap.points3d = {}
    for pointx=1,#heightmap.xpoints do
        for pointy=1,#heightmap.ypoints do
            local r, g, b = heightmap.data:getPixel(pointx, pointy)
            local col = ((r + g + b)/3)*math.max(heightmap.xpoints[#heightmap.xpoints],heightmap.ypoints[#heightmap.ypoints]) 
            table.insert(heightmap.points3d, {heightmap.xpoints[pointx],heightmap.ypoints[pointy],col})
        end
    end
end

function love.update(dt)
end

function ApplyModifiers(x, z, y)
    x = x / (1 + y/250)
    z = z / (1 + y/250)
    return x, z
end

function CenterOrigin(coordinates)
    local x = coordinates[1] - (math.max(unpack(heightmap.xpoints))/2)
    local z = -coordinates[3]/3 + (math.max(unpack(heightmap.xpoints))/2)
    x, z = ApplyModifiers(x, z, coordinates[2])
    return x, z
end

function BackToTLOrigin(x,z)
    return x + RES_X/2, z + RES_Y/2
end

function GenerateScreenPoints()
    heightmap.screenspacepoints = {}
    for point=1, #heightmap.points3d do
        local brightness = math.sqrt(heightmap.points3d[point][3] / math.max(heightmap.xpoints[#heightmap.xpoints],heightmap.ypoints[#heightmap.ypoints]))
        local x, z = CenterOrigin(heightmap.points3d[point])
        x, z = BackToTLOrigin(x,z)
        table.insert(heightmap.screenspacepoints, {math.floor(x)+0.5,math.floor(z)+0.5,brightness,brightness,brightness})
    end
end


function RenderPoints()
    love.graphics.points({heightmap.screenspacepoints[1],heightmap.screenspacepoints[2]})
    love.graphics.points(heightmap.screenspacepoints)
end

function love.draw()
    --love.graphics.draw(heightmap.texture, 0, 0, 0, 0.25,0.25)
    RenderPoints()

end