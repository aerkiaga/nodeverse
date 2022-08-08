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
    storage.lua         Persistent storage methods for all ship data
    nodetypes.lua       Defines all node types that can be used in ships
    itemtypes.lua       Defines item types that are not directy placeable

 # INDEX
    API REFERENCE
    DEBUG CODE
]]--

-- Namespace for all the API functions
nv_ships = {}

dofile(minetest.get_modpath("nv_ships") .. "/util.lua")
dofile(minetest.get_modpath("nv_ships") .. "/ship.lua")
dofile(minetest.get_modpath("nv_ships") .. "/control.lua")
dofile(minetest.get_modpath("nv_ships") .. "/storage.lua")
dofile(minetest.get_modpath("nv_ships") .. "/nodetypes.lua")
dofile(minetest.get_modpath("nv_ships") .. "/itemtypes.lua")

--[[
# API REFERENCE
Ships is a versatile structure building and ownership API featuring the ability
to construct and pilot moving structures.

At the moment, much of the functionality required by the game Nodeverse is
hardcoded. However, an API is still exposed and documented here.
]]--

--[[    nv_ships.nv_ships.ship_to_entity(ship, player, remove)
Spawns the ship in its entity form around a player. This involves attaching
many smaller entities, resembling the ship's nodes, to the player.
In order for this to be carried out, the ship needs to have a cockpit position,
that is, a node within it where the player will be seated.
    ship        a ship object; ownership makes no difference to this function
    player      player that the ship will be placed around
    remove      whether to remove any actual ship nodes; true by default
Note that 'remove' is only meaningful if the ship is being converted from node
form into entity form. By setting this to false, a new ship can be introduced
into the world.
]]

--[[    nv_ships.ship_to_node(ship, player, pos)
Spawns the ship in its node form around a world position. This involves copying
nodes stored in the ship object to the world.
Additionally, nv_ships.remove_ship_entity() will be called on 'player',
if provided. This is to facilitate operations such as landing.
The ship is placed at 'pos', relative to its cockpit position if present;
otherwise to the lowest coordinate node.
    ship        a ship object; ownership makes no difference to this function
    player      if present, the entity form will be removed from this player
    pos         location at which to place the ship
By not providing a 'player', a new structure can be introduced.
]]

--[[    nv_ships.remove_ship_entity(player)
Detach and remove any attached entities from a player.
    player      player to remove ship entity from
]]

--[[    nv_ships.rotate_ship_nodes(ship, facing)
Rotates the nodes in a ship object. Note that the actual nodes or entities in
the world are not updated.
    ship        any ship object, which nodes are rotated in-place
    facing      new 'facing' value for the ship; 0 to 4 are valid
This function ought to be called before turning a ship into its node form, so
that the new nodes align with the existing entities.
]]

--[[    nv_ships.serialize_ship(ship)
Returns a string representing the given ship object in its current state.
    ship        ship object to serialize
]]

--[[    nv_ships.deserialize_ship(data)
Returns a ship object created from the string passed as data.
    data        a string obtained from nv_ships.serialize_ship()
]]

--[[    nv_ships.load_player_state(player)
Loads a player's state, in order to resume whatever activity the player was
carrying out. This includes loading all their ships from disk.
Actually placing the ship in entity form and flying it if required is a
responsibility of the caller, however.
    player      player which data to load from disk
]]

--[[    nv_ships.store_player_state(player)
Saves a player's state, so it can be resumed with a call to
nv_ships.load_player_state().
    player      player which data to write to disk
]]

--[[    nv_ships.set_default_ship(data)
Set the default starting ship for new players.
    data        serialized representation of the ship
]]

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

-- Register a debug command: /debug
minetest.register_chatcommand("debug", {
    params = "",
    description = "Debug",
    func = function (name, param)
        local player = minetest.get_player_by_name(name)
        nv_ships.store_player_state(player)
        nv_ships.load_player_state(player)
    end
})
