local Jumper = require("lib.jumper")

local Pathfinding = {}
Pathfinding.__index = Pathfinding

function Pathfinding.new(config)
    config = config or {}

    local self = setmetatable({}, Pathfinding)
    self.cellSize = config.cellSize or 64
    self.originX = config.originX or 0
    self.originY = config.originY or 0
    self.width = config.width or 20
    self.height = config.height or 15
    self.walkableValue = 1
    self.blockedValue = 0
    self.staticBlocked = {}
    self.dynamicBlocked = {}
    self.matrix = {}
    self.grid = nil
    self.finder = nil
    self:rebuild()

    return self
end

function Pathfinding:rebuild()
    self.matrix = {}

    for row = 1, self.height do
        self.matrix[row] = {}
        for col = 1, self.width do
            local key = row .. ":" .. col
            self.matrix[row][col] = (self.staticBlocked[key] or self.dynamicBlocked[key]) and self.blockedValue or self.walkableValue
        end
    end

    self.grid = Jumper.Grid(self.matrix)
    self.finder = Jumper.Pathfinder(self.grid, "ASTAR", self.walkableValue)
    self.finder:setMode("ORTHOGONAL")
end

function Pathfinding:setBlockedCell(col, row, blocked)
    local key = row .. ":" .. col
    if blocked == false then
        self.staticBlocked[key] = nil
    else
        self.staticBlocked[key] = true
    end
    self:rebuild()
end

function Pathfinding:setBlockedRect(col, row, width, height, blocked)
    for y = row, row + height - 1 do
        for x = col, col + width - 1 do
            self:setBlockedCell(x, y, blocked)
        end
    end
end

function Pathfinding:clearDynamicBlocks()
    self.dynamicBlocked = {}
    self:rebuild()
end

function Pathfinding:worldToGrid(x, y)
    local col = math.floor((x - self.originX) / self.cellSize) + 1
    local row = math.floor((y - self.originY) / self.cellSize) + 1
    return col, row
end

function Pathfinding:gridToWorld(col, row)
    local x = self.originX + (col - 0.5) * self.cellSize
    local y = self.originY + (row - 0.5) * self.cellSize
    return x, y
end

function Pathfinding:isWalkable(col, row)
    return col >= 1 and col <= self.width and row >= 1 and row <= self.height and self.matrix[row][col] == self.walkableValue
end

function Pathfinding:findPath(startCol, startRow, goalCol, goalRow)
    if not self:isWalkable(startCol, startRow) or not self:isWalkable(goalCol, goalRow) then
        return nil
    end

    local path = self.finder:getPath(startCol, startRow, goalCol, goalRow)
    if not path then
        return nil
    end

    local nodes = {}
    for col, row in path:nodes() do
        nodes[#nodes + 1] = {col = col, row = row}
    end

    return nodes
end

function Pathfinding:findPathWorld(startX, startY, goalX, goalY)
    local startCol, startRow = self:worldToGrid(startX, startY)
    local goalCol, goalRow = self:worldToGrid(goalX, goalY)
    local nodes = self:findPath(startCol, startRow, goalCol, goalRow)

    if not nodes then
        return nil
    end

    local waypoints = {}
    for _, node in ipairs(nodes) do
        local x, y = self:gridToWorld(node.col, node.row)
        waypoints[#waypoints + 1] = {x = x, y = y, col = node.col, row = node.row}
    end

    return waypoints
end

function Pathfinding:drawDebug()
    local alpha = 0.18
    for row = 1, self.height do
        for col = 1, self.width do
            local x = self.originX + (col - 1) * self.cellSize
            local y = self.originY + (row - 1) * self.cellSize

            if self.matrix[row][col] == self.blockedValue then
                love.graphics.setColor(0.7, 0.2, 0.2, alpha)
                love.graphics.rectangle("fill", x, y, self.cellSize, self.cellSize)
            end

            love.graphics.setColor(1, 1, 1, 0.12)
            love.graphics.rectangle("line", x, y, self.cellSize, self.cellSize)
        end
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Pathfinding
