--[[
This file defines worker functions that are called from the node callbacks in
'nodetypes.lua', and serve two functions. First, they communicate the ability to
perform certain actions (e.g. whether a certain node can be placed somewhere) by
means of their return values. Second, they update ship data (see 'ship.lua' for
more details) according to the changes made to ship nodes.

 # INDEX
    ADDING NODE
    ADDING HULL
    REMOVING NODE
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
        ship.facing = node.param2 % 4
    end
    -- Place it
    local x_stride = ship.size.x
    local y_stride = ship.size.y
    local k = rel_pos.z*y_stride*x_stride + rel_pos.y*x_stride + rel_pos.x + 1
    ship.An[k] = node.name
    ship.A2[k] = node.param2
    nv_ships.global_check_ship(ship)
    return true
end

-- Tries to change scaffold node to hull node, knowing that
-- the target node is inside one of the placing player's ships
-- Will update ship data as required
-- Returns the new node, or 'nil' if failed.
local function try_put_hull_in_ship(index, pos, ship)
    local node = minetest.get_node(pos)
    local rel_pos = {
        x = pos.x - ship.pos.x,
        y = pos.y - ship.pos.y,
        z = pos.z - ship.pos.z
    }
    local x_stride = ship.size.x
    local y_stride = ship.size.y
    local k = rel_pos.z*y_stride*x_stride + rel_pos.y*x_stride + rel_pos.x + 1
    -- Check node and place it
    local allowed_nodes = {
        ["nv_ships:scaffold"] = true,
    }
    if allowed_nodes[node.name] ~= nil then
        ship.An[k] = ship.An[k] .. "_hull" .. index
        nv_ships.global_check_ship(ship)
        return {name=ship.An[k], param1=8, param2=ship.A2[k]}
    end
    return nil
end

-- Takes all node ID and param2 data from a ship and copies it to another
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
                destination.An[k_d] = source.An[k_s]
                destination.A2[k_d] = source.A2[k_s]
                k_s = k_s + 1
            end
        end
    end
    -- Clear trailing elements
    local length = destination.size.x*destination.size.y*destination.size.z
    for k_d=length+1, #destination.An do
        destination.An[k_d] = nil
        destination.A2[k_d] = nil
    end
end

local function remove_ship_from_list(ship, list)
    table.remove(list, ship.index)
    for index=ship.index, #list do
        list[index].index = index
    end
end

local function init_ship_nodes(ship)
    for k=0, ship.size.x*ship.size.y*ship.size.z do
        ship.An[k] = ""
        ship.A2[k] = 0
    end
    nv_ships.global_check_ship(ship)
end

-- Tries to shrink the ship bounding box as much as possible
-- while preserving all nodes contained inside it
local function shrink_ship_to_content(ship)
    local min_plane_is_empty = {x=true, y=true, z=true}
    local max_plane_is_empty = {x=true, y=true, z=true}
    local x_stride = ship.size.x
    local y_stride = ship.size.y
    local k = 1
    for rel_z=0, ship.size.z - 1 do
        for rel_y=0, ship.size.y - 1 do
            for rel_x=0, ship.size.x - 1 do
                if ship.An[k] ~= "" then
                    if rel_x == 0 then min_plane_is_empty.x = false end
                    if rel_y == 0 then min_plane_is_empty.y = false end
                    if rel_z == 0 then min_plane_is_empty.z = false end
                    if rel_x == ship.size.x - 1 then max_plane_is_empty.x = false end
                    if rel_y == ship.size.y - 1 then max_plane_is_empty.y = false end
                    if rel_z == ship.size.z - 1 then max_plane_is_empty.z = false end
                end
                k = k + 1
            end
        end
    end
    -- Operate on a temporary new ship
    local new_ship = {
        owner = ship.owner, state = "node", size = table.copy(ship.size), pos = table.copy(ship.pos),
        cockpit_pos = ship.cockpit_pos, facing = ship.facing, An = {}, A2 = {}
    }
    init_ship_nodes(new_ship)
    if min_plane_is_empty.x then new_ship.size.x = new_ship.size.x - 1 end
    if min_plane_is_empty.y then new_ship.size.y = new_ship.size.y - 1 end
    if min_plane_is_empty.z then new_ship.size.z = new_ship.size.z - 1 end
    if min_plane_is_empty.x then new_ship.pos.x = new_ship.pos.x + 1 end
    if min_plane_is_empty.y then new_ship.pos.y = new_ship.pos.y + 1 end
    if min_plane_is_empty.z then new_ship.pos.z = new_ship.pos.z + 1 end
    if max_plane_is_empty.x then new_ship.size.x = new_ship.size.x - 1 end
    if max_plane_is_empty.y then new_ship.size.y = new_ship.size.y - 1 end
    if max_plane_is_empty.z then new_ship.size.z = new_ship.size.z - 1 end

    map_ship_into_another(ship, new_ship)

    -- Copy to input ship
    ship.size = new_ship.size
    ship.pos = new_ship.pos
    ship.An = new_ship.An
    ship.A2 = new_ship.A2

    if ship.size.x <= 0 or ship.size.y <= 0 or ship.size.z <= 0 then
        local list = nv_ships.players_list[ship.owner].ships
        remove_ship_from_list(ship, list)
    end
end

-- Tries to remove node from world position that happens to be inside ship
-- Or turn hull node into non-hull node
-- Will update ship data as required
-- Returns 'false' if the node can't be removed, 'true' otherwise
local function try_remove_node_from_ship(node, pos, ship)
    local rel_pos = {
        x = pos.x - ship.pos.x,
        y = pos.y - ship.pos.y,
        z = pos.z - ship.pos.z
    }
    -- Check node
    if node.name == "nv_ships:seat" then
        ship.cockpit_pos = nil
        ship.facing = node.param2 % 4
    end
    -- Remove it
    local x_stride = ship.size.x
    local y_stride = ship.size.y
    local k = rel_pos.z*y_stride*x_stride + rel_pos.y*x_stride + rel_pos.x + 1
    ship.An[k] = ""
    -- Check if hull
    local start = string.find(node.name, "_hull%d*")
    if start ~= nil then
        local new_name = string.sub(node.name, 0, start-1)
        ship.An[k] = new_name
    end
    -- Resize as needed
    shrink_ship_to_content(ship)
    nv_ships.global_check_ship(ship)
    return true
end

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

--[[
 # ADDING NODE
Attempts to add a node to one of the placing player's ships, or start a new one.
The node is not physically placed in the world, but ships are updated.
Returns 'true' or 'false' to signal success or failure, respectively.
]]
function nv_ships.try_add_node(node, pos, player)
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

    local function get_merged_bounds(conflicts)
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
                }, ship.facing
            end
        end
        return nil
    end

    ----------------------------------------------------------------------------

    local name = player:get_player_name()
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
        local new_pos, new_size = get_merged_bounds(own_ships_conflicts)
        if not is_acceptable_size(new_size) then
            return false
        end
        -- New cockpit position
        local new_cockpit_pos = nil
        local new_facing = nil
        if n_cockpits == 1 then
            new_cockpit_pos, new_facing = find_new_cockpit_pos(new_pos, own_ships_conflicts)
        end
        -- New ship
        local new_ship = {
            owner = name, state = "node", size = new_size, pos = new_pos,
            cockpit_pos = new_cockpit_pos, facing = new_facing, An = {}, A2 = {}
        }
        init_ship_nodes(new_ship)
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
            cockpit_pos = nil, facing = nil, An = {}, A2 = {}
        }
        init_ship_nodes(new_ship)
        if try_put_node_in_ship(node, pos, new_ship) then
            new_ship.index = #player_ship_list+1
            player_ship_list[new_ship.index] = new_ship
            return true
        else
            return false
        end
    end
