#!/usr/bin/env bash
# This is a Bash script
# It will take all .scad files in the current directory, run OpenSCAD on them
# and output the results as .obj files

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
