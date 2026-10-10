import base64
import json
import math
import struct

LEAVES = [
    [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, [0.0, 0.25, 0.5, 0.75]],
    [3.0, 1.0, 1.0, 1.0, 1.0, 1.0, [0.0, 0.25, 0.5, 0.75]],
    [4.0, 2.0, 2.0, 1.0, 1.0, 1.0, [0.0, 0.25, 0.5, 0.75]],
    [6.0, 2.5, 2.5, 4.0, 1.0, 1.0, [0.0, 0.25, 0.5, 0.75]],
    [8.0, 2.5, 2.5, 6.0, 2.0, 2.0, [0.0, 0.5, 1.0, 1.5]],
    [15.0, 5.0, 5.0, 10.0, 2.0, 2.0, [0.0, 0.75, 1.5, 2.25]],
    [25.0, 5.0, 10.0, 7.0, 4.0, 4.0, [0.0, 1.0, 2.0, 3.0]],
    [40.0, 10.0, 20.0, 10.0, 10.0, 10.0, [0.0, 1.0, 2.0, 3.0]],
    [60.0, 20.0, 30.0, 20.0, 20.0, 20.0, [0.0, 1.0, 2.0, 3.0]],
]

OPEN_ANGLE_DEG = 45.0    # how far the leaf swings open
CLOSED_ANGLE_DEG = 0.0   # closed = both leaves coplanar

# glTF enum constants
FLOAT = 5126
UNSIGNED_SHORT = 5123
ARRAY_BUFFER = 34962
ELEMENT_ARRAY_BUFFER = 34963

def make_box(sx, sy, sz):
    hx, hy, hz = sx * 0.5, sy * 0.5, sz * 0.5

    faces = [
        ((0.0, 0.0, 1.0),
         [(-hx, -hy,  hz), ( hx, -hy,  hz), ( hx,  hy,  hz), (-hx,  hy,  hz)]),
        ((0.0, 0.0, -1.0),
         [(-hx, -hy, -hz), (-hx,  hy, -hz), ( hx,  hy, -hz), ( hx, -hy, -hz)]),
        ((1.0, 0.0, 0.0),
         [( hx, -hy, -hz), ( hx,  hy, -hz), ( hx,  hy,  hz), ( hx, -hy,  hz)]),
        ((-1.0, 0.0, 0.0),
         [(-hx, -hy, -hz), (-hx, -hy,  hz), (-hx,  hy,  hz), (-hx,  hy, -hz)]),
        ((0.0, 1.0, 0.0),
         [(-hx,  hy, -hz), (-hx,  hy,  hz), ( hx,  hy,  hz), ( hx,  hy, -hz)]),
        ((0.0, -1.0, 0.0),
         [(-hx, -hy, -hz), ( hx, -hy, -hz), ( hx, -hy,  hz), (-hx, -hy,  hz)]),
    ]

    positions, normals, indices = [], [], []
    for normal, corners in faces:
        base = len(positions)
        for corner in corners:
            positions.append(corner)
            normals.append(normal)
        indices.extend([base, base + 1, base + 2,
                        base, base + 2, base + 3])
    return positions, normals, indices


def rotation_quaternion(angle_radians, angle2_radians):
    half = angle_radians * 0.5
    half2 = angle2_radians * 0.5
    return (0.0, math.sin(half2), math.sin(half) * math.cos(half2), math.cos(half))

