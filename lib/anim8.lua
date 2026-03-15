local anim8 = {}

local function normalizeFrames(spec)
    local frames = {}

    if type(spec) == "number" then
        frames[1] = spec
        return frames
    end

    if type(spec) == "table" then
        for _, value in ipairs(spec) do
            if type(value) == "string" then
                local startFrame, endFrame = value:match("^(%d+)%-(%d+)$")
                if startFrame and endFrame then
                    startFrame = tonumber(startFrame)
                    endFrame = tonumber(endFrame)
                    local step = startFrame <= endFrame and 1 or -1
                    for frame = startFrame, endFrame, step do
                        frames[#frames + 1] = frame
                    end
                else
                    frames[#frames + 1] = tonumber(value)
                end
            else
                frames[#frames + 1] = value
            end
        end
        return frames
    end

    if type(spec) == "string" then
        local startFrame, endFrame = spec:match("^(%d+)%-(%d+)$")
        if startFrame and endFrame then
            startFrame = tonumber(startFrame)
            endFrame = tonumber(endFrame)
            local step = startFrame <= endFrame and 1 or -1
            for frame = startFrame, endFrame, step do
                frames[#frames + 1] = frame
            end
        else
            frames[1] = tonumber(spec)
        end
    end

    return frames
end

function anim8.newGrid(frameWidth, frameHeight, imageWidth, imageHeight, left, top, border)
    left = left or 0
    top = top or 0
    border = border or 0

    local grid = {
        frameWidth = frameWidth,
        frameHeight = frameHeight,
        imageWidth = imageWidth,
        imageHeight = imageHeight,
        left = left,
        top = top,
        border = border
    }

    return setmetatable(grid, {
        __call = function(self, xSpec, ySpec)
            local quads = {}
            local xs = normalizeFrames(xSpec)
            local ys = normalizeFrames(ySpec)

            for _, y in ipairs(ys) do
                for _, x in ipairs(xs) do
                    local quadX = self.left + (x - 1) * (self.frameWidth + self.border)
                    local quadY = self.top + (y - 1) * (self.frameHeight + self.border)
                    quads[#quads + 1] = love.graphics.newQuad(
                        quadX,
                        quadY,
                        self.frameWidth,
                        self.frameHeight,
                        self.imageWidth,
                        self.imageHeight
                    )
                end
            end

            return quads
        end
    })
end

function anim8.newAnimation(frames, durations)
    local animation = {
        frames = frames,
        durations = durations,
        position = 1,
        timer = 0
    }

    local function getFrameDuration(index)
        if type(animation.durations) == "table" then
            return animation.durations[index] or animation.durations[#animation.durations] or 0.1
        end
        return animation.durations or 0.1
    end

    function animation:clone()
        return anim8.newAnimation(self.frames, self.durations)
    end

    function animation:gotoFrame(index)
        self.position = math.max(1, math.min(index, #self.frames))
        self.timer = 0
    end

    function animation:update(dt)
        if #self.frames <= 1 then
            return
        end

        self.timer = self.timer + dt

        while self.timer >= getFrameDuration(self.position) do
            self.timer = self.timer - getFrameDuration(self.position)
            self.position = self.position + 1
            if self.position > #self.frames then
                self.position = 1
            end
        end
    end

    function animation:getFrameInfo()
        return self.frames[self.position], self.position
    end

    function animation:draw(image, x, y, r, sx, sy, ox, oy, kx, ky)
        love.graphics.draw(
            image,
            self.frames[self.position],
            x,
            y,
            r or 0,
            sx or 1,
            sy or 1,
            ox or 0,
            oy or 0,
            kx or 0,
            ky or 0
        )
    end

    return animation
end

return anim8
