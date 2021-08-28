--
-- Copied code of init.lua from the Hand mod
--
-- Adds the default MTG hand tool to the game
--

-- Copyright (C) 2010-2012 celeron55, Perttu Ahola <celeron55@gmail.com>
-- This file was released under GNU LGPL-2.1
-- As part of this mod, it is re-released under GNU GPL-3.0

minetest.override_item("", {
	wield_scale = {x=1,y=1,z=2.5},
	tool_capabilities = {
		full_punch_interval = 0.9,
		max_drop_level = 0,
		groupcaps = {
			crumbly = {times={[2]=3.00, [3]=0.70}, uses=0, maxlevel=1},
			snappy = {times={[3]=0.40}, uses=0, maxlevel=1},
			oddly_breakable_by_hand = {times={[1]=3.50,[2]=2.00,[3]=0.70}, uses=0}
		},
		damage_groups = {fleshy=1},
	}
})
