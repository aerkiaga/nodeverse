#!/usr/bin/env python3

# This is a Python script
# It takes an STL file name (without extension) as input, and produces an OBJ
# file in the same directory

# It's meant to be run from 'generate.sh'

import sys, re

vertex_pattern = re.compile("[ \t]*vertex ([^ ]*) ([^ ]*) ([^ ]*)")

triangles = []
with open(sys.argv[1] + ".stl", "rt") as file:
    vertex_index = 0
    for line in file:
        match = vertex_pattern.match(line)
        if match is not None:
            vertex = tuple(map(float, match.groups()))
            if vertex_index == 0:
                triangles.append([])
            triangles[-1].append(vertex)
            vertex_index = (vertex_index + 1) % 3

vertices = []
global_vertex_indices = {}
for triangle in triangles:
    for vertex in triangle:
        if vertex not in global_vertex_indices:
            global_vertex_indices[vertex] = len(vertices)
            vertices.append(vertex)

with open(sys.argv[1] + ".obj", "wt") as file:
    for vertex in vertices:
        file.write("v {} {} {}\n".format(*vertex))
    for triangle in triangles:
        file.write("f {} {} {}\n".format(
            *map(lambda x: global_vertex_indices[x] + 1, triangle)
        ))
