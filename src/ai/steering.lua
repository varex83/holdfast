local Steering = {}

local function normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length == 0 then
        return 0, 0
    end
    return x / length, y / length
end

function Steering.seek(position, target, maxSpeed)
    local dx = target.x - position.x
    local dy = target.y - position.y
    local nx, ny = normalize(dx, dy)
    return {
        x = nx * (maxSpeed or 1),
        y = ny * (maxSpeed or 1),
    }
end

function Steering.separate(actor, neighbors, desiredDistance)
    local steerX, steerY = 0, 0
    local count = 0
    desiredDistance = desiredDistance or 28

    for _, neighbor in ipairs(neighbors or {}) do
        if neighbor ~= actor and neighbor:isAlive() then
            local dx = actor.position.x - neighbor.position.x
            local dy = actor.position.y - neighbor.position.y
            local distance = math.sqrt(dx * dx + dy * dy)
            if distance > 0 and distance < desiredDistance then
                steerX = steerX + dx / distance
                steerY = steerY + dy / distance
                count = count + 1
            end
        end
    end

    if count == 0 then
        return {x = 0, y = 0}
    end

    local nx, ny = normalize(steerX / count, steerY / count)
    return {x = nx, y = ny}
end

function Steering.weightedBlend(behaviors)
    local x, y = 0, 0
    for _, behavior in ipairs(behaviors or {}) do
        x = x + (behavior.vector.x * behavior.weight)
        y = y + (behavior.vector.y * behavior.weight)
    end

    local nx, ny = normalize(x, y)
    return {x = nx, y = ny}
end

return Steering
