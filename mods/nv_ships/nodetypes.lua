--[[
It is in this file that all spaceship nodes are defined.

 # INDEX
    CALLBACKS
    COMMON REGISTRATION
    NODE TYPES
]]

--[[
 # CALLBACKS
]]

local function after_place_node_normal(pos, placer, itemstack, pointed_thing)
    local node = minetest.get_node(pos)
    if not nv_ships.try_add_node(node, pos, placer) then
        minetest.remove_node(pos)
        return true -- Don't remove from inventory
    end
end

local function can_dig_normal(pos, player)
    if player == nil then
        return false
    end
    return nv_ships.can_dig_node(pos, player)
end

local function after_dig_node_normal(pos, oldnode, oldmetadata, digger)
    if not nv_ships.try_remove_node(oldnode, pos, digger) then
        minetest.set_node(pos, oldnode)
        return
    end
    local start = string.find(oldnode.name, "_hull%d*")
    if start ~= nil then
        local new_name = string.sub(oldnode.name, 0, start-1)
        minetest.set_node(pos, {name=new_name, param1=oldnode.param1, param2=oldnode.param2})
    end
end

local function entity_on_step(self, dtime, moveresult)
    -- Sometimes these entities will not get removed normally
    -- Credit to MisterE for this workaround
    if self.object:get_attach() == nil then
        self.object:remove()
    end
end

--[[
 # COMMON REGISTRATION
]]

local function colorize_tiles(tiles, overlay_tiles, color)
    local r = {}
    for n=1, #(tiles or {}) do
        if type(tiles[n]) == "string" then
            tiles[n] = {name = tiles[n]}
        end
        if overlay_tiles ~= nil and type(overlay_tiles[n]) == "string" then
            overlay_tiles[n] = {name = overlay_tiles[n]}
        end
        if overlay_tiles ~= nil then
            r[n] = "(" .. tiles[n].name .. "^[multiply:" .. color .. ")^" .. overlay_tiles[n].name
        else
            r[n] = tiles[n].name .. "^[multiply:" .. color
        end
    end
    return r
end

minetest.register_entity("nv_ships:ship_node", {on_step = entity_on_step})

local function register_node_and_entity(name, def)
    local node_def = {
        description = def.description or "",
        drawtype = def.drawtype,
        is_ground_content = false,
        sunlight_propagates = def.sunlight_propagates,
        paramtype = def.paramtype,
        paramtype2 = def.paramtype2,
        walkable = def.walkable or true,
        tiles = def.tiles,
        overlay_tiles = def.overlay_tiles,
        color = def.color,
        use_texture_alpha = def.use_texture_alpha,
        groups = def.groups,
        node_box = def.node_box,
        mesh = def.mesh,
        selection_box = def.selection_box or def.collision_box,
        collision_box = def.collision_box,
        drop = def.drop,
        after_place_node = after_place_node_normal,
        after_dig_node = after_dig_node_normal,
        can_dig = can_dig_normal,
        on_punch = def.on_punch,
        on_rightclick = nv_ships.ship_rightclick_callback,
        nv_no_entity = def.nv_no_entity
    }
    node_def.groups.nv_ships = 1
    minetest.register_node("nv_ships:" .. name, node_def)
end

local function register_hull_node_and_entity(name, def)
    local default_palette = {
        "#EDEDED", "#9B9B9B", "#4A4A4A", "#212121", "#284E9B",
        "#2F939B", "#6DEE1D", "#287C00", "#F7F920", "#D86128",
        "#683B0C", "#C11D26", "#F9A3A5", "#D10082", "#4C007F",
    }
    for n=1, 15 do
        local colored_def = {
            description = def.description,
            drawtype = def.drawtype,
            is_ground_content = false,
            sunlight_propagates = def.sunlight_propagates,
            paramtype = def.paramtype,
            paramtype2 = def.paramtype2,
            walkable = def.walkable or true,
            tiles = colorize_tiles(def.tiles, def.overlay_tiles, default_palette[n]),
            use_texture_alpha = def.use_texture_alpha,
            groups = def.groups,
            mesh = def.mesh,
            selection_box = def.selection_box or def.collision_box,
            collision_box = def.collision_box,
            drop = def.drop,
            after_place_node = def.after_place_node,
            on_punch = def.on_punch,
            on_rightclick = nv_ships.ship_rightclick_callback,

            visual = "mesh",
            use_texture_alpha = def.use_texture_alpha,
            visual_size = def.visual_size,
            mesh = def.mesh,

            --color = default_palette[n],
            drop = "nv_ships:hull_plate" .. n,
        }
        register_node_and_entity(name .. n, colored_def)
    end
