--[[ Runebar:
	Author: Zariel
	Usage: expects self.runes to be a frame, setup and positiononed by the layout itself, it also requires self.runes[1] through 6 to be a statusbar again setup by the user.

	Options: (All optional)
	.spacing: (float)       Spacing between each bar
	.anchor: (string)       Initial anchor to the parent rune frame
	.growth: (string)       LEFT or RIGHT
	.height: (int)          Height of the bar
	.width: (int)           Width of each bar
]]

if select(2, UnitClass("player")) ~= "DEATHKNIGHT" then return end

local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local GetTime = GetTime
local GetRuneCooldown = GetRuneCooldown

oUF.colors.runes = {
	{ 1, 0, 0  },
	{ 0, 0.5, 0 },
	{ 0, 1, 1 },
	{ 0.8, 0.1, 1 },
}

local OnUpdate = function(self, elapsed)
	local time = GetTime()
	if self.finish >= time then
		self:SetValue(10 - (self.finish - time))
	else
		self:SetScript("OnUpdate", nil)
	end
end

local TypeUpdate = function(self, event, i)
	local bar = self.runes[i]
	if not bar then return end -- Just in case

	local r, g, b = unpack(self.colors.runes[GetRuneType(i)])
	bar:SetStatusBarColor(r, g, b)

	if(bar.bg) then
		local mu = bar.bg.multiplier or 1
		bar.bg:SetVertexColor(r * mu, g * mu, b * mu)
	end
end

local Update = function(self, event, rune)
	if event == "PLAYER_ENTERING_WORLD" or not coloured then
		for i = 1, 6 do
			TypeUpdate(self, event, i)
		end
		return
	end

	-- Bar could be 7, 8 for some reason
	local bar = self.runes[rune]
	if not bar then return end

	local start, dur, ready = GetRuneCooldown(rune)

	if not ready then
		bar.finish = start + dur
		bar:SetScript("OnUpdate", OnUpdate)
	else
		bar:SetScript("OnUpdate", nil)
	end
end

local Enable = function(self)
	local runes = self.runes
	if not runes or self.unit ~= "player" then return end

	RuneFrame:Hide()

	local spacing = runes.spacing or 1
	local anchor = runes.anchor or "BOTTOMLEFT"
	local growth = runes.growth == "LEFT" and - 1 or 1
	local width = runes.width or (runes:GetWidth() / 6) - spacing
	local height = runes.height or runes:GetHeight()

	for i = 1, 6 do
		local bar = runes[i]
		if(bar) then
			bar:SetWidth(width)
			bar:SetHeight(height)
			bar:SetMinMaxValues(0, 10)

			-- Horizontal? Who wants vertical ones you freaks
			bar:SetPoint(anchor, runes, anchor, (i - 1) * (width + spacing) * growth, 0)
		end
	end

	self:RegisterEvent("RUNE_POWER_UPDATE", Update)
	self:RegisterEvent("RUNE_TYPE_UPDATE", TypeUpdate)

	return true
end

local Disable = function(self)
	self.runes:Hide()
	RuneFrame:Show()

	self:UnregisterEvent("RUNE_POWER_UPDATE", Update)
	self:UnregisterEvent("RUNE_TYPE_UPDATE", TypeUpdate)
end

oUF:AddElement("Runes", Update, Enable, Disable)
