--[[
Rocket adds an item -the rocket- that can be placed by the player and used to
fly using simple physics. When the player dies, the distance they flew is
presented. Personal and server-wide records are announced.

Included files:
    player.lua          Physics, chat messages, controls...
    hud.lua             Head-up display (fuel bar, thrust and crash danger icons)
    nodes.lua           Placed rocket node
]]--

local rPath = minetest.get_modpath("rocket")

-- Namespace for all the API functions
rocket = {}

dofile(rPath .. "/player.lua")
dofile(rPath .. "/hud.lua")
dofile(rPath .. "/nodes.lua")
