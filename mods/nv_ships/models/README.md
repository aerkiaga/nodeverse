# Models
Some models files in this directory were automatically generated using the
script `generate.sh`, which reads the `.scad` files in the same directory.
These files are model scripts meant to be read by OpenSCAD, and you can edit
them to modify those models. The script is meant to be run in a Unix-like
environment.

The tool generates UV maps for all models. This means that, upon modification,
the corresponding textures in `../textures` should be updated too. This can be
achieved by importing the `.obj` files into Blender and inspecting the UV map.

## Licensing
All assets in this folder not created by `generate.sh` are created by aerkiaga
and distributed under the CC-BY-SA-4.0 license.
