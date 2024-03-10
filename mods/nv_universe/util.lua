--[[
 # DUG LIST
]]

--[[
Contains a dictionary of all dug nodes by 'in_space', then by planet,
then by Y, then by Z, then by X. Each leaf node only contains 'true'.
]]--

nv_universe.dug = {}
minetest.set_mapgen_setting("nv_universe.dug", minetest.serialize(nv_universe.dug))

function nv_universe.mark_dug_node(in_space, planet, x, y, z)
    if nv_universe.dug[in_space] == nil then
        nv_universe.dug[in_space] = {}
    end
    local cur = nv_universe.dug[in_space]
    if cur[planet] == nil then
        cur[planet] = {}
    end
    cur = cur[planet]
    if cur[y] == nil then
        cur[y] = {}
    end
    cur = cur[y]
    if cur[z] == nil then
        cur[z] = {}
    end
    cur = cur[z]
    if cur[x] == nil then
        cur[x] = true
    end
    minetest.set_mapgen_setting("nv_universe.dug", minetest.serialize(nv_universe.dug))
end

function nv_universe.sRGB_to_string(sRGB)
    return string.format("#%02x%02x%02x", sRGB.R or sRGB.r, sRGB.G or sRGB.g, sRGB.B or sRGB.b)
end

local function sRGB_to_XYZ(sRGB)
	local srgb = {
		r = sRGB.R / 255,
		g = sRGB.G / 255,
		b = sRGB.B / 255
	}
 	local XYZ = {
 		X = 0.7161046 * srgb.r + 0.1009296 * srgb.g + 0.1471858 * srgb.b,
 		Y = 0.2581874 * srgb.r + 0.7249378 * srgb.g + 0.0168748 * srgb.b,
 		Z = 0.0000000 * srgb.r + 0.0517813 * srgb.g + 0.7734287 * srgb.b
 	}
 	return XYZ
end

local function XYZ_to_xyY(XYZ)
	local sum = XYZ.X + XYZ.Y + XYZ.Z
	local xyY = {
		x = XYZ.X / sum,
		y = XYZ.Y / sum,
		Y = XYZ.Y
	}
	return xyY
end

local function sRGB_to_xyY(sRGB)
	return XYZ_to_xyY(sRGB_to_XYZ(sRGB))
end

local function T_to_xy(T)
	if T < 1667 then
		local xy = T_to_xy(1667)
		local red = sRGB_to_xyY {
			R = 255, G = 0, B = 0
		}
		xy = {
			x = red.x + T * (xy.x - red.x) / 1667,
			y = red.y + T * (xy.y - red.y) / 1667
		}
		return xy
	elseif T > 25000 then
		return T_to_xy(25000)
	else
		local x
		if T <= 4000 then
			x = -266123900 / T^3 - 234358.9 / T^2 + 877.6956 / T + 0.179910
		else
			x = -3025846900 / T^3 + 2107037.9 / T^2 + 222.6347 / T + 0.240390
		end
		local y
		if T <= 2222 then
			y = -1.1063814 * x^3 - 1.34811020 * x^2 + 2.18555832 * x - 0.20219683
		elseif T <= 4000 then
			y = -0.9549476 * x^3 - 1.37418593 * x^2 + 2.09137015 * x - 0.16748867
		else
			y = 3.0817580 * x^3 - 5.87338670 * x^2 + 3.75112997 * x - 0.37001483
		end
		return {
			x = x, y = y
		}
	end
end

local function xyY_to_XYZ(xyY)
	local XYZ = {
		X = xyY.x * xyY.Y / xyY.y,
		Y = xyY.Y,
		Z = (1 - xyY.x - xyY.y) * xyY.Y / xyY.y
	}
	return XYZ
end

local function clamp(x)
	if x > 1 then
		return 1
	elseif x < 0 then
		return 0
	else
		return x
	end
end

local function XYZ_to_sRGB(XYZ)
 	local srgb = {
 		r = 3.2404542 * XYZ.X - 1.5371385 * XYZ.Y - 0.4985314 * XYZ.Z,
 		g = -0.9692660 * XYZ.X + 1.8760108 * XYZ.Y + 0.0415560 * XYZ.Z,
 		b = 0.0556434 * XYZ.X - 0.2040259 * XYZ.Y + 1.0572252 * XYZ.Z
 	}
 	local sRGB = {
		R = clamp(srgb.r) * 255,
		G = clamp(srgb.g) * 255,
		B = clamp(srgb.b) * 255
	}
	return sRGB
end

local function xyY_to_sRGB(xyY)
	return XYZ_to_sRGB(xyY_to_XYZ(xyY))
end

function nv_universe.YT_to_sRGB(YT)
	local xy = T_to_xy(YT.T)
	return xyY_to_sRGB {
		x = xy.x,
		y = xy.y,
		Y = YT.Y
	}
end

function gen_linear(generator, min, max)
    return generator:next(0, 65535)/65536 * (max-min) + min
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
