-- Component Manager
-- Components are pure data attached to entities

local Component = {}

-- Create a new component type
-- @param name: string - Component type name
-- @param defaults: table - Default values
-- @return constructor: function - Component constructor
function Component.create(name, defaults)
    return function(data)
        local component = {
            type = name,
            entity = nil  -- Set when attached to entity
        }

        -- Apply defaults
        if defaults then
            for k, v in pairs(defaults) do
                component[k] = v
            end
        end

        -- Apply provided data
        if data then
            for k, v in pairs(data) do
                component[k] = v
            end
        end

        return component
    end
end

return Component