end

--[[
 # ADDING HULL
Attempts to turn a scaffold-related block from one of the player's ships into a
hull block, depending on the passed hull color index.
Returns the new node, or 'nil' if failed.
]]
function nv_ships.try_add_hull(node, pos, player, index)
    local name = player:get_player_name()
    local player_ship_list = nv_ships.players_list[name].ships
    local own_ships_conflicts = {}
    find_conflicts(own_ships_conflicts, pos, player_ship_list)
    if #own_ships_conflicts == 1 and is_inside(own_ships_conflicts[1].conflict) then
        return try_put_hull_in_ship(index, pos, own_ships_conflicts[1].ship)
    end
    return nil
end

--[[
 # REMOVING NODE
]]

function nv_ships.can_dig_node(pos, player)
    local name = player:get_player_name()
    local player_ship_list = nv_ships.players_list[name].ships
    local own_ships_conflicts = {}
    find_conflicts(own_ships_conflicts, pos, player_ship_list)
    if #own_ships_conflicts == 1 and is_inside(own_ships_conflicts[1].conflict) then
        return true
    end
    return false
end

--[[
Attempts to remove a node that should belong to one of the player's ships
If the node is a hull node, it is replaced with its non-hull equivalent
Returns the new node, or 'nil' if failed.
]]
function nv_ships.try_remove_node(node, pos, player, index)
    local name = player:get_player_name()
    local player_ship_list = nv_ships.players_list[name].ships
    local own_ships_conflicts = {}
    find_conflicts(own_ships_conflicts, pos, player_ship_list)
    if #own_ships_conflicts == 1 and is_inside(own_ships_conflicts[1].conflict) then
        return try_remove_node_from_ship(node, pos, own_ships_conflicts[1].ship)
    end
    return nil
end
