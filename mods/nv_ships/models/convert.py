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

tris_to_polys = [None for n in range(len(triangles))]
polys_to_tris = []

for n1 in range(len(triangles)):
    if tris_to_polys[n1] is None:
        tris_to_polys[n1] = len(polys_to_tris)
        polys_to_tris.append([])
        polys_to_tris[-1].append(n1)
    for n2 in range(n1 + 1, len(triangles)):
        if tris_to_polys[n2] == tris_to_polys[n1]:
            continue
        if len(set(triangles[n1]).intersection(set(triangles[n2]))) == 2:
            candidate_quad = tuple(set(triangles[n1]).union(set(triangles[n2])))
            M = tuple(map(lambda x: \
                tuple(map(lambda y: y[0] - y[1], zip(x, candidate_quad[0]))), candidate_quad[1:] \
            ))
            det = sum([M[0][n%3]*(M[1][(n+1)%3]*M[2][(n+2)%3] - M[1][(n+2)%3]*M[2][(n+1)%3]) \
                for n in range(0, 3) \
            ])
            if abs(det) < 0.0001:
                if tris_to_polys[n2] is not None:
                    removed_p = tris_to_polys[n2]
                    for t in polys_to_tris[removed_p]:
                        tris_to_polys[t] = tris_to_polys[n1]
                        polys_to_tris[tris_to_polys[n1]].append(t)
                    del polys_to_tris[removed_p]
                    for t_list in polys_to_tris[removed_p :]:
                        for t in t_list:
                            tris_to_polys[t] -= 1
                else:
                    tris_to_polys[n2] = tris_to_polys[n1]
                    polys_to_tris[tris_to_polys[n1]].append(n2)

poly_minima = []
poly_maxima = []
for polygon in polys_to_tris:
    poly_minima.append((1000, 1000, 1000))
    poly_maxima.append((-1000, -1000, -1000))
    for t in polygon:
        for vertex in triangles[t]:
            poly_minima[-1] = tuple(map(lambda x: min(x[0], x[1]), zip(poly_minima[-1], vertex)))
            poly_maxima[-1] = tuple(map(lambda x: max(x[0], x[1]), zip(poly_maxima[-1], vertex)))

maxcoords = (0, 0)
uvrectangles = []
excludedindices = []
for n in range(len(polys_to_tris)):
    vector = tuple(map(lambda x: x[0] - x[1], zip(poly_maxima[n], poly_minima[n])))
    excludedindex = vector.index(0)
    indices = list({0, 1, 2} - {excludedindex})
    sides = (round(16 * vector[indices[0]]), round(16 * vector[indices[1]]))
    bestfit = None
    for x in range(0, maxcoords[0] * 16 + 1, 1):
        for y in range(0, maxcoords[1] * 16 + 1, 1):
            if not bestfit or max(x, y) < max(*bestfit):
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
    excludedindices.append(excludedindex)

endcoords = list(map(lambda x: tuple(map(sum, zip(x[0], x[1]))), uvrectangles))
maxside = max([max(coord) for coord in endcoords])
maxside = 2 ** math.ceil(math.log2(maxside))

uvmap = []
tris = []
for p in range(len(polys_to_tris)):
    base_3d = poly_minima[p]
    size_3d = tuple(map(lambda x: x[0] - x[1], zip(poly_maxima[p], poly_minima[p])))
    excluded_index = size_3d.index(0)
    base_3d = tuple([base_3d[n] for n in {0, 1, 2} - {excluded_index}])
    size_3d = tuple([size_3d[n] for n in {0, 1, 2} - {excluded_index}])
    base_uv = uvrectangles[p][0]
    size_uv = uvrectangles[p][1]
    transform = lambda x: tuple(map(lambda y:
        ((y[0] - y[1]) * y[4] / y[2] + y[3]) / maxside,
        zip(x, base_3d, size_3d, base_uv, size_uv)
    ))
    for t in polys_to_tris[p]:
        tris.append(triangles[t])
        for vertex in triangles[t]:
            vertex = tuple([vertex[n] for n in {0, 1, 2} - {excluded_index}])
            uvmap.append(transform(vertex))

print("{0} x {0}".format(maxside))

with open(sys.argv[1] + ".obj", "wt") as file:
    for vertex in vertices:
        file.write("v {} {} {}\n".format(*vertex))
    for vt in uvmap:
        file.write("vt {} {}\n".format(*vt))
    for n in range(len(tris)):
        file.write("f {0}/{3} {1}/{4} {2}/{5}\n".format(
            *map(lambda x: global_vertex_indices[x] + 1, tris[n]),
            *[3 * n + m + 1 for m in {0, 1, 2}]
        ))
