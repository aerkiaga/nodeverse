# Autobox

![Autobox Visual Example](readme_assets/visual_example.jpg)

Autobox is Minetest Utility Mod for auto collision/selection boxes for nodes with drawtype=mesh. 

These auto-defined boxes come from its sister lua utility program, [boxgen](https://github.com/ExeVirus/boxgen), 
in the form of <filename>.box files. These are placed in your mod's "data/" folder to be used with autbox's only function:

    autobox.register_node(name, data_filename, node_definition, respect_nodes)

This function takes 4 parameters:

- **name** name of the node, for example: "yourmod:example"

- **data_filename** name of the node's box data, for example: "example.box"

- **node_definition** This is your normal node_definition you provide to minetest.register_node()

- **respect_nodes** Whether multi-node autobox nodes overwrite existing nodes or not
    
Putting it all together:

    autobox.register_node("yourmod:example", "example.box", yournode_def, true)
    
---

Autobox is special because it allows modders (I believe for the first time) to create nodes using meshes
*larger* than 3x3x3. Minetest has a restriction on mesh sizes of 3x3x3 for performance tradeoffs, and autobox 
allows us to represent larger meshes in a single-node-like way that respects this limitation. 

Any mesh that is larger than 3x3x3 can have ".box" data generated with [boxgen](https://github.com/ExeVirus/boxgen),
and autobox will create "child nodes" that help represent the "parent node" you register.

When you dig, punch, rotate, or do anything to a child node, you will do it to all nodes connected with the parent, and vice versa.
This allows them to act as a single node. But, to the user, child nodes will rarely be noticed. 

---

When working with multi-node representations, it's important to realize that rotation can result in orientations where a child node might
need to take the place of an existing node, like the ground when you spin a tower mesh updside down. In these cases, if you have registered your nodes with "respect_nodes"=true, the node will merely fail to rotate into the orientation and alert the rotating player why and where the rotation failed.
This always occurs for protected nodes, even with respect_nodes = false. 

---

Child_nodes are not in creative inventory, and should never be dropped in any way. If a player has access to a child node, they either hacked it in, or the server crashed just as the child nodes were being removed in some way. 

---

## Sample

To get a sample of what Autobox can let you do, uncomment the "init.lua" file's last line, which loads "example.lua". Then load up a creative world with autobox enabled and start placing and rotating and digging some "autobox:example" and "autobox:wagon" nodes to get a feel for the mod.

Happy *Auto*boxing!


