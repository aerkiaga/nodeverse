--[[
A table of players, indexed by name. Each value contains the following fields:
    ships       List of ships owned by player; see below for format
]]--
nv_ships.players_list = {}

--[[
Ship format:
    owner       name of the player that owns this ship
    state       what the ship currently is made of, "entity" or "node"
    size        size in nodes, as xyz vector
    pos         if state == "node", lowest xyz of ship bounding box in world
    cockpit_pos relative xyz of cockpit base node, or nil if no cockpit
    A           flat array of node IDs in ship bounding box (only part of ship)
    A2          flat array of param2's in ship bounding box (only part of ship)
]]--

--[[
Attempts to add a node to one of the placing player's ships, or start a new one.
The node is not physically placed in the world, but ships are updated.
Returns 'true' or 'false' to signal success or failure, respectively.
]]
function nv_ships.try_add_node(node, pos, placer)
    -- Possible scenarios:
    -- * Player puts node inside bounding box of their ship: always OK
    -- * Player puts node adjacent to bounding box of their ship
    --   - Not adjacent to anything else: OK if below size limit
    --       Simply extend bounding box
    --   - Adjacent to other players' ship(s): never OK
    --   - Adjacent to other own ship(s): OK if single cockpit and below limit
    --       Merge into one ship
    -- * Player puts node elsewhere
    --   - No conflicts with other players' ships: always OK
    --       Create new ship
    --   - Inside or adjacent to other players' ship(s): never OK
    return true
end

function nv_ships.get_landing_position(player)
    local pos = player:get_pos()
    for y=pos.y, pos.y - 64, -1 do
        pos.y = y
        local node = minetest.get_node(pos)
        if minetest.registered_nodes[node.name].walkable then
            return pos
        end
    end
    return nil
end

function nv_ships.try_board_ship(pos, player)
    local clicked_node = minetest.get_node(pos)
    local ent_name = ""
    for name in string.gmatch(clicked_node.name, "[^:]*:(.*)") do
        ent_name = "nv_ships:ent_" .. name
    end
    minetest.remove_node(pos)
    local ent_seat = minetest.add_entity(pos, ent_name)
    player:set_pos(pos)
    ent_seat:set_attach(player)
    return true
end

local function try_place_ship_at(pos, facing)
    -- 'facing' values: 0, 1, 2, 3
    -- +Z, +X, -Z, -X
    local node = minetest.get_node(pos)
    if minetest.registered_nodes[node.name].walkable then
        return false
    end
    minetest.set_node(pos, {
        name = "nv_ships:seat",
        param1 = 0, param2 = facing
    })
    return true
end

function nv_ships.remove_ship_entity(player)
    local children = player:get_children()
    for index, child in ipairs(children) do
        local properties = child:get_properties() or {}
        if true then
            child:set_detach(player)
            child:remove()
        end
    end
end

function nv_ships.try_unboard_ship(player)
    local pos = player:get_pos()
    local yaw = player:get_look_horizontal()
    local facing = math.floor(-2*yaw/math.pi + 0.5) % 4
    if try_place_ship_at(pos, facing) then
        nv_ships.remove_ship_entity(player)
        return true
    else
        return false
    end
end
