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
    if minetest.get_item_group(node.name, "pilot_seat") > 0 and ship.cockpit_pos ~= nil then
        return false
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

-- Changes a node at an absolute position in the world,
-- updating the ship accordingly
function nv_ships.set_ship_node(node, pos, ship)
    local rel_pos = {
        x = pos.x - ship.pos.x,
        y = pos.y - ship.pos.y,
        z = pos.z - ship.pos.z
    }
    local x_stride = ship.size.x
    local y_stride = ship.size.y
    local k = rel_pos.z*y_stride*x_stride + rel_pos.y*x_stride + rel_pos.x + 1
    
    ship.An[k] = node.name
    ship.A2[k] = node.param2
    nv_ships.global_check_ship(ship)
    minetest.set_node(pos, node)
end

-- Tries to change scaffold node to hull node, knowing that
-- the target node is inside one of the placing player's ships
-- Will update ship data as required
-- Returns the new node, or 'nil' if failed.
local function try_put_hull_in_ship(index, pos, ship)
    local node = minetest.get_node(pos)
    -- Check node and place it
    if minetest.get_item_group(node.name, "ship_scaffold") > 0 then
        node.name = node.name .. "_hull" .. index
        nv_ships.set_ship_node(node, pos, ship)
        return node
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
    local min_z = math.max(0, rel_pos_d.z)
    local min_y = math.max(0, rel_pos_d.y)
    local min_x = math.max(0, rel_pos_d.x)
    local max_z = math.min(source.size.z + rel_pos_d.z, destination.size.z) - 1
    local max_y = math.min(source.size.y + rel_pos_d.y, destination.size.y) - 1
    local max_x = math.min(source.size.x + rel_pos_d.x, destination.size.x) - 1
    local x_stride_d = destination.size.x
    local y_stride_d = destination.size.y
    local x_stride_s = source.size.x
    local y_stride_s = source.size.y
    for rel_z_d=min_z, max_z, 1 do
        local rel_z_s = rel_z_d - rel_pos_d.z
        for rel_y_d=min_y, max_y, 1 do
            local rel_y_s = rel_y_d - rel_pos_d.y
            for rel_x_d=min_x, max_x, 1 do
                local rel_x_s = rel_x_d - rel_pos_d.x
                local k_s = rel_z_s*y_stride_s*x_stride_s + rel_y_s*x_stride_s + rel_x_s + 1
                local k_d = rel_z_d*y_stride_d*x_stride_d + rel_y_d*x_stride_d + rel_x_d + 1
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

-- Removes a ship from its owner's ship list and updates all indices
-- Note that it will not work with any other list, only the owner's
local function remove_ship_from_list(ship)
    local list = nv_ships.players_list[ship.owner].ships
    if ship.index == nil then
        return -- Detached ships don't matter
    end
    table.remove(list, ship.index)
    for index=ship.index, #list do
        list[index].index = index
    end
end

-- Initializes nodes of a ship to an empty, default value
-- Requires that the ship's size be known
local function init_ship_nodes(ship)
    for k=0, ship.size.x*ship.size.y*ship.size.z do
        ship.An[k] = ""
        ship.A2[k] = 0
    end
    -- nv_ships.global_check_ship(ship)
end

