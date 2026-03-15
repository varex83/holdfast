-- src/net/client.lua
-- Main-thread network interface.
-- Spawns wsthread.lua in a Love2D thread and exposes a simple API.
--
-- Usage:
--   local NetClient = require("src.net.client")
--   local net = NetClient.new()
--   net:connect("127.0.0.1", 8080, sessionId, playerName, class)
--   -- in love.update:
--   net:update()
--   -- send messages:
--   net:sendInput(dx, dy)
--   net:sendHarvest(nodeId)
--   net:sendDeposit()
--   net:sendBuild(tx, ty, buildingType)
--   -- listen:
--   net:on("SNAPSHOT", function(msg) ... end)

local json  = require("lib.dkjson")
local Proto = require("src.net.protocol")

local NetClient = {}
NetClient.__index = NetClient

function NetClient.new()
    return setmetatable({
        _thread    = nil,
        _connected = false,
        _handlers  = {},
        _sendCh    = love.thread.getChannel("ws_send"),
        _recvCh    = love.thread.getChannel("ws_recv"),
        _paramsCh  = love.thread.getChannel("ws_params"),
        playerID   = nil,   -- assigned from SNAPSHOT
    }, NetClient)
end

-- ── Connection ────────────────────────────────────────────────────────────────

function NetClient:connect(host, port, sessionId, playerName, class)
    local path = "/session/" .. sessionId .. "/join"
              .. "?name=" .. (playerName or "Player")
              .. "&class=" .. (class or "warrior")

    self._paramsCh:push({ host = host, port = port, path = path })
    self._thread = love.thread.newThread("src/net/wsthread.lua")
    self._thread:start()
end

function NetClient:disconnect()
    self._sendCh:push("close")
end

function NetClient:isConnected()
    return self._connected
end

-- ── Update (call every frame) ─────────────────────────────────────────────────

function NetClient:update()
    -- Check thread error
    if self._thread then
        local err = self._thread:getError()
        if err then
            print("[net] thread error: " .. err)
            self._thread = nil
        end
    end

    -- Drain receive channel
    local item = self._recvCh:pop()
    while item do
        if item.type == "connected" then
            self._connected = true
            print("[net] connected to server")

        elseif item.type == "disconnected" then
            self._connected = false
            print("[net] disconnected")

        elseif item.type == "error" then
            print("[net] error: " .. tostring(item.message))

        elseif item.type == "message" then
            local ok, msg = pcall(json.decode, item.data)
            if ok and msg and msg.type then
                -- Cache our own player ID from the snapshot
                if msg.type == Proto.SNAPSHOT and msg.player_id then
                    self.playerID = msg.player_id
                end
                local handler = self._handlers[msg.type]
                if handler then handler(msg) end
            end
        end

        item = self._recvCh:pop()
    end
end

-- ── Event registration ────────────────────────────────────────────────────────

function NetClient:on(msgType, handler)
    self._handlers[msgType] = handler
end

-- ── Send helpers ──────────────────────────────────────────────────────────────

function NetClient:_send(t)
    if not self._connected then return end
    self._sendCh:push(json.encode(t))
end

-- Movement input: dx, dy are the normalized tile-space direction
-- (same values used for local player movement).
function NetClient:sendInput(dx, dy)
    self:_send({ type = Proto.INPUT, dx = dx, dy = dy })
end

function NetClient:sendHarvest(nodeId)
    self:_send({ type = Proto.HARVEST, node_id = nodeId })
end

function NetClient:sendDeposit()
    self:_send({ type = Proto.DEPOSIT })
end

function NetClient:sendBuild(tileX, tileY, buildingType)
    self:_send({ type = Proto.BUILD, tile_x = tileX, tile_y = tileY, building = buildingType })
end

function NetClient:sendWithdraw(resource, amount)
    self:_send({ type = Proto.WITHDRAW, resource = resource, amount = amount })
end

function NetClient:sendRepair(buildingId)
    self:_send({ type = Proto.REPAIR, building_id = buildingId })
end

function NetClient:sendAbility(targetX, targetY)
    local msg = { type = Proto.ABILITY }
    if targetX then msg.target_x = targetX end
    if targetY then msg.target_y = targetY end
    self:_send(msg)
end

function NetClient:sendSetClass(class)
    self:_send({ type = Proto.SET_CLASS, class = class })
end

return NetClient
