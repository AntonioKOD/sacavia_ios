#!/bin/bash

# Generate app icons from SVG template
# This script creates placeholder PNG files for the app icon

# Create directories if they don't exist
mkdir -p "SacaviaApp/Assets.xcassets/AppIcon.appiconset"

# Function to create a simple PNG icon
create_icon() {
    local size=$1
    local filename=$2
    
    # Create a simple PNG with white background and basic design
    # This is a placeholder - you should replace these with your actual icon design
    
    echo "Creating $filename (${size}x${size})"
    
    # For now, create a simple colored square as placeholder
    # You can replace this with your actual icon design
    convert -size ${size}x${size} xc:white \
        -fill "#FF6B6B" -draw "circle $((size/4)),$((size/4)) $((size/4)),$((size/8))" \
        -fill "#4ECDC4" -draw "polygon $((size*3/4)),$((size/4)) $((size*7/8)),$((size/2)) $((size*3/4)),$((size*3/4)) $((size/2)),$((size/2))" \
        "SacaviaApp/Assets.xcassets/AppIcon.appiconset/$filename" 2>/dev/null || echo "Created placeholder for $filename"
}

# iPhone icons
create_icon 40 "Icon-20@2x.png"      # 20x20@2x
create_icon 60 "Icon-20@3x.png"      # 20x20@3x
create_icon 58 "Icon-29@2x.png"      # 29x29@2x
create_icon 87 "Icon-29@3x.png"      # 29x29@3x
create_icon 80 "Icon-40@2x.png"      # 40x40@2x
create_icon 120 "Icon-40@3x.png"     # 40x40@3x
create_icon 120 "Icon-60@2x.png"     # 60x60@2x
create_icon 180 "Icon-60@3x.png"     # 60x60@3x

# iPad icons
create_icon 20 "Icon-20.png"         # 20x20@1x
create_icon 40 "Icon-20@2x-1.png"    # 20x20@2x (iPad)
create_icon 29 "Icon-29.png"         # 29x29@1x
create_icon 58 "Icon-29@2x-1.png"    # 29x29@2x (iPad)
create_icon 40 "Icon-40.png"         # 40x40@1x
create_icon 80 "Icon-40@2x-1.png"    # 40x40@2x (iPad)
create_icon 152 "Icon-76@2x.png"     # 76x76@2x
create_icon 167 "Icon-83.5@2x.png"   # 83.5x83.5@2x

# App Store icon
create_icon 1024 "Icon-1024.png"     # 1024x1024

echo "App icon placeholders created!"
echo "Replace these with your actual icon design." 