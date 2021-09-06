local prev_globalstep = nil

function get_dtime()
    local r
    local current_time = minetest.get_us_time()
	if prev_globalstep == nil then
		r = 0
	else
		r = (current_time - prev_globalstep) / 1e+6
	end
	prev_globalstep = current_time
    return r
end
