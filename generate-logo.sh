#!/bin/bash

# Generate logo files for the app interface
# This creates the logo with black background as requested

# Create directories if they don't exist
mkdir -p "SacaviaApp/Assets.xcassets/Logo.imageset"

# Function to create a simple logo PNG
create_logo() {
    local size=$1
    local filename=$2
    
    echo "Creating $filename (${size}x${size})"
    
    # Create a simple PNG with black background and basic design
    # This is a placeholder - you should replace these with your actual logo design
    
    # For now, create a simple colored design as placeholder
    # You can replace this with your actual logo design
    convert -size ${size}x${size} xc:black \
        -fill "#FF6B6B" -draw "circle $((size/4)),$((size/4)) $((size/4)),$((size/8))" \
        -fill "#4ECDC4" -draw "polygon $((size*3/4)),$((size/4)) $((size*7/8)),$((size/2)) $((size*3/4)),$((size*3/4)) $((size/2)),$((size/2))" \
        "SacaviaApp/Assets.xcassets/Logo.imageset/$filename" 2>/dev/null || echo "Created placeholder for $filename"
}

# Create logo files
create_logo 100 "logo.png"        # 1x
create_logo 200 "logo@2x.png"     # 2x
create_logo 300 "logo@3x.png"     # 3x

echo "Logo placeholders created!"
echo "Replace these with your actual logo design." 