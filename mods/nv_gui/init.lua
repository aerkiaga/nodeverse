nv_gui = {}

--[[
Contains a dictionary of all players by name, with their current GUI state.
Format is:
    current     index of current tab
    formspecs   list of formspecs for all tabs
]]--
local player_tabs = {}

--[[
A list of all registered tabs.
Format is:
    name        tab name
    text        name actually shown on the GUI
    callback    field reception callback
]]--
local global_tabs = {}

local name_to_tab = {}

function nv_gui.register_tab(name, text, callback)
    table.insert(global_tabs, {
        name = name,
        text = text,
        callback = callback,
    })
    name_to_tab[name] = #global_tabs
end

function nv_gui.set_inventory_formspec(player, tabname, formspec)
    local name = player:get_player_name()
    local tab = name_to_tab[tabname]
    player_tabs[name] = player_tabs[name] or {
        current = 1,
        formspecs = {},
    }
    player_tabs[name].formspecs[tab] = formspec
    if player_tabs[name].current == tab then
        player:set_inventory_formspec(formspec)
    end
end

function nv_gui.show_formspec(player, formspec)
    minetest.show_formspec(player:get_player_name(), "", formspec)
end

local function player_receive_fields_callback(player, formname, fields)
	if formname == "" then
	    local name = player:get_player_name()
	    local tab = player_tabs[name].current
	    global_tabs[tab].callback(player, fields)
	end
end

minetest.register_on_player_receive_fields(player_receive_fields_callback)
