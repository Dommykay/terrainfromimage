love = require("love")

function love.load()
    RES_X = love.graphics.getWidth()
    RES_Y = love.graphics.getHeight()
    _G.font = love.graphics.newFont("Assets/Font/Jersey10-Regular.ttf", 24)
    love.window.setTitle("Terrain gen")
    love.graphics.setBackgroundColor(0,0,0)
    _G.resolution = 50
    _G.perspective = 300
    _G.size = 1
    _G.heightmap = {}
    heightmap.filepath = "Assets/Heightmap.png"
    heightmap.texture = love.graphics.newImage(heightmap.filepath)
    heightmap.data = love.image.newImageData(heightmap.filepath)
    heightmap.xpoints = {}
    heightmap.ypoints = {}
    heightmap.points3d = {}
    heightmap.screenspacepoints = {}
    heightmap.screenspacepolypoints = {}

    love.graphics.setPointSize(3)
    love.graphics.setLineStyle("smooth")

    GenerateCoords(math.floor(resolution))
    GeneratePoints()
    GenerateScreenPoints()
    ConvertTo2DList()

end

function love.resize(w,h)
    RES_X = w
    RES_Y = h
end


function GenerateCoords(resolution)

    local width = heightmap.data:getWidth()
    heightmap.xpoints = {}
    for i=1,resolution-1 do
        table.insert(heightmap.xpoints,(width/(resolution-1))*(i-1))
    end
    table.insert(heightmap.xpoints, width-1)

    local height = heightmap.data:getHeight()
    heightmap.ypoints = {}
    for i=1,resolution-1 do
        table.insert(heightmap.ypoints,(height/resolution-1)*(i-1))
    end
    table.insert(heightmap.ypoints, height-1)

end


function GeneratePoints()
    heightmap.points3d = {}
    for pointx=1,#heightmap.xpoints do
        for pointy=1,#heightmap.ypoints do
            local r, g, b = heightmap.data:getPixel(heightmap.xpoints[pointx], heightmap.ypoints[pointy])
            local col = ((r + g + b)/3)*math.max(heightmap.xpoints[#heightmap.xpoints],heightmap.ypoints[#heightmap.ypoints]) 
            table.insert(heightmap.points3d, {heightmap.xpoints[pointx],heightmap.ypoints[pointy],col})
        end
    end
end

function love.update(dt)
    heightmap.xpoints = {}
    heightmap.ypoints = {}
    heightmap.points3d = {}
    heightmap.screenspacepoints = {}
    heightmap.screenspacepolypoints = {}
    --resolution = resolution + math.sin(love.timer.getTime()*dt*15)/10
    if resolution < 3 then
        resolution = 3
    end
    IncrementResolution()
    if love.keyboard.isDown("up") then
        perspective = perspective / (1+dt)
    end
    if love.keyboard.isDown("down") then
        perspective = perspective * (1+dt)
    end
    if love.keyboard.isDown("1") then
        heightmap.filepath = "Assets/Heightmap.png"
        heightmap.texture = love.graphics.newImage(heightmap.filepath)
        heightmap.data = love.image.newImageData(heightmap.filepath)
    end
    if love.keyboard.isDown("2") then
        heightmap.filepath = "Assets/Heightmap2.png"
        heightmap.texture = love.graphics.newImage(heightmap.filepath)
        heightmap.data = love.image.newImageData(heightmap.filepath)
    end
end

function ApplyModifiers(x, z, y)
    perspective = math.max(perspective,0.5)
    x = x / (1 + y/math.max(perspective,0.5))
    z = z / (1 + y/math.max(perspective,0.5))
    return x, z
end

function CenterOrigin(coordinates,brightness_mult)
    local x = coordinates[1] - (math.max(unpack(heightmap.xpoints))/2)
    local z = -coordinates[3]/(brightness_mult/150) + (math.max(unpack(heightmap.ypoints))/2)
    x, z = ApplyModifiers(x, z, coordinates[2])
    return x, z
end

function BackToTLOrigin(x,z)
    return x + RES_X/2, z + RES_Y/2
end

function GenerateScreenPoints()
    heightmap.screenspacepoints = {}
    for point=1, #heightmap.points3d do
        local brightness_mult = math.max(heightmap.xpoints[#heightmap.xpoints],heightmap.ypoints[#heightmap.ypoints])
        local brightness = math.sqrt(heightmap.points3d[point][3] / brightness_mult)
        local x, z = CenterOrigin(heightmap.points3d[point],brightness_mult)
        x, z = BackToTLOrigin(x,z)
        table.insert(heightmap.screenspacepoints, {math.floor(x)+0.5,math.floor(z-RES_X/6)+0.5,brightness,brightness,brightness})
    end
end


function RenderPoints()
    love.graphics.points(heightmap.screenspacepoints)
end

function ConvertTo2DList()
    heightmap.screenspacepolypoints = {}
    for z=#heightmap.ypoints-1,1,-1 do
        for x=1,#heightmap.xpoints-1 do
            local polygon = {{
                heightmap.screenspacepoints[z+(#heightmap.xpoints * (x-1))],
                heightmap.screenspacepoints[z+(#heightmap.xpoints * (x))],
                heightmap.screenspacepoints[z+(#heightmap.xpoints * (x-1) + 1)],
                },{
                heightmap.screenspacepoints[z+(#heightmap.xpoints * (x))],
                heightmap.screenspacepoints[z+(#heightmap.xpoints * (x-1) + 1)],
                heightmap.screenspacepoints[z+(#heightmap.xpoints * (x) + 1)],
            }}
            table.insert(heightmap.screenspacepolypoints, polygon[1])
            table.insert(heightmap.screenspacepolypoints, polygon[2])
        end
    end
end

function RenderPolygons()
    for polygonindex=1, #heightmap.screenspacepolypoints do
        local poly = heightmap.screenspacepolypoints[polygonindex]
        local r, g, b = 0, 0, 0
        for pointindex=1, #poly do
            local point = poly[pointindex]
            r, g, b = r + point[3], g + point[4], b + point[5]
        end
        r, g, b = r/3, g/3, b/3
        love.graphics.setColor(r, g, b, 1)
        love.graphics.polygon("fill", poly[1][1], poly[1][2], poly[2][1], poly[2][2], poly[3][1], poly[3][2])
    end
end
function IncrementResolution()
    GenerateCoords(resolution)
    GeneratePoints()
    GenerateScreenPoints()
    ConvertTo2DList()
end
function love.wheelmoved(x, y)
    resolution = resolution + y
end


function love.draw()
    love.graphics.setColor(1,1,1,1)
    
    love.graphics.draw(heightmap.texture, 0, 0, 0, 0.25,0.25)
    RenderPolygons()
    --RenderPoints()
    love.graphics.setColor(1,1,1,1)
    local resolution_text = {{1,1,1,1},string.format("The resolution is %s and the perspective is %s", resolution-1, perspective)}
    love.graphics.print(resolution_text, 0, RES_Y - 2*font:getHeight(), 0, 1.5, 1.5, 0, 0, 0, 0)
    love.graphics.print("Press 1 and 2 to switch between textures, scroll to change resolution and arrow keys to change perspective.", 0, RES_Y - font:getHeight(), 0, 1.5, 1.5, 0, 0, 0, 0)
end