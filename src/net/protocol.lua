-- src/net/protocol.lua
-- Message type constants mirroring holdfastbackend/internal/wsnet/protocol.go

local Protocol = {}

-- Client → Server
Protocol.INPUT     = "INPUT"
Protocol.HARVEST   = "HARVEST"
Protocol.DEPOSIT   = "DEPOSIT"
Protocol.BUILD     = "BUILD"
Protocol.WITHDRAW  = "WITHDRAW"
Protocol.REPAIR    = "REPAIR"
Protocol.SET_CLASS = "SET_CLASS"
Protocol.ABILITY   = "ABILITY"

-- Server → Client
Protocol.SNAPSHOT     = "SNAPSHOT"
Protocol.DELTA        = "DELTA"
Protocol.PHASE_CHANGE = "PHASE_CHANGE"
Protocol.WAVE_START   = "WAVE_START"
Protocol.GAME_OVER    = "GAME_OVER"
Protocol.CHUNK        = "CHUNK"
Protocol.ERROR        = "ERROR"

return Protocol
