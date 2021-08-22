--
-- A single, global function to help with registering auto-boxed meshes
--
autobox = {}

local function param2offset(pos, param2)
    local ret = {}
        local param2Table = {
		[0]={"x",1,"y",1,"z",1}, --0
        {"z",1,"y",1,"x",-1}, --1
        {"x",-1,"y",1,"z",-1}, --2
		{"z",-1,"y",1,"x",1}, --3
		
		{"x",1,"z",-1,"y",1}, --4
		{"z",1,"x",1,"y",1}, --5
		{"x",-1,"z",1,"y",1}, --6
		{"z",-1,"x",-1,"y",1}, --7
		
		{"x",1,"z",1,"y",-1}, --8
		{"z",1,"x",-1,"y",-1}, --9
		{"x",-1,"z",-1,"y",-1}, --10
		{"z",-1,"x",1,"y",-1}, --11
		
		{"y",1,"x",-1,"z",1}, --12
		{"y",1,"z",-1,"x",-1}, --13
		{"y",1,"x",1,"z",-1}, --14
		{"y",1,"z",1,"x",1}, --15
		
		{"y",-1,"x",1,"z",1}, --16
		{"y",-1,"z",1,"x",-1}, --17
		{"y",-1,"x",-1,"z",-1}, --18
		{"y",-1,"z",-1,"x",1}, --19
		
		{"x",-1,"y",-1,"z",1}, --20
		{"z",-1,"y",-1,"x",-1}, --21
		{"x",1,"y",-1,"z",-1}, --22
		{"z",1,"y",-1,"x",1}, --23   
        } --End all 24 directions
        ret.x = pos[param2Table[param2][1]] * param2Table[param2][2] --{x or y or z value} * {+1 or -1}
        ret.y = pos[param2Table[param2][3]] * param2Table[param2][4]
        ret.z = pos[param2Table[param2][5]] * param2Table[param2][6]
		if ret.x == -0 then
			ret.x = 0
		end
		if ret.y == -0 then
			ret.y = 0
		end
		if ret.z == -0 then
			ret.z = 0
		end
    return ret
end


--Simple function that performs a deep copy of a table
local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

--Checks the node provided to see if it can be built in or not
local function buildable(node, pos_list, numPositions, current_pos, old_param2, new_param2)
--and minetest.registered_nodes[old_node.name].draw_type == "liquid" 
--and minetest.registered_nodes[old_node.name].draw_type == "flowingliquid" then
	
	--First check if this position is currently filled by this node:
	if numPositions ~= nil then
		for i=1, numPositions do
			if vector.equals(	param2offset(pos_list[i], old_param2), --Any of the old
								param2offset(pos_list[current_pos], new_param2) --match this one of the new
							) then	
				return true
			end
		end
	end

	--Then check for other nodes
	if node.name == "air" then
		return true
	elseif  node == nil  then
		return true
	elseif  minetest.registered_nodes[node.name].drawtype == "liquid"  then
		return true
	elseif  minetest.registered_nodes[node.name].drawtype == "flowingliquid"  then
		return true
	else 
		return false
	end
end

function delete_and_place(node_pos_list, numNodes, new_param2, name, pos)
	local param1s = {}
	
	local p_node = minetest.get_node(pos)
	local old_param2 = p_node.param2
        
	--Remove old child nodes
	for i=1,numNodes do
		local child_pos = vector.add(pos, param2offset(node_pos_list[i], old_param2))
		param1s[i] = minetest.get_node(child_pos).param1
		minetest.swap_node(child_pos,{name="air"}) --Don't trigger the destructors
		minetest.get_meta(child_pos):from_table(nil) --delete the metadata
	end
		        
	--Place new child nodes
	for i=1,numNodes do
		local adjusted_offset = param2offset(node_pos_list[i], new_param2)
		local child_pos = vector.add(pos, adjusted_offset) --calculate node position
		minetest.swap_node(child_pos,{name=name..i, param1 = param1s[i], param2 = new_param2 }) --set the node
		local meta = minetest.get_meta(child_pos)
		meta:from_table(nil) --delete the metadata
		meta:set_string("parent_pos", minetest.serialize(pos)) --set that node's parent
	end
	
	--Don't forget the parent node itself :)
	
	minetest.swap_node(pos,{name=p_node.name, param1 = p_node.param1, param2 = new_param2})
end

--Place all ".box" files in your mod's "/data" folder
function autobox.register_node(name, data_filename, node_definition, respect_nodes)

-- Load the data
local modname = minetest.get_current_modname()
local path = minetest.get_modpath(modname)
local f = io.open(path .. "/data/" .. data_filename, "rb")
local data = minetest.deserialize(f:read("*all"))
io.close(f)

