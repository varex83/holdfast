-- Love2D Configuration
function love.conf(t)
    t.identity = "holdfast"
    t.version = "11.5"
    t.console = false

    t.window.title = "Holdfast"
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = false
    t.window.vsync = 1
    t.window.msaa = 0

    t.modules.joystick = true
    t.modules.physics = false  -- Not using Box2D physics
end
