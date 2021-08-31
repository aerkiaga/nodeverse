--[[
A table of players, indexed by name. Each value contains the following fields:
    ships       List of ships owned by player; see below for format
]]--
nv_ships.players_list = {}

--[[
Ship format:
    owner       name of the player that owns this ship
    index       index of ship in player's ship list
    state       what the ship currently is made of, "entity" or "node"
    size        size in nodes, as xyz vector
    pos         if state == "node", lowest xyz of ship bounding box in world
    cockpit_pos relative xyz of cockpit base node, or 'nil' if no cockpit
    A           flat array of node IDs in ship bounding box (only part of ship)
    A2          flat array of param2's in ship bounding box (only part of ship)
]]--

--[[
Returns nil if no conflict, a vector if 'pos' lies within, or adjacent to, the
box defined by vectors 'box_pos' and 'box_size'. The return vector indicates the
direction in which 'pos' is adjacent relative to the box (e.g. {x=1, y=0, z=1}),
or {x=0, y=0, z=0} if 'pos' is within the box.
]]--
local function compute_box_conflict(pos, box_pos, box_size)
    local function compute_component_conflict(pos_c, box_pos_c, box_size_c)
        local box_maxp_c = box_pos_c + box_size_c - 1
        if pos_c < box_pos_c then
            if pos_c < box_pos_c - 1 then
                return nil
            else
                return -1
            end
        elseif pos_c > box_maxp_c then
            if pos_c > box_maxp_c + 1 then
                return nil
            else
                return 1
            end
        else
            return 0
        end
    end

    ----------------------------------------------------------------------------

    local r = {
        x = compute_component_conflict(pos.x, box_pos.x, box_size.x),
        y = compute_component_conflict(pos.y, box_pos.y, box_size.y),
        z = compute_component_conflict(pos.z, box_pos.z, box_size.z)
    }
    if r.x == nil or r.y == nil or r.z == nil then
        return nil
    end
    return r
end

-- Tries to put node in world position that happens to be inside ship
-- Will update ship data as required
-- Returns 'false' if the node can't be placed, 'true' otherwise
local function try_put_node_in_ship(node, pos, ship)
    local rel_pos = {
        x = pos.x - ship.pos.x,
        y = pos.y - ship.pos.y,
        z = pos.z - ship.pos.z
    }
    -- Check node
    if node.name == "nv_ships:seat" then
        if ship.cockpit_pos ~= nil then
            return false
        end
        ship.cockpit_pos = rel_pos
    end
    -- Place it
    local x_stride = ship.size.x
    local y_stride = ship.size.y
    local k = rel_pos.z*y_stride*x_stride + rel_pos.y*x_stride + rel_pos.x + 1
    ship.A[k] = minetest.registered_nodes[node.name]
    ship.A2[k] = node.param2
    return true
end

-- Takes all node ID and param2 data from a ship and copy it to another
-- Will take ship position and size into consideration
local function map_ship_into_another(source, destination)
    local rel_pos_d = {
        x = source.pos.x - destination.pos.x,
        y = source.pos.y - destination.pos.y,
        z = source.pos.z - destination.pos.z
    }
    local x_stride = destination.size.x
    local y_stride = destination.size.y
    local k_s = 1
    for rel_z_d=rel_pos_d.z, rel_pos_d.z + source.size.z - 1 do
        for rel_y_d=rel_pos_d.y, rel_pos_d.y + source.size.y - 1 do
            for rel_x_d=rel_pos_d.x, rel_pos_d.x + source.size.x - 1 do
                local k_d = rel_z_d*y_stride*x_stride + rel_y_d*x_stride + rel_x_d + 1
                destination.A[k_d] = source.A[k_s]
                destination.A2[k_d] = source.A2[k_s]
                k_s = k_s + 1
            end
        end
    end
end

local function remove_ship_from_list(ship, list)
    table.remove(list, ship.index)
    for index=ship.index, #list do
        list[index].index = index
    end
end

