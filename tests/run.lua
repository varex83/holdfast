package.path = table.concat({
    './?.lua',
    './?/init.lua',
    './src/?.lua',
    './src/?/init.lua',
    './lib/?.lua',
    package.path,
}, ';')

local function installLoveStub()
    if _G.love then
        return
    end

    local function noop() end
    _G.love = {
        graphics = {
            newFont = function(size)
                return {
                    getWidth = function(_, text) return #(tostring(text or '')) * math.max(1, math.floor((size or 12) / 2)) end,
                    getHeight = function() return size or 12 end,
                }
            end,
            setColor = noop,
            setFont = noop,
            print = noop,
            printf = noop,
            rectangle = noop,
            polygon = noop,
            circle = noop,
            line = noop,
            clear = noop,
            getWidth = function() return 1280 end,
            getHeight = function() return 720 end,
            getDimensions = function() return 1280, 720 end,
            push = noop,
            pop = noop,
            translate = noop,
            scale = noop,
        },
        mouse = {
            getPosition = function() return 0, 0 end,
        },
        timer = {
            getTime = function() return 0 end,
        },
        joystick = {
            getJoysticks = function() return {} end,
        },
        keyboard = {
            isDown = function() return false end,
        },
    }
end

installLoveStub()

local failures = 0
local testsRun = 0

local function fail(message)
    failures = failures + 1
    io.stderr:write('FAIL: ' .. message .. '\n')
end

local function assertEqual(actual, expected, message)
    if actual ~= expected then
        error(string.format('%s (expected %s, got %s)', message or 'values differ', tostring(expected), tostring(actual)), 2)
    end
end

local function assertTrue(value, message)
    if not value then
        error(message or 'expected truthy value', 2)
    end
end

local function test(name, fn)
    testsRun = testsRun + 1
    local ok, err = pcall(fn)
    if ok then
        io.write('PASS: ' .. name .. '\n')
    else
        fail(name .. ' -> ' .. tostring(err))
    end
end

test('EventBus supports instance publish/emit aliases', function()
    local EventBus = require('src.core.eventbus')
    local bus = EventBus.new()
    local seen = {}

    local id = bus:subscribe('tick', function(context, value)
        seen[#seen + 1] = context.label .. ':' .. value
    end, { label = 'ctx' })

    assertEqual(bus:publish('tick', 3), 1, 'publish should return delivered listener count')
    assertEqual(seen[1], 'ctx:3', 'context callback should receive payload')

    bus.emit('tick', 4)
    assertEqual(seen[2], 'ctx:4', 'bound emit alias should publish on the instance')
    assertTrue(bus:unsubscribe('tick', id), 'unsubscribe should acknowledge removal')
    assertEqual(bus:publish('tick', 5), 0, 'publish should not deliver after unsubscribe')
end)

test('EventBus static global helpers still work', function()
    local EventBus = require('src.core.eventbus')
    local received = nil
    local id = EventBus.on('global_event', function(payload)
        received = payload
    end)

    EventBus.emit('global_event', 42)
    assertEqual(received, 42, 'global emit should reach global subscriber')
    assertTrue(EventBus.off('global_event', id), 'global off should remove listener')
end)

test('StateMachine tracks transitions and lifecycle hooks', function()
    local StateMachine = require('src.core.statemachine')
    local EventBus = require('src.core.eventbus')
    local machine = StateMachine(EventBus.new())
    local calls = {}

    machine:addState('a', {
        enter = function(_, payload) calls[#calls + 1] = 'enter-a:' .. payload end,
        exit = function() calls[#calls + 1] = 'exit-a' end,
    })
    machine:addState('b', {
        enter = function() calls[#calls + 1] = 'enter-b' end,
        exit = function() calls[#calls + 1] = 'exit-b' end,
    })

    machine:setState('a', 'hello')
    machine:setState('b')

    assertEqual(machine:getCurrentState(), 'b', 'current state should update')
    assertEqual(machine:getPreviousState(), 'a', 'previous state should track last state')
    assertEqual(table.concat(calls, ','), 'enter-a:hello,exit-a,enter-b', 'state hooks should run in order')
end)

test('PhaseManager advances day and night correctly', function()
    local PhaseManager = require('src.world.phasemanager')
    local phases = PhaseManager({ dayLength = 10, nightLength = 4 })

    phases:reset()
    phases:transition(PhaseManager.PHASE.DAY)
    assertEqual(phases:getDayNumber(), 1, 'first transition to day should increment to day 1')
    assertEqual(phases:getTimeRemaining(), 10, 'day transition should reset day timer')

    assertTrue(not phases:update(3), 'phase should not transition before timer expires')
    assertTrue(phases:update(7), 'phase should request transition when timer expires exactly')

    phases:transition(PhaseManager.PHASE.NIGHT)
    assertTrue(phases:isNight(), 'night transition should switch phase')
    assertEqual(phases:getTimeRemaining(), 4, 'night timer should reset to night length')
end)

test('Inventory capacity limits additions and SupplyDepot withdraw is lossless', function()
    local Inventory = require('src.inventory.inventory')
    local SupplyDepot = require('src.inventory.supplydepot')

    local inventory = Inventory('warrior')
    assertEqual(inventory:add('wood', 10), 4, 'warrior inventory should cap wood by weight')
    assertEqual(inventory:count('wood'), 4, 'inventory should contain capped amount')
    assertEqual(inventory:totalWeight(), 8, 'inventory weight should reflect stored resources')

    local depot = SupplyDepot(0, 0)
    depot:add('stone', 5)

    local withdrew = depot:withdraw('stone', 5, inventory)
    assertEqual(withdrew, 0, 'withdraw should respect full inventory and avoid removing stock')
    assertEqual(depot:count('stone'), 5, 'depot stock should remain untouched when inventory cannot accept items')

    inventory:clear()
    withdrew = depot:withdraw('stone', 5, inventory)
    assertEqual(withdrew, 2, 'withdraw should add only what fits into inventory capacity')
    assertEqual(depot:count('stone'), 3, 'depot should keep remainder when inventory only partially accepts items')
    assertEqual(inventory:count('stone'), 2, 'inventory should receive actual withdrawn amount')
end)

test('DayPhase build mode starts from the current ghost tile', function()
    local DayPhase = require('src.world.dayphase')
    local phase = DayPhase({ publish = function() end })
    local worldState = {
        phaseManager = { getDayNumber = function() return 1 end },
        _ghostTile = function() return 4, 5 end,
    }

    phase:enter(worldState)
    phase:keypressed('b', worldState)

    local tx, ty = phase.buildGhost:cursorTile()
    assertTrue(phase.buildGhost:isActive(), 'build ghost should activate on build input')
    assertEqual(tx, 4, 'build ghost should start at current ghost tile x')
    assertEqual(ty, 5, 'build ghost should start at current ghost tile y')
end)

if failures > 0 then
    io.stderr:write(string.format('\n%d/%d tests failed\n', failures, testsRun))
    os.exit(1)
end

io.write(string.format('\nAll %d tests passed\n', testsRun))
