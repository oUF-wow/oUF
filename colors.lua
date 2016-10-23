local parent, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local frame_metatable = Private.frame_metatable

local colors = {
	smooth = {
		1, 0, 0,
		1, 1, 0,
		0, 1, 0
	},
	disconnected = {.6, .6, .6},
	tapped = {.6,.6,.6},
	class = {},
	reaction = {},
}

-- We do this because people edit the vars directly, and changing the default
-- globals makes SPICE FLOW!
local function customClassColors()
	if(CUSTOM_CLASS_COLORS) then
		local function updateColors()
			for classToken, color in next, CUSTOM_CLASS_COLORS do
				colors.class[classToken] = {color.r, color.g, color.b}
			end

			for _, obj in next, oUF.objects do
				obj:UpdateAllElements('CUSTOM_CLASS_COLORS')
			end
		end

		updateColors()
		CUSTOM_CLASS_COLORS:RegisterCallback(updateColors)

		return true
	end
end

if(not customClassColors()) then
	for classToken, color in next, RAID_CLASS_COLORS do
		colors.class[classToken] = {color.r, color.g, color.b}
	end

	local eventHandler = CreateFrame('Frame')
	eventHandler:RegisterEvent('ADDON_LOADED')
	eventHandler:SetScript('OnEvent', function(self)
		if(customClassColors()) then
			self:UnregisterEvent('ADDON_LOADED')
			self:SetScript('OnEvent', nil)
		end
	end)
end

for eclass, color in next, FACTION_BAR_COLORS do
	colors.reaction[eclass] = {color.r, color.g, color.b}
end

local function colorsAndPercent(a, b, ...)
	if(a <= 0 or b == 0) then
		return nil, ...
	elseif(a >= b) then
		return nil, select(select('#', ...) - 2, ...)
	end

	local num = select('#', ...) / 3
	local segment, relperc = math.modf((a / b) * (num - 1))
	return relperc, select((segment * 3) + 1, ...)
end

-- http://www.wowwiki.com/ColorGradient
local function RGBColorGradient(...)
	local relperc, r1, g1, b1, r2, g2, b2 = colorsAndPercent(...)
	if(relperc) then
		return r1 + (r2 - r1) * relperc, g1 + (g2 - g1) * relperc, b1 + (b2 - b1) * relperc
	else
		return r1, g1, b1
	end
end

-- HCY functions are based on http://www.chilliant.com/rgb2hsv.html
local function getY(r, g, b)
	return 0.299 * r + 0.587 * g + 0.114 * b
end

function oUF:RGBToHCY(r, g, b)
	local min, max = min(r, g, b), max(r, g, b)
	local chroma = max - min
	local hue
	if(chroma > 0) then
		if(r == max) then
			hue = ((g - b) / chroma) % 6
		elseif(g == max) then
			hue = (b - r) / chroma + 2
		elseif(b == max) then
			hue = (r - g) / chroma + 4
		end
		hue = hue / 6
	end
	return hue, chroma, getY(r, g, b)
end

local math_abs = math.abs
function oUF:HCYtoRGB(hue, chroma, luma)
	local r, g, b = 0, 0, 0
	if(hue and luma > 0) then
		local h2 = hue * 6
		local x = chroma * (1 - math_abs(h2 % 2 - 1))
		if(h2 < 1) then
			r, g, b = chroma, x, 0
		elseif(h2 < 2) then
			r, g, b = x, chroma, 0
		elseif(h2 < 3) then
			r, g, b = 0, chroma, x
		elseif(h2 < 4) then
			r, g, b = 0, x, chroma
		elseif(h2 < 5) then
			r, g, b = x, 0, chroma
		else
			r, g, b = chroma, 0, x
		end

		local y = getY(r, g, b)
		if(luma < y) then
			chroma = chroma * (luma / y)
		elseif(y < 1) then
			chroma = chroma * (1 - luma) / (1 - y)
		end

		r = (r - y) * chroma + luma
		g = (g - y) * chroma + luma
		b = (b - y) * chroma + luma
	end
	return r, g, b
end

local function HCYColorGradient(...)
	local relperc, r1, g1, b1, r2, g2, b2 = colorsAndPercent(...)
	if(not relperc) then
		return r1, g1, b1
	end

	local h1, c1, y1 = self:RGBToHCY(r1, g1, b1)
	local h2, c2, y2 = self:RGBToHCY(r2, g2, b2)
	local c = c1 + (c2 - c1) * relperc
	local y = y1 + (y2 - y1) * relperc

	if(h1 and h2) then
		local dh = h2 - h1
		if(dh < -0.5) then
			dh = dh + 1
		elseif(dh > 0.5) then
			dh = dh - 1
		end

		return self:HCYtoRGB((h1 + dh * relperc) % 1, c, y)
	else
		return self:HCYtoRGB(h1 or h2, c, y)
	end

end

local function ColorGradient(...)
	return (oUF.useHCYColorGradient and HCYColorGradient or RGBColorGradient)(...)
end

Private.colors = colors

oUF.colors = colors
oUF.ColorGradient = ColorGradient
oUF.RGBColorGradient = RGBColorGradient
oUF.HCYColorGradient = HCYColorGradient
oUF.useHCYColorGradient = false

frame_metatable.__index.colors = colors
frame_metatable.__index.ColorGradient = ColorGradient
