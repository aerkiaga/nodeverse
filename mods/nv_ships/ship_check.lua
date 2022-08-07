--[[
This file contains functions that scan all of a ship's nodes to modify them in
certain ways or compute global properties for the ship. In particular, they
ensure that all nodes respect orientation constraints, so the player has to
worry as little as possible about properly orienting them, and also check
whether the ship is appropriately built and should be allowed to take off.

 # INDEX
    GLOBAL CHECK
]]

local function compute_values_for_glass_node(neighbors)

    local function rotate_x(n)
        n.ym, n.zm, n.y0, n.z0 = n.zm, n.y0, n.z0, n.ym
    end

    local function rotate_y(n)
        n.xm, n.z0, n.x0, n.zm = n.z0, n.x0, n.zm, n.xm
    end

    local function rotate_z(n)
        n.xm, n.ym, n.x0, n.y0 = n.ym, n.x0, n.y0, n.xm
    end

    local function count_differences(na, nb)
        local r = 0
        if na.x0 ~= nb.x0 then r = r + 1 end
        if na.xm ~= nb.xm then r = r + 1 end
        if na.y0 ~= nb.y0 then r = r + 1 end
        if na.ym ~= nb.ym then r = r + 1 end
        if na.z0 ~= nb.z0 then r = r + 1 end
        if na.zm ~= nb.zm then r = r + 1 end
        return r
    end

    -- axis 1 is y, 2 is z, 3 is x; rotations follow right-hand rule
    local function axis_and_rotation_to_facedir(xrot, yrot)
        -- OTHER STUFF (for reference)
        --      rotation
        -- axis  0  1  2  3
        --   X   0  8 22  4
        --   Y   0  3  2  1
        --   Z   0 12 20 16
        local translation_table = {
            [0] = {[0] = 0, 3, 2, 1},
            {[0] = 8, 15, 6, 17},
            {[0] = 22, 23, 20, 21},
            {[0] = 4, 19, 10, 13}
        }
        return translation_table[xrot][yrot]
    end

    ----------------------------------------------------------------------------

    local rn, r2
    -- Count the number of axes where one side is covered and the other isn't
    -- This is used to choose glass node shape
    local num_partial_axes = 0
    if neighbors.x0 ~= neighbors.xm then num_partial_axes = num_partial_axes + 1 end
    if neighbors.y0 ~= neighbors.ym then num_partial_axes = num_partial_axes + 1 end
    if neighbors.z0 ~= neighbors.zm then num_partial_axes = num_partial_axes + 1 end
    local current_neighbors = nil
    local xrot_max, xrot_step, yrot_max
    if num_partial_axes <= 1 then
        rn = "nv_ships:glass_face"
        current_neighbors = {
            x0 = true, xm = true, y0 = true, ym = true, z0 = false, zm = false
        }
        xrot_max, xrot_step, yrot_max = 1, 1, 1
    elseif num_partial_axes == 2 then
        rn = "nv_ships:glass_edge"
        current_neighbors = {
            x0 = false, xm = true, y0 = true, ym = true, z0 = false, zm = true
        }
        xrot_max, xrot_step, yrot_max = 3, 1, 3
    else
        rn = "nv_ships:glass_vertex"
        current_neighbors = {
            x0 = false, xm = true, y0 = false, ym = true, z0 = false, zm = true
        }
        xrot_max, xrot_step, yrot_max = 2, 2, 3
    end
    -- Now just brute-force every possible rotation
    local axis_functions = {
        rotate_y, rotate_z, rotate_x
    }
    local min_differences = 7
    local go_on = true
    local best_xrot, best_yrot
    for xrot=0, xrot_max, xrot_step do
        local saved_neighbors = table.copy(current_neighbors)
        for yrot=0, yrot_max do
            local differences = count_differences(current_neighbors, neighbors)
            if differences < min_differences then
                min_differences = differences
                best_xrot = xrot
                best_yrot = yrot
                if differences <= 1 then
                    go_on = false
                    break
                end
            end
            rotate_y(current_neighbors)
        end
        if not go_on then break end
        current_neighbors = saved_neighbors
        for n=1, xrot_step do
            rotate_x(current_neighbors)
        end
    end
    -- Translate the best combination to a param2
    -- TODO: axis + rotation can't represent all distinct orientations
    r2 = axis_and_rotation_to_facedir(best_xrot, best_yrot)
    return rn, r2
end

--[[
 # GLOBAL CHECK

Entry point for all the functions in this file.
]]--

function nv_ships.global_check_ship(ship)
    ship.cockpit_pos = nil
    ship.facing = nil
    local x_stride = ship.size.x
    local y_stride = ship.size.y
    local k = 1
    for rel_z=0, ship.size.z - 1 do
        for rel_y=0, ship.size.y - 1 do
            for rel_x=0, ship.size.x - 1 do
                -- If a pilot seat is found, assign a cockpit to the ship
                if minetest.get_item_group(ship.An[k], "pilot_seat") > 0 then
                    ship.cockpit_pos = {
                        x = rel_x, y = rel_y, z = rel_z
                    }
                    ship.facing = ship.A2[k]
                -- Make sure that all glass nodes are connected
                elseif ship.An[k] == "nv_ships:glass_face"
                or ship.An[k] == "nv_ships:glass_edge"
                or ship.An[k] == "nv_ships:glass_vertex" then
                    local neighbors_solid_status = {
                        x0 = rel_x > 0 and ship.An[k - 1] ~= "",
                        xm = rel_x < ship.size.x - 1 and ship.An[k + 1] ~= "",
                        y0 = rel_y > 0 and ship.An[k - x_stride] ~= "",
                        ym = rel_y < ship.size.y - 1 and ship.An[k + x_stride] ~= "",
                        z0 = rel_z > 0 and ship.An[k - x_stride*y_stride] ~= "",
                        zm = rel_z < ship.size.z - 1 and ship.An[k + x_stride*y_stride] ~= ""
                    }
                    ship.An[k], ship.A2[k] = compute_values_for_glass_node(neighbors_solid_status)
                    minetest.add_node({
                        x = rel_x + ship.pos.x,
                        y = rel_y + ship.pos.y,
                        z = rel_z + ship.pos.z
                    }, {
                        name = ship.An[k],
                        param1 = 15,
                        param2 = ship.A2[k]
                    })
                end
                k = k + 1
            end
        end
    end
end
