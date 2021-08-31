nv_ships = {}

dofile(minetest.get_modpath("nv_ships") .. "/util.lua")
dofile(minetest.get_modpath("nv_ships") .. "/ship.lua")
dofile(minetest.get_modpath("nv_ships") .. "/control.lua")
dofile(minetest.get_modpath("nv_ships") .. "/nodetypes.lua")

local function pos_to_string(pos, separator)
    separator = separator or ","
    if pos == nil then
        return "nil"
    end
    return string.format("%d%s%d%s%d", pos.x, separator, pos.y, separator, pos.z)
end

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
                    "  %d. made of %s, size %s at (%s); cockpit (%s), data [%d] [%d]",
                    ship.index, ship.state,
                    pos_to_string(ship.size, "x"),
                    pos_to_string(ship.pos),
                    pos_to_string(ship.cockpit_pos),
                    #ship.A, #ship.A2
                ))
            end
        end
    end
})
