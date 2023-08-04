#!/usr/bin/env bash
# This is a Bash script
# Use it after creating file 'nv_atlas.png'; see 'generate.scm' for steps
# First of all, this script requires ImageMagick to be installed
# Install it if necessary (e.g. by running 'sudo apt-get install imagemagick')
# Open a terminal and go into this same directory
# Type 'bash split.sh', with no quotes, and press enter

convert -crop 8x1 nv_atlas.png nv_palette%d.png
mv nv_palette0.png     nv_palette_stone1.png
mv nv_palette1.png     nv_palette_stone2.png
mv nv_palette2.png     nv_palette_water1.png
mv nv_palette3.png     nv_palette_water2.png
mv nv_palette4.png     nv_palette_water3.png
mv nv_palette5.png     nv_palette_water4.png
mv nv_palette6.png     nv_palette_grass1.png
mv nv_palette7.png     nv_palette_grass2.png
mv nv_palette8.png     nv_palette_grass3.png
mv nv_palette9.png     nv_palette_grass4.png
mv nv_palette10.png     nv_palette_grass5.png
mv nv_palette11.png     nv_palette_grass6.png
convert -level -25,100% +append nv_palette_stone1.png nv_palette_stone2.png nv_palette_stone.png
convert +append nv_palette_stone.png nv_palette_stone.png nv_palette_stone.png
convert +append nv_palette_stone.png nv_palette_stone.png nv_palette_stone.png
