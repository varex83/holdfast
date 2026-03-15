-- src/net/wsthread.lua
-- WebSocket client running in a Love2D thread.
-- Communicates with the main thread via named channels:
--   ws_params  (main → thread, once)  : table {host, port, path}
--   ws_send    (main → thread, many)  : JSON string or "close"
--   ws_recv    (thread → main, many)  : table {type, [data|message]}

local socket = require("socket")
local bit    = require("bit")

local sendCh = love.thread.getChannel("ws_send")
local recvCh = love.thread.getChannel("ws_recv")
local params = love.thread.getChannel("ws_params"):demand()

-- ── Base64 ────────────────────────────────────────────────────────────────────

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64(data)
    local out = {}
    local len = #data
    local rem = len % 3

    for i = 1, len - rem, 3 do
        local b1, b2, b3 = data:byte(i), data:byte(i + 1), data:byte(i + 2)
        local n = b1 * 65536 + b2 * 256 + b3
        out[#out + 1] = B64:sub(math.floor(n / 262144) % 64 + 1,
                                 math.floor(n / 262144) % 64 + 1)
        out[#out + 1] = B64:sub(math.floor(n / 4096)   % 64 + 1,
                                 math.floor(n / 4096)   % 64 + 1)
        out[#out + 1] = B64:sub(math.floor(n / 64)     % 64 + 1,
                                 math.floor(n / 64)     % 64 + 1)
        out[#out + 1] = B64:sub(n % 64 + 1, n % 64 + 1)
    end

    if rem == 1 then
        local b1 = data:byte(len)
        out[#out + 1] = B64:sub(math.floor(b1 / 4) + 1,
                                  math.floor(b1 / 4) + 1)
        out[#out + 1] = B64:sub((b1 % 4) * 16 + 1, (b1 % 4) * 16 + 1)
        out[#out + 1] = "=="
    elseif rem == 2 then
        local b1, b2 = data:byte(len - 1), data:byte(len)
        out[#out + 1] = B64:sub(math.floor(b1 / 4) + 1,
                                  math.floor(b1 / 4) + 1)
        out[#out + 1] = B64:sub((b1 % 4) * 16 + math.floor(b2 / 16) + 1,
                                  (b1 % 4) * 16 + math.floor(b2 / 16) + 1)
        out[#out + 1] = B64:sub((b2 % 16) * 4 + 1, (b2 % 16) * 4 + 1)
        out[#out + 1] = "="
    end

    return table.concat(out)
end

local function randomKey()
    local bytes = {}
    for i = 1, 16 do bytes[i] = string.char(math.random(0, 255)) end
    return base64(table.concat(bytes))
end

-- ── WebSocket framing ─────────────────────────────────────────────────────────

local function xorMask(payload, mask)
    local out = {}
    for i = 1, #payload do
        out[i] = string.char(bit.bxor(payload:byte(i), mask[((i - 1) % 4) + 1]))
    end
    return table.concat(out)
end

-- Encode a client→server frame (always masked per RFC 6455).
local function encodeFrame(payload, opcode)
    opcode = opcode or 1  -- TEXT
    local len = #payload
    local mask = {
        math.random(0, 255), math.random(0, 255),
        math.random(0, 255), math.random(0, 255),
    }
    local hdr = {}
    hdr[1] = string.char(0x80 + opcode)  -- FIN + opcode

    if len <= 125 then
        hdr[2] = string.char(0x80 + len)
    elseif len <= 65535 then
        hdr[2] = string.char(0x80 + 126)
        hdr[3] = string.char(math.floor(len / 256))
        hdr[4] = string.char(len % 256)
    else
        hdr[2] = string.char(0x80 + 127)
        for i = 1, 4 do hdr[2 + i] = string.char(0) end  -- high 4 bytes = 0
        hdr[7] = string.char(math.floor(len / 16777216) % 256)
        hdr[8] = string.char(math.floor(len / 65536)   % 256)
        hdr[9] = string.char(math.floor(len / 256)     % 256)
        hdr[10] = string.char(len % 256)
    end

    hdr[#hdr + 1] = string.char(mask[1])
    hdr[#hdr + 1] = string.char(mask[2])
    hdr[#hdr + 1] = string.char(mask[3])
    hdr[#hdr + 1] = string.char(mask[4])

    return table.concat(hdr) .. xorMask(payload, mask)
end

-- Buffered reader --
local recvBuf = ""

local function bufRead(tcp, n)
    while #recvBuf < n do
        local data, err, partial = tcp:receive(n - #recvBuf)
        local chunk = data or partial or ""
        recvBuf = recvBuf .. chunk
        if err and err ~= "timeout" then return nil, err end
    end
    local result = recvBuf:sub(1, n)
    recvBuf = recvBuf:sub(n + 1)
    return result
end

-- Try to receive one WebSocket frame.
-- Returns opcode, payload on success.
-- Returns nil, nil, "timeout" if no data available yet.
-- Returns nil, nil, err on connection error.
local function recvFrame(tcp)
    -- Non-blocking peek: bail out immediately if no data
    if #recvBuf < 1 then
        local data, err, partial = tcp:receive(1)
        local chunk = data or partial or ""
        recvBuf = recvBuf .. chunk
        if err == "timeout" and #recvBuf == 0 then
            return nil, nil, "timeout"
        elseif err and err ~= "timeout" then
            return nil, nil, err
        end
    end

    -- Commit to reading the full frame header (2 bytes)
    local h, err = bufRead(tcp, 2)
    if not h then return nil, nil, err end

    local b1, b2 = h:byte(1), h:byte(2)
    local opcode = bit.band(b1, 0x0F)
    local masked  = bit.band(b2, 0x80) ~= 0
    local paylen  = bit.band(b2, 0x7F)

    if paylen == 126 then
        local ext, e = bufRead(tcp, 2)
        if not ext then return nil, nil, e end
        paylen = ext:byte(1) * 256 + ext:byte(2)
    elseif paylen == 127 then
        local ext, e = bufRead(tcp, 8)
        if not ext then return nil, nil, e end
        paylen = 0
        for i = 5, 8 do paylen = paylen * 256 + ext:byte(i) end
    end

    local maskKey = nil
    if masked then
        local mk, e = bufRead(tcp, 4)
        if not mk then return nil, nil, e end
        maskKey = { mk:byte(1), mk:byte(2), mk:byte(3), mk:byte(4) }
    end

    local payload = ""
    if paylen > 0 then
        local p, e = bufRead(tcp, paylen)
        if not p then return nil, nil, e end
        payload = maskKey and xorMask(p, maskKey) or p
    end

    return opcode, payload
end

-- ── HTTP Upgrade ──────────────────────────────────────────────────────────────

local function httpUpgrade(tcp, host, port, path)
    local key = randomKey()
    local req = table.concat({
        "GET " .. path .. " HTTP/1.1",
        "Host: " .. host .. ":" .. tostring(port),
        "Upgrade: websocket",
        "Connection: Upgrade",
        "Sec-WebSocket-Key: " .. key,
        "Sec-WebSocket-Version: 13",
        "", "",
    }, "\r\n")

    local _, err = tcp:send(req)
    if err then return nil, "send: " .. err end

    -- Read response headers until blank line
    local resp = ""
    for _ = 1, 100 do
        local line, e = tcp:receive("*l")
        if e then return nil, "recv: " .. e end
        resp = resp .. line
        if line == "" then break end
    end

    if not resp:find("101") then
        return nil, "upgrade failed: " .. resp:sub(1, 120)
    end
    return true
end

-- ── Main loop ─────────────────────────────────────────────────────────────────

local function run()
    local host = params.host
    local port = params.port
    local path = params.path

    local tcp = socket.tcp()
    tcp:settimeout(10)

    local ok, err = tcp:connect(host, port)
    if not ok then
        recvCh:push({ type = "error", message = "connect: " .. tostring(err) })
        return
    end

    ok, err = httpUpgrade(tcp, host, port, path)
    if not ok then
        recvCh:push({ type = "error", message = "upgrade: " .. tostring(err) })
        tcp:close()
        return
    end

    recvCh:push({ type = "connected" })
    tcp:settimeout(0.01)  -- 10 ms read timeout; keeps send queue responsive

    local running = true
    while running do
        -- Flush outgoing queue first
        local msg = sendCh:pop()
        while msg do
            if msg == "close" then
                tcp:send(encodeFrame("", 8))  -- CLOSE frame
                running = false
                break
            end
            tcp:send(encodeFrame(msg))
            msg = sendCh:pop()
        end
        if not running then break end

        -- Try to receive one frame
        local opcode, payload, ferr = recvFrame(tcp)
        if opcode then
            if opcode == 1 then        -- TEXT
                recvCh:push({ type = "message", data = payload })
            elseif opcode == 8 then    -- CLOSE
                running = false
            elseif opcode == 9 then    -- PING → PONG
                tcp:send(encodeFrame(payload, 10))
            end
        elseif ferr and ferr ~= "timeout" then
            recvCh:push({ type = "error", message = "recv: " .. ferr })
            running = false
        end
    end

    tcp:close()
    recvCh:push({ type = "disconnected" })
end

local ok, err = pcall(run)
if not ok then
    love.thread.getChannel("ws_recv"):push({ type = "error", message = tostring(err) })
end
