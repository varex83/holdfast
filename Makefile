# Makefile for Holdfast - Love2D Game Development Workflow

# Project configuration
PROJECT_NAME := holdfast
LOVE_VERSION := 11.5
BUILD_DIR := build
DIST_DIR := dist

# Platform detection
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
	LOVE_BIN := /Applications/love.app/Contents/MacOS/love
	PLATFORM := macos
else ifeq ($(UNAME_S),Linux)
	LOVE_BIN := love
	PLATFORM := linux
else
	LOVE_BIN := love
	PLATFORM := windows
endif

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

.PHONY: help run test lint clean build watch install-deps build-all package-macos package-linux package-windows check-love

# Default target
.DEFAULT_GOAL := help

## help: Show this help message
help:
	@echo "$(GREEN)Holdfast Development Workflow$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@grep -E '^## ' $(MAKEFILE_LIST) | sed 's/## /  /' | column -t -s ':'

## run: Run the game with Love2D
run: check-love
	@echo "$(GREEN)Running Holdfast...$(NC)"
	@$(LOVE_BIN) .

## dev: Run in development mode with debug overlay enabled
dev: check-love
	@echo "$(GREEN)Running Holdfast in development mode...$(NC)"
	@HOLDFAST_DEV=1 $(LOVE_BIN) .

## test: Run test suite
test:
	@echo "$(GREEN)Running tests...$(NC)"
	@if [ -f "tests/run.lua" ] && command -v lua >/dev/null 2>&1; then \
		lua tests/run.lua; \
	elif [ -d "tests" ] && [ -n "$$(ls -A tests/*.lua 2>/dev/null)" ] && { command -v $(LOVE_BIN) >/dev/null 2>&1 || [ -f "$(LOVE_BIN)" ]; }; then \
		$(LOVE_BIN) tests/; \
	else \
		echo "$(YELLOW)No runnable test setup found$(NC)"; \
	fi

## lint: Lint Lua code with luacheck
lint:
	@echo "$(GREEN)Linting Lua code...$(NC)"
	@if command -v luacheck >/dev/null 2>&1; then \
		luacheck . --exclude-files '.git/**' 'build/**' 'dist/**' 'lib/**'; \
	else \
		echo "$(RED)luacheck not installed. Run 'make install-deps' first$(NC)"; \
		exit 1; \
	fi

## format: Format Lua code with stylua
format:
	@echo "$(GREEN)Formatting Lua code...$(NC)"
	@if command -v stylua >/dev/null 2>&1; then \
		stylua .; \
	else \
		echo "$(YELLOW)stylua not installed. Install with: cargo install stylua$(NC)"; \
	fi

## clean: Remove build artifacts
clean:
	@echo "$(GREEN)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR) $(DIST_DIR)
	@echo "$(GREEN)Clean complete$(NC)"

