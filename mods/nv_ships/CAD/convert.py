#!/usr/bin/env python3

# This is a Python script
# It takes an STL file name (without extension) as input, and produces an OBJ
# file in the same directory

# It's meant to be run from 'generate.sh'

import math, sys, re

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

rectangles = []
for n1 in range(len(triangles)):
    for n2 in range(n1 + 1, len(triangles)):
        if len(set(triangles[n1]).intersection(set(triangles[n2]))) == 2:
            candidate = tuple(set(triangles[n1]).union(set(triangles[n2])))
            M = tuple(map(lambda x: \
                tuple(map(lambda y: y[0] - y[1], zip(x, candidate[0]))), candidate[1:] \
            ))
            det = sum([M[0][n%3]*(M[1][(n+1)%3]*M[2][(n+2)%3] - M[1][(n+2)%3]*M[2][(n+1)%3]) \
                for n in range(0, 3) \
            ])
            if abs(det) < 0.0001:
                rectangles.append(candidate)

maxcoords = (0, 0)
uvrectangles = []
uvmap = []
excludedindices = []
for rectangle in rectangles:
    M = tuple(map(lambda x: \
        tuple(map(lambda y: y[0] - y[1], zip(x, rectangle[0]))), rectangle[1:] \
    ))
    lengths = tuple(map(lambda x: math.hypot(*x), M))
    excludedindex = lengths.index(max(lengths)) + 1
    indices = [0] + list({1, 2, 3} - {excludedindex})
    sides = (int(16 * lengths[indices[1] - 1]), int(16 * lengths[indices[2] - 1]))
    bestfit = None
    for x in range(0, maxcoords[0] * 16 + 1, 1):
        for y in range(0, maxcoords[1] * 16 + 1, 1):
            if not bestfit or math.hypot(x, y) < math.hypot(*bestfit):
                fits = True
                for uvrect in uvrectangles:
                    if uvrect[0][0] + uvrect[1][0] > x and uvrect[0][0] < x + sides[0] \
                    and uvrect[0][1] + uvrect[1][1] > y and uvrect[0][1] < y + sides[1]:
                        fits = False
                        break
                if fits:
                    maxcoords = tuple(map(lambda x: max(x[0], x[1]), \
                        zip(maxcoords, (x + sides[0], y + sides[1])) \
                    ))
                    bestfit = (x, y)
    uvrectangles.append((bestfit, sides))
    uvmaprect = [0, 0, 0, 0]
    uvmaprect[indices[0]] = bestfit
    uvmaprect[indices[1]] = (bestfit[0] + sides[0], bestfit[1])
    uvmaprect[indices[2]] = (bestfit[0], bestfit[1] + sides[1])
    uvmaprect[excludedindex] = (bestfit[0] + sides[0], bestfit[1] + sides[1])
    uvmap.append(uvmaprect)
    excludedindices.append(excludedindex)

maxside = max([max(list(map(lambda x: max(x[n]), uvmap))) for n in range(4)])
maxside = 2 ** math.ceil(math.log2(maxside))
uvmap = list(map(lambda x: tuple(map(lambda y: tuple(map(lambda z: z/maxside, y)), x)), uvmap))

print("{0} x {0}".format(maxside))

with open(sys.argv[1] + ".obj", "wt") as file:
    for vertex in vertices:
        file.write("v {} {} {}\n".format(*vertex))
    for uv in uvmap:
        for vt in uv:
            file.write("vt {} {}\n".format(*vt))
    for n in range(len(rectangles)):
        for i in {1, 2, 3} - {excludedindices[n]}:
            file.write("f {0}/{3} {1}/{4} {2}/{5}\n".format(
                *map(lambda x: global_vertex_indices[x] + 1, \
                    [rectangles[n][k] for k in {0, i, excludedindices[n]}] \
                ),
                *[4 * n + m + 1 for m in {0, i, excludedindices[n]}]
            ))
