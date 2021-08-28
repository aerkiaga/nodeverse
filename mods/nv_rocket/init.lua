--[[
Rocket adds an item -the rocket- that can be placed by the player and used to
fly using simple physics. When the player dies, the distance they flew is
presented. Personal and server-wide records are announced.

Included files:
    hand.lua            Just a copy of the Hand mod code by celeron55
    player.lua          Physics, chat messages, controls...
    hud.lua             Head-up display (fuel bar, thrust and crash danger icons)
    nodes.lua           Placed rocket node
]]--

local rPath = minetest.get_modpath("nv_rocket")

-- Namespace for all the API functions
nv_rocket = {}

dofile(rPath .. "/hand.lua")
dofile(rPath .. "/player.lua")
dofile(rPath .. "/hud.lua")
dofile(rPath .. "/nodes.lua")