-- Tries to shrink the ship bounding box as much as possible
-- while preserving all nodes contained inside it
local function shrink_ship_to_content(ship)
    -- Operate on a temporary new ship
    local new_ship = {
        owner = ship.owner, state = "node", size = table.copy(ship.size), pos = table.copy(ship.pos),
        cockpit_pos = ship.cockpit_pos, facing = ship.facing, An = {}, A2 = {}
    }
    local did_shrink = false
    repeat -- Repeat the following until the ship can't be shrunk anymore
        -- Probably not the best possible way to implement this...
        did_shrink = false
        local min_plane_is_empty = {x=true, y=true, z=true}
        local max_plane_is_empty = {x=true, y=true, z=true}
        local x_stride = ship.size.x
        local y_stride = ship.size.y
        local min_z = new_ship.pos.z - ship.pos.z
        local min_y = new_ship.pos.y - ship.pos.y
        local min_x = new_ship.pos.x - ship.pos.x
        local max_z = min_z + new_ship.size.z - 1
        local max_y = min_y + new_ship.size.y - 1
        local max_x = min_x + new_ship.size.x - 1
        for rel_z=min_z, max_z do
            for rel_y=min_y, max_y do
                for rel_x=min_x, max_x do
                    local k = rel_z*y_stride*x_stride + rel_y*x_stride + rel_x + 1
                    if ship.An[k] ~= "" then
                        if rel_x == min_x then min_plane_is_empty.x = false end
                        if rel_y == min_y then min_plane_is_empty.y = false end
                        if rel_z == min_z then min_plane_is_empty.z = false end
                        if rel_x == max_x then max_plane_is_empty.x = false end
                        if rel_y == max_y then max_plane_is_empty.y = false end
                        if rel_z == max_z then max_plane_is_empty.z = false end
                    else
                    end
                end
            end
        end
        if min_plane_is_empty.x then new_ship.size.x = new_ship.size.x - 1 did_shrink = true end
        if min_plane_is_empty.y then new_ship.size.y = new_ship.size.y - 1 did_shrink = true end
        if min_plane_is_empty.z then new_ship.size.z = new_ship.size.z - 1 did_shrink = true end
        if new_ship.size.x * new_ship.size.y * new_ship.size.z == 0 then
            break
        end
        if min_plane_is_empty.x then new_ship.pos.x = new_ship.pos.x + 1 did_shrink = true end
        if min_plane_is_empty.y then new_ship.pos.y = new_ship.pos.y + 1 did_shrink = true end
        if min_plane_is_empty.z then new_ship.pos.z = new_ship.pos.z + 1 did_shrink = true end
        if max_plane_is_empty.x then new_ship.size.x = new_ship.size.x - 1 did_shrink = true end
        if max_plane_is_empty.y then new_ship.size.y = new_ship.size.y - 1 did_shrink = true end
        if max_plane_is_empty.z then new_ship.size.z = new_ship.size.z - 1 did_shrink = true end
    until not did_shrink or new_ship.size.x * new_ship.size.y * new_ship.size.z == 0
    init_ship_nodes(new_ship)

    map_ship_into_another(ship, new_ship)

    -- Copy to input ship
    ship.size = new_ship.size
    ship.pos = new_ship.pos
    ship.An = new_ship.An
    ship.A2 = new_ship.A2

    if ship.size.x <= 0 or ship.size.y <= 0 or ship.size.z <= 0 then
        remove_ship_from_list(ship)
    end
end