local placement_node = copy(node_definition)
if data.numNodes > 1 then
    
    
    --Get list of child node positions
    local node_pos_list = {}
    for i=2,data.numNodes do 
        node_pos_list[i-1] = data.nodes[i].position    
    end
	
	----------------------------------------On Place-----------------------------------------------	
	placement_node.on_place = function(itemstack, placer, pointed_thing) --Mostly taken from core.item_place_node
		if pointed_thing.type ~= "node" then
			return itemstack, nil
		end
		local under = pointed_thing.under
		local oldnode_under = minetest.get_node_or_nil(under)
		local above = pointed_thing.above
		local oldnode_above = minetest.get_node_or_nil(above)
		local playername = placer:get_player_name()
		local log = minetest.log
	
		if not oldnode_under or not oldnode_above then
			log("info", playername .. " tried to place"
				.. " node in unloaded position " .. minetest.pos_to_string(above))
			return itemstack, nil
		end
		
		local olddef_under = minetest.registered_nodes[oldnode_under.name]
		olddef_under = olddef_under or minetest.nodedef_default
		local olddef_above = minetest.registered_nodes[oldnode_above.name]
		olddef_above = olddef_above or minetest.nodedef_default

		if not olddef_above.buildable_to and not olddef_under.buildable_to then
			log("info", playername .. " tried to place"
				.. " node in invalid position " .. minetest.pos_to_string(above)
				.. ", replacing " .. oldnode_above.name)
			return itemstack, nil
		end
		
		-- Place above pointed node
		local place_to = {x = above.x, y = above.y, z = above.z}
		
		-- If node under is buildable_to, place into it instead (eg. snow)
		if olddef_under.buildable_to then
			log("info", "node under is buildable to")
			place_to = {x = under.x, y = under.y, z = under.z}
		end
		
		if minetest.is_protected(place_to, playername) then
			log("action", playername
					.. " tried to place " .. placement_node.name
					.. " at protected position "
					.. minetest.pos_to_string(place_to))
			minetest.record_protection_violation(place_to, playername)
			return itemstack, nil
		end
        
        --Get the param2 set before cycling through children nodes
        
        local oldnode = minetest.get_node(place_to)
		local newnode = {name = name, param1 = 0, param2 = param2 or 0}
		
		if placement_node.place_param2 ~= nil then
			newnode.param2 = placement_node.place_param2
		elseif (placement_node.paramtype2 == "facedir" or
				placement_node.paramtype2 == "colorfacedir") and not param2 then
			local placer_pos = placer and placer:get_pos()
			if placer_pos then
				local dir = {
					x = above.x - placer_pos.x,
					y = above.y - placer_pos.y,
					z = above.z - placer_pos.z
				}
				newnode.param2 = minetest.dir_to_facedir(dir)
				log("info", "facedir: " .. newnode.param2)
			end
		end
        
        --Now check protection for all the child nodes
        for i=2,data.numNodes do
            local child_pos = vector.add(place_to, param2offset(data.nodes[i].position, newnode.param2))
            if minetest.is_protected(child_pos, playername) then
                log("action", playername
                        .. " tried to place " .. def.name .. i-1
                        .. " at protected position "
                        .. minetest.pos_to_string(child_pos))
                minetest.record_protection_violation(place_to, playername)
                --Let the player know:
                minetest.chat_send_player(playername, "Unable to place object at ".. minetest.pos_to_string(place_to) .. " due to protection at: " .. minetest.pos_to_string(child_pos))
                return itemstack, nil
            end
        end
		
        --Now check if all spots besides the first is available
        --If not, let the player know where
		if respect_nodes == true then
            for i=2,data.numNodes do
				local child_pos = vector.add(place_to, param2offset(data.nodes[i].position, newnode.param2))
				local node_there = minetest.get_node_or_nil(child_pos)
				if buildable(node_there) == false then
					log("action", playername
							.. " tried to place " .. name
							.. " (an autobox multi-node model) at inhabited position "
							.. minetest.pos_to_string(child_pos))
					minetest.chat_send_player(playername, "Unable to place object at ".. minetest.pos_to_string(place_to) .. " due to " .. node_there.name .. " node at " .. minetest.pos_to_string(child_pos))
					return itemstack, nil
				end
			end
        end

		log("action", playername .. " places node "
				.. name .. " at " .. minetest.pos_to_string(place_to))		
		
		-- Add node and update
		minetest.add_node(place_to, newnode)
        
        --Set up meta for finding the child nodes later
        local meta = minetest.get_meta(place_to)
        meta:set_string("child_nodes", minetest.serialize(node_pos_list))
		meta:set_string("numNodes", tostring(data.numNodes-1))
		
		-- add the rest of the nodes, but without callbacks, since the parent handles all that :)
        for i=2,data.numNodes do
			local child_pos = vector.add(place_to, param2offset(data.nodes[i].position, newnode.param2)) --calculate node position
            minetest.swap_node(child_pos,{name=name..i-1, param2 = newnode.param2 }) --set the node
            local meta = minetest.get_meta(child_pos)
            meta:from_table(nil) --delete previous meta
			meta:set_string("parent_pos", minetest.serialize(place_to)) --set the child node's parent position
        end
			
		-- Play sound if it was done by a player
		if playername ~= "" and placement_node.sounds and placement_node.sounds.place then
			minetest.sound_play(placement_node.sounds.place, {
				pos = place_to,
				exclude_player = playername,
			}, true)
		end
		
		local take_item = true
		
		-- Run callback
		if placement_node.after_place_node and not prevent_after_place then
			-- Deepcopy place_to and pointed_thing because callback can modify it
			local place_to_copy = {x=place_to.x, y=place_to.y, z=place_to.z}
			local pointed_thing_copy = copy_pointed_thing(pointed_thing)
			if placement_node.after_place_node(place_to_copy, placer, itemstack,
					pointed_thing_copy) then
				take_item = false
			end
		end
		
		-- Run script hook
		for _, callback in ipairs(minetest.registered_on_placenodes) do
			-- Deepcopy pos, node and pointed_thing because callback can modify them
			local place_to_copy = {x=place_to.x, y=place_to.y, z=place_to.z}
			local newnode_copy = {name=newnode.name, param1=newnode.param1, param2=newnode.param2}
			local oldnode_copy = {name=oldnode.name, param1=oldnode.param1, param2=oldnode.param2}
			local pointed_thing_copy = copy(pointed_thing)
			if callback(place_to_copy, newnode_copy, placer, oldnode_copy, itemstack, pointed_thing_copy) then
				take_item = false
			end
		end
		
		if take_item then
			itemstack:take_item()
		end
		return itemstack, place_to
	end
    
    ----------------------------------------On Destruct----------------------------------------
    placement_node.on_destruct = function(pos)
        local meta = minetest.get_meta(pos)
        --First remove the nodes
        local node_pos_list = minetest.deserialize(meta:get_string("child_nodes"))
		if node_pos_list ~= nil then
			local parent_param2 = minetest.get_node(pos).param2
			--param 2 is between 0-23, need to properly change directions of the node position offsets based on this value
			
			--First we need to specify the order ( xyz , xzy , yxz , yzx , zxy, zyx )
			--Then specify the direction. Maybe I should just do a lookup table.........
			--Z direction is always facedir_to_dir, that is accurate for Z only.
			local numNodes = tonumber(meta:get_string("numNodes"))
			for i=1,numNodes do
				local adjusted_offset = param2offset(node_pos_list[i], parent_param2)
				minetest.swap_node(vector.add(pos, adjusted_offset),{name="air"}) --Don't trigger the destructors
				minetest.get_meta(vector.add(pos, adjusted_offset)):from_table(nil) --delete the metadata
			end
		end
    end
    
    ----------------------------------------On Rotate-----------------------------------------------
    placement_node.on_rotate = function(pos, node, user, mode, new_param2) --ignore new_param2 and just use the mode and a lookup table
        --Get player name for protection checking and chat
        local playername = user and user:get_player_name() or ""
        if playername == nil then
			return false
		end
		
        --Get meta describing positioning
        local meta = minetest.get_meta(pos)
        local node_pos_list = minetest.deserialize(meta:get_string("child_nodes"))
		local numNodes =  tonumber(meta:get_string("numNodes"))
		
		if user:get_player_control().sneak then --we are doing a sneak-rotate instead, i.e. go to next available
			local original_param2 = minetest.get_node(pos).param2
			local next_param2 = (original_param2 + 1) % 24
			
			while next_param2 ~= original_param2 do
				local protected = false
				local blocked = false
				
				--Check protection for children node destinations
				for i=1,numNodes do
					local child_pos = vector.add(pos, param2offset(node_pos_list[i], next_param2))
					if minetest.is_protected(child_pos, player_name) then
						protected = true
						break
					end
				end
				
				--Check for availability, if respecting nodes
				if respect_nodes == true then
					for i=1,numNodes do
						local child_pos = vector.add(pos, param2offset(node_pos_list[i], next_param2))
						local node_there = minetest.get_node_or_nil(child_pos)
						if buildable(node_there, node_pos_list, numNodes, i, original_param2 , next_param2) == false then
							blocked = true
						end
					end
				end
				
				if protected == false and blocked == false then
					delete_and_place(node_pos_list, numNodes, next_param2, name, pos)
					return true
				end
				next_param2 = (next_param2 + 1) % 24
			end
			
			--We were unsucessful at rotating in any direction, let the player know the bad news:
			minetest.chat_send_player(playername, "Unable to rotate object in any other direction due to protection (or nodes blocking the way), you should make room")
			return false
		end
        
        --Check protection for children node destinations
        for i=1,numNodes do
            local child_pos = vector.add(pos, param2offset(node_pos_list[i], new_param2))
            if minetest.is_protected(child_pos, player_name) then
                --Let the player know:
                minetest.chat_send_player(playername, "Unable to rotate object at ".. minetest.pos_to_string(pos) .. " due to protection at: " .. minetest.pos_to_string(child_pos))
                return false --Fail to rotate
            end
        end
		
        --Now check if all spots, besides the first, are available
        --If not, let the player know where
		if respect_nodes == true then
            for i=1,numNodes do
				local old_param2 = minetest.get_node(pos).param2
                local child_pos = vector.add(pos, param2offset(node_pos_list[i], new_param2))
                local node_there = minetest.get_node_or_nil(child_pos)
                if buildable(node_there, node_pos_list, numNodes, i, old_param2 , new_param2) == false then
                    minetest.chat_send_player(playername, "Unable to rotate object at ".. minetest.pos_to_string(pos) .. 
									" due to " .. node_there.name .. " node at " .. minetest.pos_to_string(child_pos) ..
									"\n You may do a sneak-rotate to go to the next available rotation, or remove that node" 
									)
					
					return false --Fail to rotate
                end
            end
        end
           
        --All spots are available, Delele old nodes, place the new nodes at correct locations. setting 'param2 = new_param2' (to get correct collision boxes)
		
        delete_and_place(node_pos_list, numNodes, new_param2, name, pos)
		return true --rotate success
    end
    
	placement_node.collision_box =  {
										type = "fixed",
										fixed = data.nodes[1].boxTable
									}
	placement_node.selection_box =  {
										type = "fixed",
										fixed = data.nodes[1].boxTable
									}
	
	--Register Placement Node
	minetest.register_node(name, placement_node)
	
	for i=2,data.numNodes do
			local child_def = copy(node_definition)
			child_def.draw_type = "airlike" --Gotta be invisible
			child_def.mesh = "" --Which ironically 
			child_def.collision_box =  	{
											type = "fixed",
											fixed = data.nodes[i].boxTable
										}
			child_def.selection_box =  	{
											type = "fixed",
											fixed = data.nodes[i].boxTable
										}
			child_def.drop = ""
			child_def.groups.not_in_creative_inventory = 1
            
            --Call the parent for everything :)
            
			child_def.on_destruct = function(pos) --This will only occur on a dig
				local parent_pos = minetest.deserialize(minetest.get_meta(pos):get_string("parent_pos"))
                minetest.remove_node(parent_pos)
			end
			
			child_def.on_dig = function(pos, node, digger)
				local parent_pos = minetest.deserialize(minetest.get_meta(pos):get_string("parent_pos"))
				minetest.node_dig(parent_pos, {name=name}, digger)
			end
			
			child_def.on_rotate = function(pos, node, user, mode, new_param2)
				local parent_pos = minetest.deserialize(minetest.get_meta(pos):get_string("parent_pos"))
				return minetest.registered_nodes[name].on_rotate(parent_pos, minetest.get_node(parent_pos), user, mode, new_param2)
			end
            
            child_def.on_punch = function(pos, node, puncher, pointed_thing)
                if minetest.registered_nodes[name].on_punch ~= nil then
					local parent_pos = minetest.deserialize(minetest.get_meta(pos):get_string("parent_pos"))
					return minetest.registered_nodes[name].on_punch(parent_pos, minetest.get_node(parent_pos), puncher, pointed_thing)
				end
			end
            
            child_def.on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
				if minetest.registered_nodes[name].on_rightclick ~= nil  then
					local parent_pos = minetest.deserialize(minetest.get_meta(pos):get_string("parent_pos"))				
					return minetest.registered_nodes[name].on_rightclick(parent_pos, minetest.get_node(parent_pos), clicker, itemstack, pointed_thing)
				end
            end
            
            child_def.on_blast = function(pos, intensity)
                if minetest.registered_nodes[name].on_blast ~= nil then
					local parent_pos = minetest.deserialize(minetest.get_meta(pos):get_string("parent_pos"))
					return minetest.registered_nodes[name].on_blast(parent_pos, intensity)
				end
            end
			
            minetest.register_node(name..i-1, child_def)
	end  
else 
                                    -----------Single node representation----------------
	--Only need to overwrite the collision and selection boxes
	placement_node.collision_box = {
										type = "fixed",
										fixed = data.nodes[1].boxTable
								   }
	placement_node.selection_box = {
										type = "fixed",
										fixed = data.nodes[1].boxTable
								   }
									
	--Just register the node like normal. Nothing that special is required here, just autoboxing a single node							
	minetest.register_node(name, placement_node)
end --end if single node represented object
end --End autobox function

--Example
--dofile(minetest.get_modpath("autobox") .. "/example.lua")
