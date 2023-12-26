nv_encyclopedia = {}

local function joinplayer_callback(player, last_login)
    local formspec = [[
		formspec_version[2]
		size[14,8]
	]]
	nv_gui.set_inventory_formspec(player, "encyclopedia", formspec)
end

minetest.register_on_joinplayer(joinplayer_callback)

local function player_receive_fields_callback(player, fields)
	for field, value in pairs(fields) do
	end
end

nv_gui.register_tab("encyclopedia", "Discoveries", player_receive_fields_callback)
