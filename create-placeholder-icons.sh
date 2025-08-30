#!/bin/bash

# Create simple placeholder PNG files for app icons
# This creates minimal PNG files that Xcode can recognize

# Function to create a simple PNG file
create_png() {
    local size=$1
    local filename=$2
    
    echo "Creating $filename (${size}x${size})"
    
    # Create a minimal PNG file with white background and simple design
    # This is a base64 encoded minimal PNG
    local png_data="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
    
    # Decode and save as PNG
    echo "$png_data" | base64 -d > "Assets.xcassets/AppIcon.appiconset/$filename"
}

# Create all required icon files
create_png 40 "Icon-20@2x.png"
create_png 60 "Icon-20@3x.png"
create_png 58 "Icon-29@2x.png"
create_png 87 "Icon-29@3x.png"
create_png 80 "Icon-40@2x.png"
create_png 120 "Icon-40@3x.png"
create_png 120 "Icon-60@2x.png"
create_png 180 "Icon-60@3x.png"
create_png 20 "Icon-20.png"
create_png 40 "Icon-20@2x-1.png"
create_png 29 "Icon-29.png"
create_png 58 "Icon-29@2x-1.png"
create_png 40 "Icon-40.png"
create_png 80 "Icon-40@2x-1.png"
create_png 152 "Icon-76@2x.png"
create_png 167 "Icon-83.5@2x.png"
create_png 1024 "Icon-1024.png"

echo "Placeholder app icons created!" 