--[[
Given an absolute node position that has been removed from the ship, it tries to
split the remaining nodes into as many non-adjacent new ships as possible.
]]--
local function try_split_ship_by_node(pos, ship)

    -- Returns whether the particular quadrant plane contains any node
    local function try_plane(X, Y, Z)
        local rel_pos = {
            x = pos.x - ship.pos.x,
            y = pos.y - ship.pos.y,
            z = pos.z - ship.pos.z
        }
        local min_z = rel_pos.z
        if Z == -1 then min_z = 0 end
        local min_y = rel_pos.y
        if Y == -1 then min_y = 0 end
        local min_x = rel_pos.x
        if X == -1 then min_x = 0 end
        local max_z = rel_pos.z
        if Z == 1 then max_z = ship.size.z - 1 end
        local max_y = rel_pos.y
        if Y == 1 then max_y = ship.size.y - 1 end
        local max_x = rel_pos.x
        if X == 1 then max_x = ship.size.x - 1 end
        local x_stride = ship.size.x
        local y_stride = ship.size.y
        for rel_z=min_z, max_z do
            for rel_y=min_y, max_y do
                for rel_x=min_x, max_x do
                    local k = rel_z*y_stride*x_stride + rel_y*x_stride + rel_x + 1
                    if ship.An[k] ~= "" then
                        return true
                    end
                end
            end
        end
        return false
    end

    -- Checks whether two bounding boxes can be merged
    local function check_merge(bounding_box_a, bounding_box_b, separation_planes)
        local shared_volume = {
            min = {
                x = math.max(bounding_box_a.min.x, bounding_box_b.min.x),
                y = math.max(bounding_box_a.min.y, bounding_box_b.min.y),
                z = math.max(bounding_box_a.min.z, bounding_box_b.min.z)
            },
            max = {
                x = math.min(bounding_box_a.max.x, bounding_box_b.max.x),
                y = math.min(bounding_box_a.max.y, bounding_box_b.max.y),
                z = math.min(bounding_box_a.max.z, bounding_box_b.max.z)
            },
        }
        if shared_volume.max.x > shared_volume.min.x
        and shared_volume.max.y > shared_volume.min.y
        and shared_volume.max.z > shared_volume.min.z then
            return true -- Bounding boxes overlap, can always merge in this case
        end
        if math.abs(shared_volume.max.x - shared_volume.min.x)
        + math.abs(shared_volume.max.y - shared_volume.min.y)
        + math.abs(shared_volume.max.z - shared_volume.min.z)
        == 2 then -- The two boxes share a plane
            -- If any of the quadrant planes in the contact surface between boxes
            -- is true in 'separation_planes', return true
            local min_z = shared_volume.min.z
            if min_z and shared_volume.max.z == 1 then
                min_z = 1
            end
            local min_y = shared_volume.min.y
            if min_y == 0 and shared_volume.max.y == 1 then
                min_y = 1
            end
            local min_x = shared_volume.min.x
            if min_x == 0 and shared_volume.max.x == 1 then
                min_x = 1
            end
            for Z=min_z, shared_volume.max.z, 2 do
                for Y=min_y, shared_volume.max.y, 2 do
                    for X=min_x, shared_volume.max.x, 2 do
                        if separation_planes[X][Y][Z] then
                            return true
                        end
                    end
                end
            end
            -- Fall through
        end
        return false
    end

    -- Input    Output
    -- -1       Relative coordinate origin
    -- 0        Coordinate given as 'pos'
    -- 1        Corner opposite to origin
    local function translate_ternary_to_relative(value, component_name)
        if value == 0 then return pos[component_name] - ship.pos[component_name]
        elseif value == 1 then return ship.size[component_name] - 1
        else return 0 end
    end

    -- Take a fragment of 'ship' as defined by the ternary coordinates in
    -- 'bounding_box' and make it into a new, fully checked but detached ship.
    -- Returns 'nil' if there are no nodes in the specified box.
    local function translate_to_ship(bounding_box)
        local relative_bounding_box = {
            min = {
                x = translate_ternary_to_relative(bounding_box.min.x, "x"),
                y = translate_ternary_to_relative(bounding_box.min.y, "y"),
                z = translate_ternary_to_relative(bounding_box.min.z, "z")
            },
            max = {
                x = translate_ternary_to_relative(bounding_box.max.x, "x"),
                y = translate_ternary_to_relative(bounding_box.max.y, "y"),
                z = translate_ternary_to_relative(bounding_box.max.z, "z")
            }
        }
        local new_ship = {
            owner = ship.owner, index = nil, state = "node",
            size = {
                x = relative_bounding_box.max.x - relative_bounding_box.min.x + 1,
                y = relative_bounding_box.max.y - relative_bounding_box.min.y + 1,
                z = relative_bounding_box.max.z - relative_bounding_box.min.z + 1
            },
            pos = {
                x = ship.pos.x + relative_bounding_box.min.x,
                y = ship.pos.y + relative_bounding_box.min.y,
                z = ship.pos.z + relative_bounding_box.min.z
            },
            An = {}, A2 = {}
        }
        init_ship_nodes(new_ship)
        map_ship_into_another(ship, new_ship)
        shrink_ship_to_content(new_ship)
        if new_ship.size.x * new_ship.size.y * new_ship.size.z == 0 then
            return nil
        end
        nv_ships.global_check_ship(new_ship)
        return new_ship
    end

    ----------------------------------------------------------------------------

    -- All the small quadrant planes separating octants
    local separation_planes = {
        [0] = {
            [-1] = {[-1] = try_plane(0, -1, -1), [1] = try_plane(0, -1, 1)},
            [1] = {[-1] = try_plane(0, 1, -1), [1] = try_plane(0, 1, 1)}
        },
        [-1] = {
            [0] = {[-1] = try_plane(-1, 0, -1), [1] = try_plane(-1, 0, 1)},
            [-1] = {[0] = try_plane(-1, -1, 0)},
            [1] = {[0] = try_plane(-1, 1, 0)}
        },
        [1] = {
            [0] = {[-1] = try_plane(1, 0, -1), [1] = try_plane(1, 0, 1)},
            [-1] = {[0] = try_plane(1, -1, 0)},
            [1] = {[0] = try_plane(1, 1, 0)}
        }
    }
    -- The starting bounding boxes are just the 8 octants
    local bounding_boxes = {
        {min = {x = -1, y = -1, z = -1}, max = {x = 0, y = 0, z = 0}},
        {min = {x = -1, y = -1, z = 0}, max = {x = 0, y = 0, z = 1}},
        {min = {x = -1, y = 0, z = -1}, max = {x = 0, y = 1, z = 0}},
        {min = {x = -1, y = 0, z = 0}, max = {x = 0, y = 1, z = 1}},
        {min = {x = 0, y = -1, z = -1}, max = {x = 1, y = 0, z = 0}},
        {min = {x = 0, y = -1, z = 0}, max = {x = 1, y = 0, z = 1}},
        {min = {x = 0, y = 0, z = -1}, max = {x = 1, y = 1, z = 0}},
        {min = {x = 0, y = 0, z = 0}, max = {x = 1, y = 1, z = 1}}
    }
    -- Now merge bounding boxes whenever a plane with nodes lies between them
    local failed_attempts_in_a_row = 0
    while failed_attempts_in_a_row <= #bounding_boxes do
        -- Try each element, adding it to the end of the list, until
        -- all elements have been tried without a single merge
        local go_on = #bounding_boxes >= 2
        local did_merge = false
        repeat -- Repeat until we can't merge anymore
            did_merge = false
            local n = 2
            while n <= #bounding_boxes do -- Attempt merge with all others
                if check_merge(bounding_boxes[1], bounding_boxes[n], separation_planes) then
                    did_merge = true
                    failed_attempts_in_a_row = 0
                    bounding_boxes[1] = {
                        min = {
                            x = math.min(bounding_boxes[1].min.x, bounding_boxes[n].min.x),
                            y = math.min(bounding_boxes[1].min.y, bounding_boxes[n].min.y),
                            z = math.min(bounding_boxes[1].min.z, bounding_boxes[n].min.z)
                        },
                        max = {
                            x = math.max(bounding_boxes[1].max.x, bounding_boxes[n].max.x),
                            y = math.max(bounding_boxes[1].max.y, bounding_boxes[n].max.y),
                            z = math.max(bounding_boxes[1].max.z, bounding_boxes[n].max.z)
                        }
                    }
                    table.remove(bounding_boxes, n)
                else
                    n = n + 1
                end
            end
        until not did_merge
        -- Move to end of list
        table.insert(bounding_boxes, table.remove(bounding_boxes, 1))
        failed_attempts_in_a_row = failed_attempts_in_a_row + 1
    end
    -- Construct ships from bounding boxes
    local output_ships = {}
    for _, bounding_box in ipairs(bounding_boxes) do
        local new_ship = translate_to_ship(bounding_box)
        if new_ship ~= nil then
            table.insert(output_ships, new_ship)
        end
    end
    return output_ships
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
    -- Resize or split as needed, update player's ship list
    local owner_name = ship.owner
    local original_index = ship.index
    local new_ships = try_split_ship_by_node(pos, ship)
    if #new_ships >= 1 then
        new_ships[1].index = original_index
        nv_ships.players_list[owner_name].ships[original_index] = new_ships[1]
        if #new_ships >= 2 then
            for n=2, #new_ships do
                table.insert(nv_ships.players_list[owner_name].ships, new_ships[n])
                new_ships[n].index = #nv_ships.players_list[owner_name].ships
            end
        end
    else
        remove_ship_from_list(nv_ships.players_list[owner_name].ships[original_index])
    end
    return true
