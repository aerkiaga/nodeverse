--[[
This file contains functions that scan all of a ship's nodes to modify them in
certain ways or compute global properties for the ship. In particular, they
ensure that all nodes respect orientation constraints, so the player has to
worry as little as possible about properly orienting them, and also check
whether the ship is appropriately built and should be allowed to take off.

 # INDEX
    GLOBAL CHECK
]]

--[[
 # GLOBAL CHECK

Entry point for all the functions in this file.
]]--

function nv_ships.global_check_ship(ship)
    ship.cockpit_pos = nil
    ship.facing = nil
    local k = 1
    for rel_z=0, ship.size.z - 1 do
        for rel_y=0, ship.size.y - 1 do
            for rel_x=0, ship.size.x - 1 do
                -- If a pilot seat is found, assign a cockpit to the ship
                if ship.An[k] == "nv_ships:seat" then
                    ship.cockpit_pos = {
                        x = rel_x, y = rel_y, z = rel_z
                    }
                    ship.facing = ship.A2[k]
                end
                k = k + 1
            end
        end
    end
end
