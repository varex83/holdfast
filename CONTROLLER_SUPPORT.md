# Controller Support

## Overview

Holdfast now supports gamepad controllers, with specific support for the **DualSense (PS5)** controller. The game automatically detects connected controllers and allows seamless switching between keyboard and gamepad input.

## Supported Controllers

- **DualSense (PlayStation 5)** - Full support
- Any SDL-compatible gamepad should work with standard button mappings

## Button Mappings (DualSense)

### Gameplay (Day State)

| Action | Keyboard | DualSense |
|--------|----------|-----------|
| Move | WASD | Left Stick |
| Camera | Mouse Wheel (zoom) | Right Stick (pan) |
| Skip to Night | Space | Triangle (△) |
| Open Menu | ESC | Circle (○) |

### Menu Navigation

| Action | Keyboard | DualSense |
|--------|----------|-----------|
| Navigate Up | Up Arrow | D-Pad Up |
| Navigate Down | Down Arrow | D-Pad Down |
| Select | Enter/Space | Cross (✕) |
| Back/Quit | ESC | Circle (○) |

### Night State

| Action | Keyboard | DualSense |
|--------|----------|-----------|
| Skip to Day | Space | Triangle (△) |
| Return to Menu | ESC | Circle (○) |

### Game Over

| Action | Keyboard | DualSense |
|--------|----------|-----------|
| Return to Menu | Enter/ESC | Cross (✕) or Circle (○) |

## Features

### Automatic Detection
- Controllers are automatically detected when connected
- Hot-swapping supported (plug/unplug during gameplay)
- Connection status shown in debug overlay (F1)

### Analog Movement
- Left stick provides smooth 360° movement
- Deadzone filtering prevents stick drift
- Movement automatically normalized for diagonal directions

### Vibration Support
The InputManager includes vibration functions for future use:
```lua
game.input:vibrate(leftMotor, rightMotor, duration)
game.input:stopVibration()
```

### Dual Input
- Keyboard and controller can be used simultaneously
- Gamepad input takes priority when analog stick is moved
- No need to switch input modes manually

### Dynamic UI Labels
- On-screen controls automatically update based on active input device
- When using keyboard: Shows "WASD: move", "SPACE: skip", etc.
- When using gamepad: Shows "Left Stick: move", "△: skip", etc.
- System detects which input was last used and updates prompts accordingly
- PlayStation button symbols (✕, ○, □, △) displayed for DualSense

## Debug Information

Press **F1** to toggle the debug overlay, which shows:
- Controller connection status
- Controller name/model
- Other debug information (FPS, memory, etc.)

## Implementation Details

### Input Manager
Location: `src/input/inputmanager.lua`

The InputManager provides a high-level abstraction over Love2D's input system:
- **getMoveVector()** - Returns normalized X/Y movement from keyboard or gamepad
- **isActionPressed(action)** - Check if an action is currently active
- **hasController()** - Check if a controller is connected
- **getControllerName()** - Get the name of the active controller

### Integration
All game states use the InputManager through `game.input`:
- **DayState** - Analog movement and button navigation
- **MenuState** - D-pad navigation and button selection
- **NightState** - Button shortcuts
- **GameOverState** - Button confirmation

## Future Enhancements

- [ ] Customizable button mappings
- [ ] Multiple controller support (local multiplayer)
- [ ] Rumble/haptic feedback during combat
- [x] ~~Right stick camera control~~ ✅ Implemented
- [ ] Trigger-based actions (L2/R2)
- [x] ~~On-screen button prompts that change based on active input device~~ ✅ Implemented
- [ ] Controller sensitivity settings
- [ ] Gyro support (DualSense motion controls)
- [ ] Adaptive triggers (DualSense haptic features)
- [ ] Controller-specific button icons (Xbox vs PlayStation)

## Troubleshooting

### Controller Not Detected

1. Ensure your controller is properly connected (USB or Bluetooth)
2. Check if Love2D recognizes it: `love.joystick.getJoysticks()`
3. Toggle the debug overlay (F1) to see connection status
4. Try disconnecting and reconnecting the controller

### Buttons Not Working

1. Verify the controller is recognized as a gamepad (SDL mapping)
2. Check if the controller appears in the debug overlay
3. Some generic controllers may need custom SDL mappings

### Stick Drift

The deadzone is set to 0.2 (20%) by default. If you experience drift:
```lua
game.input.deadzone = 0.3  -- Increase deadzone
```

## Technical Notes

### Love2D Callbacks
The following callbacks are now handled:
- `love.joystickadded(joystick)` - Controller connected
- `love.joystickremoved(joystick)` - Controller disconnected
- `love.gamepadpressed(joystick, button)` - Button pressed
- `love.gamepadreleased(joystick, button)` - Button released

### SDL2 Gamepad Mapping
Love2D uses SDL2 for controller support, which provides standardized button names:
- Face buttons: "a", "b", "x", "y"
- D-pad: "dpup", "dpdown", "dpleft", "dpright"
- Sticks: "leftx", "lefty", "rightx", "righty"
- Triggers: "triggerleft", "triggerright"
- Bumpers: "leftshoulder", "rightshoulder"

## Testing

To test controller support:

1. Connect a DualSense controller
2. Launch the game: `love .`
3. Press F1 to verify controller is detected
4. Navigate the menu with D-pad
5. Start a game and move with the left stick
6. Test all button mappings

## Contributing

When adding new actions or states:
1. Add keyboard mapping to `keyboardMap` in InputManager
2. Add gamepad mapping to `gamepadMap` in InputManager
3. Use `game.input:isActionPressed(action)` for continuous input
4. Implement `gamepadPressed(joystick, button)` callback in state for one-time events
5. Update this documentation with new mappings
