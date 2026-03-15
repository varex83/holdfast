-- Luacheck configuration for Holdfast Love2D project

-- Love2D standard defines love.* fields; we assign to them (love.load etc.)
std = "lua51+love"

ignore = {
    "211", -- unused local variable
    "212", -- unused argument
    "213", -- unused loop variable
    "631", -- line is too long
    "141", -- setting read-only field (love.load, love.update etc. is normal Love2D)
    "142", -- mutating read-only field
}

exclude_files = {
    "build/**",
    "dist/**",
    ".git/**",
    ".luarocks/**",
    "lib/**",
}

globals = {
    "love",
}

-- Maximum line length
max_line_length = 120

-- Maximum code complexity
max_cyclomatic_complexity = 15
