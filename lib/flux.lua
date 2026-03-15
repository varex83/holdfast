local flux = {}

local easing = {
    linear = function(t)
        return t
    end,
    quadout = function(t)
        return 1 - (1 - t) * (1 - t)
    end,
    quadinout = function(t)
        if t < 0.5 then
            return 2 * t * t
        end
        return 1 - ((-2 * t + 2) ^ 2) / 2
    end
}

local Tween = {}
Tween.__index = Tween

function Tween:new(group, obj, duration, vars)
    local startValues = {}
    for key, target in pairs(vars) do
        startValues[key] = obj[key]
        if startValues[key] == nil then
            startValues[key] = target
        end
    end

    return setmetatable({
        group = group,
        obj = obj,
        duration = math.max(duration or 0, 0.000001),
        vars = vars,
        startValues = startValues,
        elapsed = 0,
        delayTime = 0,
        easeFn = easing.linear,
        complete = nil
    }, Tween)
end

function Tween:delay(seconds)
    self.delayTime = math.max(seconds or 0, 0)
    return self
end

function Tween:ease(nameOrFunction)
    if type(nameOrFunction) == "function" then
        self.easeFn = nameOrFunction
    elseif type(nameOrFunction) == "string" then
        self.easeFn = easing[nameOrFunction:lower()] or self.easeFn
    end
    return self
end

function Tween:oncomplete(callback)
    self.complete = callback
    return self
end

function Tween:update(dt)
    if self.delayTime > 0 then
        self.delayTime = self.delayTime - dt
        return false
    end

    self.elapsed = self.elapsed + dt
    local progress = math.min(self.elapsed / self.duration, 1)
    local eased = self.easeFn(progress)

    for key, target in pairs(self.vars) do
        local startValue = self.startValues[key]
        self.obj[key] = startValue + (target - startValue) * eased
    end

    if progress >= 1 then
        if self.complete then
            self.complete()
        end
        return true
    end

    return false
end

local Group = {}
Group.__index = Group

function Group:to(obj, duration, vars)
    local tween = Tween:new(self, obj, duration, vars)
    self.tweens[#self.tweens + 1] = tween
    return tween
end

function Group:update(dt)
    for i = #self.tweens, 1, -1 do
        if self.tweens[i]:update(dt) then
            table.remove(self.tweens, i)
        end
    end
end

function Group:stop(obj)
    for i = #self.tweens, 1, -1 do
        if self.tweens[i].obj == obj then
            table.remove(self.tweens, i)
        end
    end
end

function flux.group()
    return setmetatable({tweens = {}}, Group)
end

return flux
