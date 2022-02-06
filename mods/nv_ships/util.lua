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

function base64_encode(value)
    if value < 26 then
        return string.char(65 + value)
    elseif value < 52 then
        return string.char(97 + value - 26)
    elseif value < 62 then
        return string.char(48 + value - 52)
    elseif value == 63 then
        return "/"
    end
    return "+"
end

function base64_decode(ch)
    local raw = string.byte(ch)
    if raw >= 97 then
        return raw - 97 + 26
    elseif raw >= 65 then
        return raw - 65
    elseif raw >= 48 then
        return raw - 48 + 52
    elseif raw == 47 then
        return 63
    end
    return 62
end