end

local function register_hull_variants(name, def)
    local def2 = table.copy(def)
    def2.tiles = {def.nv_texture .. ".png"}
    def2.overlay_tiles = nil
    def2.groups = table.copy(def.groups)
    def2.groups.ship_scaffold = 1
    register_node_and_entity(name, def2)
    local def3 = table.copy(def)
    def3.tiles = {def.nv_texture .. "_hull.png"}
    def3.overlay_tiles = {def.nv_texture .. "_hull_overlay.png"}
    def3.groups = table.copy(def.groups)
    def3.groups.ship_hull = 1
    register_hull_node_and_entity(name .. "_hull", def3)
end

--[[
 # NODE TYPES
Allocated: 100
16      seat
16      dark_seat
16      control_panel
16      scaffold
16      scaffold_edge
16      floor
16      turbo_engine
1       landing_leg
1       glass_face
1       glass_edge
1       glass_vertex
]]--

-- SEAT
-- A pilot seat to man the ship
-- Defines cockpit position and orientation
-- Required for liftoff
-- At most one per ship
register_hull_variants("seat", {
    description = "Pilot seat",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    nv_texture = "nv_seat",
    use_texture_alpha = "clip",
    groups = {
        oddly_breakable_by_hand = 3,
        fall_damage_add_percent = -100,
        bouncy = 0,
        pilot_seat = 1,
    },
    mesh = "nv_seat.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0, 0.5}
        },
    },
})

-- DARK SEAT
-- A glowing pilot seat
register_hull_variants("dark_seat", {
    description = "Dark pilot seat",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    nv_texture = "nv_seat_dark",
    use_texture_alpha = "clip",
    groups = {
        oddly_breakable_by_hand = 3,
        fall_damage_add_percent = -100,
        bouncy = 0,
        pilot_seat = 1,
    },
    mesh = "nv_seat.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0, 0.5}
        },
    },
})

-- CONTROL PANEL
-- A control panel lying right in front of the pilot.
register_hull_variants("control_panel", {
    description = "Control panel",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    nv_texture = "nv_control_panel",
    use_texture_alpha = "clip",
    groups = {
        oddly_breakable_by_hand = 3,
        fall_damage_add_percent = -100,
        bouncy = 0
    },
    mesh = "nv_control_panel.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
        },
    },
})

-- SCAFFOLD
-- A full block of scaffolding
register_hull_variants("scaffold", {
    description = "Ship scaffold",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    nv_texture = "nv_scaffold",
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "nv_scaffold.obj",
    
    on_punch = function(pos, node, puncher, pointed_thing)
        if node.name ~= "nv_ships:scaffold" then
            return
        end
        local ship = nv_ships.get_owned_ship_at(pos, puncher)
        if ship ~= nil then
            nv_ships.set_ship_node({name = "nv_ships:scaffold_edge", param2 = 0}, pos, ship)
        end
    end,
})

-- SCAFFOLD EDGE
-- A block of scaffolding rounded at one edge
-- Not obtainable as item
register_hull_variants("scaffold_edge", {
    description = "Ship scaffold edge",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    nv_texture = "nv_scaffold_edge",
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "nv_scaffold_edge.obj",
    
    drop = "nv_ships:scaffold",
    on_punch = function(pos, node, puncher, pointed_thing)
        if node.name ~= "nv_ships:scaffold_edge" then
            return
        end
        local ship = nv_ships.get_owned_ship_at(pos, puncher)
        if ship ~= nil then
            if node.param2 == 14 then
                nv_ships.set_ship_node({name = "nv_ships:scaffold", param2 = 0}, pos, ship)
            else
                local rotation_table = {
                    [0] = 1, [1] = 2, [2] = 3, [3] = 4,
                    [4] = 12, [12] = 7, [7] = 13, [13] = 5,
                    [5] = 15, [15] = 6, [6] = 14
                }
                nv_ships.set_ship_node({
                    name = "nv_ships:scaffold_edge", param2 = rotation_table[node.param2]
                }, pos, ship)
            end
        end
    end,
})