end

-- Gets a node position ('pos') and tries to find all instances where the node
-- is inside, or adjacent to, one of the given ships' bounding box. Appends all
-- found conflicts to 'conflicts', as tables containing 'ship' and 'conflict':
-- the ship which bounding box is in conflict, and a vector indicating the
-- relative position of 'pos' with it (all zero for inside, one coordinate set
-- to 1 for adjacent to a face, etc. See 'compute_box_conflict()').
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

function nv_ships.get_owned_ship_at(pos, player)
    local name = player:get_player_name()
    local player_ship_list = nv_ships.players_list[name].ships
    local own_ships_conflicts = {}
    find_conflicts(own_ships_conflicts, pos, player_ship_list)
    if #own_ships_conflicts == 1 and is_inside(own_ships_conflicts[1].conflict) then
        return own_ships_conflicts[1].ship
    end
    return nil
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

    -- Count number of cockpits across all ships in a conflict list
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

    -- Get position and size that would result from merging the bounding boxes
    -- of all ships in 'conflicts' into a single bounding box
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

    -- Check if a certain size is appropriate for a spaceship
    -- Maximum size is arbitrarily set to 15x15x15; while the code should be
    -- able to handle much more than that, it's useful to have a maximum so:
    -- * Players can build hangars, landing platforms, etc. for other people's
    --   ships, regardless of their size.
    -- * Server-wide performance issues are harder to trigger by just building
    --   very large ships.
    -- * It's harder to completely enclose someone else's ship with one's own.
    --   Although this could be worked around more gracefully (TODO).
    local function is_acceptable_size(size)
        return size.x <= 15 and size.y <= 15 and size.y <= 15
    end

    -- Find the one cockpit among all ships in 'conflicts', and return its
    -- position relative to 'relative_to'
    -- Retained only as a means to check if *any* of the ships has a cockpit
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
    -- Check case 1 (inside bounding box of own ship)
    if #own_ships_conflicts == 1 and is_inside(own_ships_conflicts[1].conflict) then
        return try_put_node_in_ship(node, pos, own_ships_conflicts[1].ship)
    end

    local other_ships_conflicts = {}
    for name2, player in pairs(nv_ships.players_list) do
        if name2 ~= name then
            find_conflicts(other_ships_conflicts, pos, player.ships)
        end
    end
    -- Check case 2 (inside or adjacent to other players' ships)
    if #other_ships_conflicts >= 1 then
        return false
    end
    -- Check case 3 (adjacent to (any number of) own ship(s))
    -- Those ships will be merged into a single ship
    -- TODO: don't allow merging when that would overlap another player's ship
    if #own_ships_conflicts >= 1 then
        local n_cockpits = count_cockpits_up_to_two(own_ships_conflicts)
        if n_cockpits >= 2 then
            return false -- Can't have more than one cockpit in final result
        end
        -- New position and size
        local new_pos, new_size = get_merged_bounds(own_ships_conflicts)
        if not is_acceptable_size(new_size) then
            return false -- Can't exceed acceptable size limits
        end
        -- New cockpit position
        local new_cockpit_pos = nil
        local new_facing = nil
        if n_cockpits == 1 then
            new_cockpit_pos, new_facing = find_new_cockpit_pos(new_pos, own_ships_conflicts)
        end
        -- Create new, empty ship
        local new_ship = {
            owner = name, state = "node", size = new_size, pos = new_pos,
            cockpit_pos = new_cockpit_pos, facing = new_facing, An = {}, A2 = {}
        }
        init_ship_nodes(new_ship)
        -- Add nodes from other ships into merged ship
        for index, conflict in ipairs(own_ships_conflicts) do
            map_ship_into_another(conflict.ship, new_ship)
        end
        -- Only now try to put the new node
        if try_put_node_in_ship(node, pos, new_ship) then
            -- Succeeded, commit the merge
            for index, conflict in ipairs(own_ships_conflicts) do
                remove_ship_from_list(conflict.ship)
            end
            new_ship.index = #player_ship_list+1
            player_ship_list[new_ship.index] = new_ship
            return true
        else
            return false
        end
    else -- ... and case 4 (away from any existing ships)
        -- A new ship will be created
        local new_ship = {
            owner = name, state = "node", size = {x=1, y=1, z=1}, pos = pos,
            cockpit_pos = nil, facing = nil, An = {}, A2 = {}
        }
        init_ship_nodes(new_ship)
        if try_put_node_in_ship(node, pos, new_ship) then
            -- Node placement succeeded, commit single-node ship
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
    local ship = nv_ships.get_owned_ship_at(pos, player)
    if ship ~= nil then
        return try_put_hull_in_ship(index, pos, ship)
    end
    return nil
end

--[[
 # REMOVING NODE
]]

function nv_ships.can_dig_node(pos, player)
    return nv_ships.get_owned_ship_at(pos, player) ~= nil
end

--[[
Attempts to remove a node that should belong to one of the player's ships
If the node is a hull node, it is replaced with its non-hull equivalent
Returns the new node, or 'nil' if failed.
]]
function nv_ships.try_remove_node(node, pos, player, index)
    local ship = nv_ships.get_owned_ship_at(pos, player)
    if ship ~= nil then
        return try_remove_node_from_ship(node, pos, ship)
    end
    return nil
end