--[[
Attempts to add a node to one of the placing player's ships, or start a new one.
The node is not physically placed in the world, but ships are updated.
Returns 'true' or 'false' to signal success or failure, respectively.
]]
function nv_ships.try_add_node(node, pos, placer)
    -- Possible scenarios:
    -- 1 Player puts node inside bounding box of own ship: always OK
    -- 2 Player puts node inside or adjacent to other players' ship(s): never OK
    -- 3 Player puts node adjacent to bounding box of own ship
    --   - Not adjacent to anything else: OK if below size limit
    --       Simply extend bounding box
    --   - Adjacent to other own ship(s): OK if single cockpit and below limit
    --       Merge into one single ship
    -- 4 Player puts node elsewhere: always OK
    --     Create new ship

    local function find_conflicts(conflicts, pos, ships)
        for index, ship in ipairs(ships) do
            if ship.state == "node" then
                local conflict = compute_box_conflict(pos, ship.pos, ship.size)
                if conflict ~= nil then
                    conflicts[#conflicts+1] = {
                        ship = ship, conflict = conflict
                    }
                end
            end
        end
    end

    local function is_inside(conflict)
        return conflict.x == 0 and conflict.y == 0 and conflict.z == 0
    end

    local function count_cockpits_up_to_two(conflicts)
        local n = 0
        for index, conflict in ipairs(conflicts) do
            if conflict.ship.cockpit_pos ~= nil then
                n = n + 1
                if n >= 2 then
                    return n
                end
            end
        end
        return n
    end

    local function get_merged_bounds(pos, conflicts)
        local minp = {x=pos.x, y=pos.y, z=pos.z}
        local maxp = {x=pos.x, y=pos.y, z=pos.z}
        for index, conflict in ipairs(conflicts) do
            minp.x = math.min(minp.x, conflict.ship.pos.x)
            minp.y = math.min(minp.y, conflict.ship.pos.y)
            minp.z = math.min(minp.z, conflict.ship.pos.z)
            maxp.x = math.max(maxp.x, conflict.ship.pos.x + conflict.ship.size.x - 1)
            maxp.y = math.max(maxp.y, conflict.ship.pos.y + conflict.ship.size.y - 1)
            maxp.z = math.max(maxp.z, conflict.ship.pos.z + conflict.ship.size.z - 1)
        end
        local r_pos = minp
        local r_size = {
            x = maxp.x - minp.x + 1,
            y = maxp.y - minp.y + 1,
            z = maxp.z - minp.z + 1
        }
        return r_pos, r_size
    end

    local function is_acceptable_size(size)
        return size.x <= 15 and size.y <= 15 and size.y <= 15
    end

    local function find_new_cockpit_pos(relative_to, conflicts)
        for index, conflict in ipairs(conflicts) do
            local ship = conflict.ship
            if conflict.ship.cockpit_pos ~= nil then
                return {
                    x = ship.cockpit_pos.x + ship.pos.x - relative_to.x,
                    y = ship.cockpit_pos.y + ship.pos.y - relative_to.y,
                    z = ship.cockpit_pos.z + ship.pos.z - relative_to.z,
                }
            end
        end
        return nil
    end

    ----------------------------------------------------------------------------

    local name = placer:get_player_name()
    local player_ship_list = nv_ships.players_list[name].ships
    local own_ships_conflicts = {}
    find_conflicts(own_ships_conflicts, pos, player_ship_list)
    -- Check case 1
    if #own_ships_conflicts == 1 and is_inside(own_ships_conflicts[1].conflict) then
        return try_put_node_in_ship(node, pos, own_ships_conflicts[1].ship)
    end

    local other_ships_conflicts = {}
    for name2, player in pairs(nv_ships.players_list) do
        if name2 ~= name then
            find_conflicts(other_ships_conflicts, pos, player.ships)
        end
    end
    -- Check case 2
    if #other_ships_conflicts >= 1 then
        return false
    end
    -- Check case 3 (general code for any number of adjacent ships)
    if #own_ships_conflicts >= 1 then
        local n_cockpits = count_cockpits_up_to_two(own_ships_conflicts)
        if n_cockpits >= 2 then
            return false
        end
        -- New position and size
        local new_pos, new_size = get_merged_bounds(pos, own_ships_conflicts)
        if not is_acceptable_size(new_size) then
            return false
        end
        -- New cockpit position
        local new_cockpit_pos = nil
        if n_cockpits == 1 then
            new_cockpit_pos = find_new_cockpit_pos(new_pos, own_ships_conflicts)
        end
        -- New ship
        local new_ship = {
            owner = name, state = "node", size = new_size, pos = new_pos,
            cockpit_pos = new_cockpit_pos, A = {}, A2 = {}
        }
        -- Add nodes from other ships
        for index, conflict in ipairs(own_ships_conflicts) do
            map_ship_into_another(conflict.ship, new_ship)
        end
        -- Only now try to put the new node
        if try_put_node_in_ship(node, pos, new_ship) then
            for index, conflict in ipairs(own_ships_conflicts) do
                remove_ship_from_list(conflict.ship, player_ship_list)
            end
            new_ship.index = #player_ship_list+1
            player_ship_list[new_ship.index] = new_ship
            return true
        else
            return false
        end
    else -- ... and case 4
        local new_ship = {
            owner = name, state = "node", size = {x=1, y=1, z=1}, pos = pos,
            cockpit_pos = nil, A = {}, A2 = {}
        }
        if try_put_node_in_ship(node, pos, new_ship) then
            new_ship.index = #player_ship_list+1
            player_ship_list[new_ship.index] = new_ship
            return true
        else
            return false
        end
    end
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