-- FLOOR
-- A thin scaffold floor occupying the bottom 1/4 of the node
-- Can be walked on easily
register_hull_variants("floor", {
    description = "Ship floor",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    nv_texture = "nv_floor",
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "nv_floor.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, -0.25, 0.5}
        },
    },
})

-- TURBO ENGINE
-- A turbojet engine to push an airship forward
register_hull_variants("turbo_engine", {
    description = "Turbo engine",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    nv_texture = "nv_turbo_engine",
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "nv_turbo_engine.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5}
        },
    },
})

-- LANDING LEG
-- A retractable landing leg for spacecraft
-- Has no entity form
register_node_and_entity("landing_leg", {
    description = "Landing leg",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    tiles = {"nv_landing_leg.png"},
    use_texture_alpha = "clip",
    groups = {oddly_breakable_by_hand = 3},
    mesh = "nv_landing_leg.obj",
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.25, -0.5, -0.25, 0.25, 0.5, 0.25}
        },
    },

    nv_no_entity = true,
})

-- GLASS FACE
-- A glass square cutting a node-shaped space in half
-- Should be unobtainable
-- TODO: handle side faces being visible with multiple connected panes
register_node_and_entity("glass_face", {
    description = "Glass face",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    tiles = {{
        name = "nv_glass.png",
        backface_culling = true,
        align_style = "world"
    }},
    use_texture_alpha = "blend",
    groups = {oddly_breakable_by_hand = 3},
    collision_box = {
        type = "fixed",
        fixed = {
            {-0.5, -0.5, -0.0625, 0.5, 0.5, 0.0625},
        }
    },
    mesh = "nv_glass_face.obj",
    drop = "nv_ships:glass_pane",

    nv_no_entity = true,
})

-- GLASS EDGE
-- Two perpendicular glass rectangles separating a quadrant of a node
-- Should be unobtainable
register_node_and_entity("glass_edge", {
    description = "Glass edge",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    tiles = {{
        name = "nv_glass.png",
        backface_culling = true,
        align_style = "world"
    }},
    use_texture_alpha = "blend",
    groups = {oddly_breakable_by_hand = 3},
    collision_box = {
        type = "fixed",
        fixed = {
            {0.0625, -0.5, -0.0625, 0.5, 0.5, 0.0625},
            {-0.0625, -0.5, 0.0625, 0.0625, 0.5, 0.5},
            {-0.0625, -0.5, -0.0625, 0.0625, 0.5, 0.0625},
        }
    },
    mesh = "nv_glass_edge.obj",
    drop = "nv_ships:glass_pane",

    nv_no_entity = true,
})

-- GLASS VERTEX
-- Three perpendicular glass squares separating an octant of a node
-- Should be unobtainable
register_node_and_entity("glass_vertex", {
    description = "Glass vertex",
    drawtype = "mesh",
    sunlight_propagates = true,
    paramtype = "light",
    paramtype2 = "facedir",

    tiles = {{
        name = "nv_glass.png",
        backface_culling = true,
        align_style = "world"
    }},
    use_texture_alpha = "blend",
    groups = {oddly_breakable_by_hand = 3},
    collision_box = {
        type = "fixed",
        fixed = {
            {0.0625, 0.0625, -0.0625, 0.5, 0.5, 0.0625},
            {-0.0625, 0.0625, 0.0625, 0.0625, 0.5, 0.5},
            {0.0625, -0.0625, 0.0625, 0.5, 0.0625, 0.5},
            {-0.0625, 0.0625, -0.0625, 0.0625, 0.5, 0.0625},
            {-0.0625, -0.0625, 0.0625, 0.0625, 0.0625, 0.5},
            {0.0625, -0.0625, -0.0625, 0.5, 0.0625, 0.0625},
            {-0.0625, -0.0625, -0.0625, 0.0625, 0.0625, 0.0625},
        }
    },
    mesh = "nv_glass_vertex.obj",
    drop = "nv_ships:glass_pane",

    nv_no_entity = true,
})