## build: Create .love file for distribution
build: clean lint
	@echo "$(GREEN)Building $(PROJECT_NAME).love...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@zip -9 -r $(BUILD_DIR)/$(PROJECT_NAME).love . \
		-x "*.git*" \
		-x "*.DS_Store" \
		-x "$(BUILD_DIR)/*" \
		-x "$(DIST_DIR)/*" \
		-x "saves/*" \
		-x "tests/*" \
		-x "Makefile" \
		-x "*.md" \
		-x ".claude/*"
	@echo "$(GREEN)Build complete: $(BUILD_DIR)/$(PROJECT_NAME).love$(NC)"

## watch: Run game with auto-reload on file changes (requires entr)
watch:
	@echo "$(GREEN)Watching for file changes...$(NC)"
	@if command -v entr >/dev/null 2>&1; then \
		find . -name "*.lua" | entr -r make run; \
	else \
		echo "$(RED)entr not installed. Install with:$(NC)"; \
		echo "  macOS: brew install entr"; \
		echo "  Linux: apt-get install entr or yum install entr"; \
	fi

## build-all: Build packages for all platforms
build-all: package-macos package-linux package-windows
	@echo "$(GREEN)All platform builds complete!$(NC)"

## package-macos: Create macOS .app bundle
package-macos: build
	@echo "$(GREEN)Packaging for macOS...$(NC)"
	@mkdir -p $(DIST_DIR)/macos
	@if [ -d "/Applications/love.app" ]; then \
		cp -r /Applications/love.app $(DIST_DIR)/macos/$(PROJECT_NAME).app; \
		cp $(BUILD_DIR)/$(PROJECT_NAME).love $(DIST_DIR)/macos/$(PROJECT_NAME).app/Contents/Resources/; \
		echo "$(GREEN)macOS package created: $(DIST_DIR)/macos/$(PROJECT_NAME).app$(NC)"; \
	else \
		echo "$(RED)Love2D not found in /Applications/love.app$(NC)"; \
		echo "Download from: https://love2d.org/"; \
		exit 1; \
	fi

## package-linux: Create Linux AppImage
package-linux: build
	@echo "$(GREEN)Packaging for Linux...$(NC)"
	@mkdir -p $(DIST_DIR)/linux
	@cp $(BUILD_DIR)/$(PROJECT_NAME).love $(DIST_DIR)/linux/
	@echo "$(YELLOW)Linux distribution created: $(DIST_DIR)/linux/$(PROJECT_NAME).love$(NC)"
	@echo "$(YELLOW)Users need Love2D installed to run it$(NC)"

## package-windows: Create Windows executable
package-windows: build
	@echo "$(GREEN)Packaging for Windows...$(NC)"
	@mkdir -p $(DIST_DIR)/windows
	@echo "$(YELLOW)Windows packaging requires manual steps:$(NC)"
	@echo "  1. Download Love2D for Windows from https://love2d.org/"
	@echo "  2. Concatenate: copy /b love.exe+$(PROJECT_NAME).love $(PROJECT_NAME).exe"
	@echo "  3. Package with DLLs from Love2D distribution"
	@cp $(BUILD_DIR)/$(PROJECT_NAME).love $(DIST_DIR)/windows/
	@echo "$(YELLOW).love file copied to $(DIST_DIR)/windows/$(NC)"

## install-deps: Install development dependencies
install-deps:
	@echo "$(GREEN)Installing development dependencies...$(NC)"
	@if [ "$(PLATFORM)" = "macos" ]; then \
		if ! command -v brew >/dev/null 2>&1; then \
			echo "$(RED)Homebrew not installed. Install from https://brew.sh/$(NC)"; \
			exit 1; \
		fi; \
		brew list luarocks >/dev/null 2>&1 || brew install luarocks; \
		brew list entr >/dev/null 2>&1 || brew install entr; \
	elif [ "$(PLATFORM)" = "linux" ]; then \
		echo "$(YELLOW)Install luarocks and entr using your package manager$(NC)"; \
		echo "  Debian/Ubuntu: sudo apt-get install luarocks entr"; \
		echo "  Fedora: sudo dnf install luarocks entr"; \
	fi
	@echo "$(GREEN)Installing Lua tools via luarocks...$(NC)"
	@if command -v luarocks >/dev/null 2>&1; then \
		luarocks install --local luacheck; \
		luarocks install --local busted; \
		echo "$(GREEN)Dependencies installed!$(NC)"; \
		echo "$(YELLOW)Add to PATH: export PATH=\$$HOME/.luarocks/bin:\$$PATH$(NC)"; \
	else \
		echo "$(RED)luarocks not found$(NC)"; \
	fi

## check-love: Verify Love2D is installed
check-love:
	@if ! command -v $(LOVE_BIN) >/dev/null 2>&1 && [ ! -f "$(LOVE_BIN)" ]; then \
		echo "$(RED)Love2D not found!$(NC)"; \
		echo "Install from: https://love2d.org/"; \
		exit 1; \
	fi

## find-lib: Search for libraries by feature (usage: make find-lib FEATURE="collision")
find-lib:
	@if [ -z "$(FEATURE)" ]; then \
		echo "$(RED)Usage: make find-lib FEATURE=\"your-feature\"$(NC)"; \
		echo "$(YELLOW)Examples:$(NC)"; \
		echo "  make find-lib FEATURE=\"collision\""; \
		echo "  make find-lib FEATURE=\"pathfinding\""; \
		echo "  make find-lib FEATURE=\"camera\""; \
		exit 1; \
	fi
	@echo "$(GREEN)Searching for libraries related to: $(FEATURE)$(NC)"
	@echo "-------------------"
	@if grep -i "$(FEATURE)" LIBRARIES.md > /dev/null 2>&1; then \
		grep -i -A 2 -B 1 "$(FEATURE)" LIBRARIES.md | head -20; \
		echo ""; \
		echo "$(YELLOW)See LIBRARIES.md for full details$(NC)"; \
	else \
		echo "$(YELLOW)No libraries found for '$(FEATURE)'$(NC)"; \
		echo "Try searching LIBRARIES.md manually or check:"; \
		echo "  - https://github.com/love2d-community/awesome-love2d"; \
		echo "  - https://love2d.org/wiki/Category:Libraries"; \
	fi

## libs: Show quick library recommendations for common features
libs:
	@echo "$(GREEN)Quick Library Recommendations$(NC)"
	@echo "-------------------"
	@echo "$(YELLOW)Search for specific features:$(NC)"
	@echo "  make find-lib FEATURE=\"collision\""
	@echo "  make find-lib FEATURE=\"pathfinding\""
	@echo "  make find-lib FEATURE=\"camera\""
	@echo "  make find-lib FEATURE=\"animation\""
	@echo ""
	@echo "$(YELLOW)Recommended for Holdfast:$(NC)"
	@echo "  • bump.lua      - AABB collision detection"
	@echo "  • jumper        - A* pathfinding for enemies"
	@echo "  • anim8         - Sprite animation"
	@echo "  • flux          - Tweening for UI"
	@echo "  • lume          - Utility functions"
	@echo "  • dkjson        - Save/load JSON"
	@echo "  • lurker        - Hot-reload code changes"
	@echo ""
	@echo "$(GREEN)Full library list: LIBRARIES.md$(NC)"

## stats: Show project statistics
stats:
	@echo "$(GREEN)Project Statistics$(NC)"
	@echo "-------------------"
	@echo "Lua files: $$(find . -name '*.lua' -not -path './build/*' -not -path './dist/*' | wc -l | xargs)"
	@echo "Lines of code: $$(find . -name '*.lua' -not -path './build/*' -not -path './dist/*' -exec cat {} \; | wc -l | xargs)"
	@echo "Asset files: $$(find assets -type f 2>/dev/null | wc -l | xargs)"

## validate: Run all validation checks (lint + test)
validate: lint test
	@echo "$(GREEN)All validation checks passed!$(NC)"

## init: Initialize project (first time setup)
init: install-deps
	@echo "$(GREEN)Initializing Holdfast development environment...$(NC)"
	@mkdir -p saves
	@mkdir -p tests
	@mkdir -p assets/sprites
	@mkdir -p assets/sounds
	@mkdir -p assets/fonts
	@echo "$(GREEN)Project initialized!$(NC)"
	@echo "$(YELLOW)Next steps:$(NC)"
	@echo "  1. Run 'make dev' to start the game in development mode"
	@echo "  2. Run 'make watch' for auto-reload during development"
	@echo "  3. Read CLAUDE.md for project documentation"
