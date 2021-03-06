#!/usr/bin/env bash
# This is a Bash script
# It requires a recent version of ChucK, as well as FFMPeg
# You can install ChucK with e.g. sudo apt-get install chuck, but may be outdated
# Alternatively, you can build from source or download recent binaries
# (see https://chuck.cs.princeton.edu/ or https://chuck.stanford.edu/)
# You can install FFMPeg with e.g. sudo apt-get install ffmpeg

# Open a terminal and go into this same directory
# Type 'bash record.sh', with no quotes, and press enter
# This script will generate appropriate OGG Vorbis audio files
# from the ChucK scripts present in the same directory

record_file() {
    chuck -s "$1.ck" "rec.ck:$1.wav" &&
    (echo "(FFMPeg) Converting to OGG"
    ffmpeg -y -v warning -i "$1.wav" "$1.ogg"
    rm "$1.wav")
}

record_file nv_step_dust
record_file nv_step_dust.0
record_file nv_step_grass_soil
record_file nv_step_grass_soil.0
record_file nv_step_gravel
record_file nv_step_gravel.0
record_file nv_step_sediment
record_file nv_step_sediment.0
record_file nv_step_snow
record_file nv_step_snow.0
record_file nv_step_stone
record_file nv_step_stone.0