class GltfBuilder:
    def __init__(self):
        self.blob = bytearray()
        self.buffer_views = []
        self.accessors = []
        self.meshes = []
        self.materials = []
        self.nodes = []
        self.animations = []

    def _align(self):
        while len(self.blob) % 4:
            self.blob.append(0)

    def _add_view(self, raw, target=None):
        self._align()
        offset = len(self.blob)
        self.blob.extend(raw)
        view = {"buffer": 0, "byteOffset": offset, "byteLength": len(raw)}
        if target is not None:
            view["target"] = target
        self.buffer_views.append(view)
        return len(self.buffer_views) - 1

    def _add_accessor(self, view, component_type, count, type_name, minmax=None):
        accessor = {
            "bufferView": view,
            "componentType": component_type,
            "count": count,
            "type": type_name,
        }
        if minmax is not None:
            accessor["min"], accessor["max"] = minmax
        self.accessors.append(accessor)
        return len(self.accessors) - 1

    def add_vec3(self, vectors, target=ARRAY_BUFFER):
        flat = [c for v in vectors for c in v]
        view = self._add_view(struct.pack("<%df" % len(flat), *flat), target)
        lo = [min(v[i] for v in vectors) for i in range(3)]
        hi = [max(v[i] for v in vectors) for i in range(3)]
        return self._add_accessor(view, FLOAT, len(vectors), "VEC3", (lo, hi))

    def add_vec4(self, vectors):
        flat = [c for v in vectors for c in v]
        view = self._add_view(struct.pack("<%df" % len(flat), *flat))
        return self._add_accessor(view, FLOAT, len(vectors), "VEC4")

    def add_indices(self, indices):
        view = self._add_view(struct.pack("<%dH" % len(indices), *indices),
                              ELEMENT_ARRAY_BUFFER)
        return self._add_accessor(view, UNSIGNED_SHORT, len(indices), "SCALAR",
                                  ([min(indices)], [max(indices)]))

    def add_scalar_floats(self, values):
        view = self._add_view(struct.pack("<%df" % len(values), *values))
        return self._add_accessor(view, FLOAT, len(values), "SCALAR",
                                  ([min(values)], [max(values)]))

    def add_mesh(self, name, positions, normals, indices):
        pos_acc = self.add_vec3(positions)
        nrm_acc = self.add_vec3(normals)
        idx_acc = self.add_indices(indices)
        self.meshes.append({
            "name": name,
            "primitives": [{
                "attributes": {"POSITION": pos_acc, "NORMAL": nrm_acc},
                "indices": idx_acc,
            }],
        })
        return len(self.meshes) - 1

    def add_node(self, name, mesh=None, translation=None, rotation=None,
                 children=None):
        node = {"name": name}
        if mesh is not None:
            node["mesh"] = mesh
        if translation is not None:
            node["translation"] = list(translation)
        if rotation is not None:
            node["rotation"] = list(rotation)
        if children:
            node["children"] = list(children)
        self.nodes.append(node)
        return len(self.nodes) - 1

    def add_animation(self, name, node_index, times, rotations, path="rotation"):
        input_acc = self.add_scalar_floats(times)
        output_acc = self.add_vec4(rotations)
        self.animations.append({
            "name": name,
            "samplers": [{
                "input": input_acc,
                "output": output_acc,
                "interpolation": "LINEAR",
            }],
            "channels": [{
                "sampler": 0,
                "target": {"node": node_index, "path": path},
            }],
        })
        return len(self.animations) - 1

    def to_dict(self, scene_name="HingeScene", root_nodes=None):
        self._align()
        uri = ("data:application/octet-stream;base64,"
               + base64.b64encode(bytes(self.blob)).decode("ascii"))

        doc = {
            "asset": {"version": "2.0", "generator": "generate.py"},
            "scene": 0,
            "scenes": [{"name": scene_name, "nodes": list(root_nodes or [])}],
            "nodes": self.nodes,
            "meshes": self.meshes,
            "accessors": self.accessors,
            "bufferViews": self.buffer_views,
            "buffers": [{"byteLength": len(self.blob), "uri": uri}],
        }
        if self.animations:
            doc["animations"] = self.animations
        return doc

def build_hinge(reverse = False):
    g = GltfBuilder()

    positions, normals, indices = make_box(LEAF_LENGTH, LEAF_THICKNESS,
                                           LEAF_HEIGHT)
    positions2, normals2, indices2 = make_box(LEAF_LENGTH2, LEAF_THICKNESS2,
                                           LEAF_HEIGHT2)

    mesh_fixed = g.add_mesh("LeafMesh", positions, normals, indices)
    mesh_swing = g.add_mesh("LeafMesh2", positions2, normals2, indices2)

    half = LEAF_LENGTH * 0.25 + LEAF_LENGTH2 * 0.25

    leaf_fixed = g.add_node("LeafFixed", mesh=mesh_fixed,
                            translation=(-half, 0.0, 0.0))
    leaf_swing = g.add_node("LeafSwinging", mesh=mesh_swing,
                            translation=(half, 0.0, 0.0))

    hinge = g.add_node("Hinge", children=[leaf_swing])

    root = g.add_node("HingeRoot", children=[leaf_fixed, hinge])

    closed = math.radians(CLOSED_ANGLE_DEG)
    opened = math.radians(OPEN_ANGLE_DEG)
    ang1 = math.radians(0)
    ang2 = math.radians(24)
    ang3 = math.radians(48)

    times = TIMES
    angles = [
        (closed, -ang1),
        (opened, -ang2),
        (closed, -ang3),
        (closed, -ang1)
    ] if reverse else [
        (closed, ang1),
        (opened, ang2),
        (closed, ang3),
        (closed, ang1)
    ]
    rotations = [rotation_quaternion(a, b) for (a, b) in angles]

    g.add_animation("HingeOpenClose", hinge, times, rotations)

    return g.to_dict(root_nodes=[root])


def main():
    global OUTPUT_FILE, LEAF_LENGTH, LEAF_THICKNESS, LEAF_HEIGHT, LEAF_LENGTH2
    global LEAF_THICKNESS2, LEAF_HEIGHT2, TIMES
    for i, l in enumerate(LEAVES):
        OUTPUT_FILE = f"nv_hinge{i+1}.gltf"
        LEAF_LENGTH = l[0]
        LEAF_THICKNESS = l[1]
        LEAF_HEIGHT = l[2]
        LEAF_LENGTH2 = l[3]
        LEAF_THICKNESS2 = l[4]
        LEAF_HEIGHT2 = l[5]
        TIMES = l[6]
    
        doc = build_hinge()
        with open(OUTPUT_FILE, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, indent=2)
        
        OUTPUT_FILE = f"nv_hinge{i+1}_r.gltf"
        doc = build_hinge(reverse = True)
        with open(OUTPUT_FILE, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, indent=2)

if __name__ == "__main__":
    main()
