--To load these examples, uncomment the last line in init.lua  (remove the "--" at the beginning)

--First Example
node_definition ={
	description =  "Example",
	drawtype = "mesh",
        mesh = "example.obj",
        sunlight_propagates = true,
        paramtype2 = "facedir",
        collision_box = {
            type = "fixed",
            fixed = {{0.95, -1.55, -0.55, -0.25, -0.65, 0.55}} --overwritten later
        },
        selection_box = {
            type = "fixed",
            fixed = {{0.95, -1.55, -0.55, -0.25, -0.65, 0.55}} --overwritten later
        },

        tiles = {"autobox_stone.png"},

        
        groups = { cracky=2 },

}
autobox.register_node("autobox:example","example.box",node_definition,true)

--Second Example
node_definition ={
	description =  "Wagon",
	drawtype = "mesh",
        mesh = "wagon.obj",
        sunlight_propagates = true,
        paramtype2 = "facedir",
        collision_box = {
            type = "fixed",
            fixed = {{0.95, -1.55, -0.55, -0.25, -0.65, 0.55}} --overwritten later
        },
        selection_box = {
            type = "fixed",
            fixed = {{0.95, -1.55, -0.55, -0.25, -0.65, 0.55}} --overwritten later
        },

        tiles = {"wagon.jpg"},

        
        groups = { cracky=2 },

}
autobox.register_node("autobox:wagon","wagon.box",node_definition,true)