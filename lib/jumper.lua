local jumper = {}

local Grid = {}
Grid.__index = Grid

function Grid:new(matrix)
    return setmetatable({
        matrix = matrix,
        height = #matrix,
        width = matrix[1] and #matrix[1] or 0
    }, Grid)
end

function Grid:getNodeAt(x, y)
    if x < 1 or y < 1 or x > self.width or y > self.height then
        return nil
    end
    return {x = x, y = y}
end

function Grid:isWalkableAt(x, y, walkableValue)
    if x < 1 or y < 1 or x > self.width or y > self.height then
        return false
    end

    return self.matrix[y][x] == walkableValue
end

local Path = {}
Path.__index = Path

function Path:new(nodes)
    return setmetatable({points = nodes}, Path)
end

function Path:nodes()
    local index = 0
    return function()
        index = index + 1
        local node = self.points[index]
        if node then
            return node.x, node.y
        end
    end
end

local Pathfinder = {}
Pathfinder.__index = Pathfinder

local function heuristic(ax, ay, bx, by)
    return math.abs(ax - bx) + math.abs(ay - by)
end

local function reconstruct(cameFrom, currentKey, current)
    local nodes = {current}
    while cameFrom[currentKey] do
        current = cameFrom[currentKey]
        currentKey = current.y .. ":" .. current.x
        table.insert(nodes, 1, current)
    end
    return nodes
end

function Pathfinder:new(grid, _, walkableValue)
    return setmetatable({
        grid = grid,
        walkableValue = walkableValue or 1,
        mode = "ORTHOGONAL"
    }, Pathfinder)
end

function Pathfinder:setMode(mode)
    self.mode = mode or self.mode
end

function Pathfinder:getPath(startX, startY, goalX, goalY)
    local startNode = self.grid:getNodeAt(startX, startY)
    local goalNode = self.grid:getNodeAt(goalX, goalY)

    if not startNode or not goalNode then
        return nil
    end

    if not self.grid:isWalkableAt(goalX, goalY, self.walkableValue) then
        return nil
    end

    local openList = {
        {
            x = startNode.x,
            y = startNode.y,
            g = 0,
            h = heuristic(startNode.x, startNode.y, goalNode.x, goalNode.y)
        }
    }
    local openIndex = {[startNode.y .. ":" .. startNode.x] = true}
    local closed = {}
    local cameFrom = {}
    local gScore = {[startNode.y .. ":" .. startNode.x] = 0}
    local offsets = {
        {1, 0},
        {-1, 0},
        {0, 1},
        {0, -1}
    }

    if self.mode == "DIAGONAL" then
        offsets[#offsets + 1] = {1, 1}
        offsets[#offsets + 1] = {1, -1}
        offsets[#offsets + 1] = {-1, 1}
        offsets[#offsets + 1] = {-1, -1}
    end

    while #openList > 0 do
        table.sort(openList, function(a, b)
            return (a.g + a.h) < (b.g + b.h)
        end)

        local current = table.remove(openList, 1)
        local currentKey = current.y .. ":" .. current.x
        openIndex[currentKey] = nil

        if current.x == goalNode.x and current.y == goalNode.y then
            return Path:new(reconstruct(cameFrom, currentKey, {x = current.x, y = current.y}))
        end

        closed[currentKey] = true

        for _, offset in ipairs(offsets) do
            local nx = current.x + offset[1]
            local ny = current.y + offset[2]
            local neighborKey = ny .. ":" .. nx

            if not closed[neighborKey] and self.grid:isWalkableAt(nx, ny, self.walkableValue) then
                local stepCost = (offset[1] ~= 0 and offset[2] ~= 0) and 1.41421356237 or 1
                local tentativeG = current.g + stepCost

                if tentativeG < (gScore[neighborKey] or math.huge) then
                    cameFrom[neighborKey] = {x = current.x, y = current.y}
                    gScore[neighborKey] = tentativeG

                    if not openIndex[neighborKey] then
                        openList[#openList + 1] = {
                            x = nx,
                            y = ny,
                            g = tentativeG,
                            h = heuristic(nx, ny, goalNode.x, goalNode.y)
                        }
                        openIndex[neighborKey] = true
                    else
                        for _, node in ipairs(openList) do
                            if node.x == nx and node.y == ny then
                                node.g = tentativeG
                                node.h = heuristic(nx, ny, goalNode.x, goalNode.y)
                                break
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

jumper.Grid = setmetatable({}, {
    __call = function(_, matrix)
        return Grid:new(matrix)
    end
})

jumper.Pathfinder = setmetatable({}, {
    __call = function(_, grid, finder, walkableValue)
        return Pathfinder:new(grid, finder, walkableValue)
    end
})

return jumper
