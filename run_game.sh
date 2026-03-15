#!/bin/bash
# Quick launcher script for Holdfast

LOVE_PATH="/Users/bogdanogorodniy/Downloads/love.app/Contents/MacOS/love"

if [ -f "$LOVE_PATH" ]; then
    "$LOVE_PATH" .
else
    echo "Error: Love2D not found at $LOVE_PATH"
    echo "Please install Love2D or update the path in this script"
    exit 1
fi
