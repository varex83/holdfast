-- Luacheck configuration for Holdfast Love2D project

-- Allow Love2D globals
std = "lua51+love"

-- Ignore warnings about line length
ignore = {
    "211", -- unused local variable
    "212", -- unused argument
    "213", -- unused loop variable
    "631", -- line is too long
}

-- Files and directories to exclude
exclude_files = {
    "build/**",
    "dist/**",
    ".git/**",
    ".luarocks/**",
    "lib/**",
}

-- Global variables to allow
globals = {
    "love",
}

-- Read-only globals
read_globals = {
    "love",
}

-- Maximum line length
max_line_length = 120

-- Maximum code complexity
max_cyclomatic_complexity = 15
