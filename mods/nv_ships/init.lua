--[[
NV Ships adds the ability to build a boardable, flying ship using a fixed set of
nodes. Whenever a player adds a new node to a ship of their own, the node is
registered as part of the ship, which has its constituent nodes stored separate
from the world. Then, actions like boarding, unboarding, lifting off, landing...
are implemented as operations that modify ship state, or apply changes in the
world depending on it.
Included files:
    util.lua            Utility functions for callbacks and player manipulation
    ship.lua            Wrapper around ship objects: building and conversion
    control.lua         Code to connect user input with ship behavior
    nodetypes.lua       Defines all node types that can be used in ships

 # INDEX
    DEBUG CODE
]]--

-- Namespace for all the API functions
nv_ships = {}

dofile(minetest.get_modpath("nv_ships") .. "/util.lua")
dofile(minetest.get_modpath("nv_ships") .. "/ship.lua")
dofile(minetest.get_modpath("nv_ships") .. "/control.lua")
dofile(minetest.get_modpath("nv_ships") .. "/nodetypes.lua")

--[[
 # DEBUG CODE
]]

local function pos_to_string(pos, separator)
    separator = separator or ","
    if pos == nil then
        return "nil"
    end
    return string.format("%d%s%d%s%d", pos.x, separator, pos.y, separator, pos.z)
end

-- Register a debug command: /ships
minetest.register_chatcommand("ships", {
    params = "",
    description = "Ships: list current player's ships",
    func = function (name, param)
        local player = minetest.get_player_by_name(name)
        if player == nil then
            return false, "Player not found"
        end
        local n_ships = 0
        if nv_ships.players_list[name] ~= nil
        and nv_ships.players_list[name].ships ~= nil then
            n_ships = #nv_ships.players_list[name].ships
        end
        minetest.chat_send_player(name, string.format(
            "%s has %d ship(s)", name, n_ships
        ))
        if nv_ships.players_list[name] ~= nil
        and nv_ships.players_list[name].ships ~= nil then
            for index, ship in ipairs(nv_ships.players_list[name].ships) do
                minetest.chat_send_player(name, string.format(
                    "  %d. made of %s, size %s at (%s); cockpit (%s), facing %d, data [%d] [%d]",
                    ship.index, ship.state,
                    pos_to_string(ship.size, "x"),
                    pos_to_string(ship.pos),
                    pos_to_string(ship.cockpit_pos),
                    ship.facing or -1,
                    #ship.An, #ship.A2
                ))
            end
        end
    end
})
