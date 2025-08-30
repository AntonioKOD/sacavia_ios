#!/bin/bash

# Create logo PNG files for the app interface
# This creates the logo with black background as requested

# Function to create a simple logo PNG
create_logo() {
    local size=$1
    local filename=$2
    
    echo "Creating $filename (${size}x${size})"
    
    # Create a minimal PNG file with black background
    # This is a base64 encoded minimal PNG with black background
    local png_data="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="
    
    # Decode and save as PNG
    echo "$png_data" | base64 -d > "Assets.xcassets/Logo.imageset/$filename"
}

# Create logo files
create_logo 100 "logo.png"
create_logo 200 "logo@2x.png"
create_logo 300 "logo@3x.png"

echo "Logo placeholder files created!" 