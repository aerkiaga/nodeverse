#!/usr/bin/env bash
# This is a Bash script
# It requires OpenSCAD, which you can install from your system's repositories,
# e.g. sudo apt-get install openscad, or download from https://openscad.org/

# Open a terminal and go into this same directory
# Type 'bash generate.sh', with no quotes, and press enter
# This script will generate appropriate Wavefront OBJ model files
# from the OpenSCAD scripts present in the same directory

generate_file() {
    echo "Reading $1.scad"
    (
        openscad -o "$1.stl" --output_format asciistl "$1.scad" ||
        openscad -o "$1.stl" "$1.scad"
    ) 2>/dev/null &&
    `dirname "${BASH_SOURCE[0]}"`/convert.py "$1" &&
    rm "$1.stl"
}

generate_file test
