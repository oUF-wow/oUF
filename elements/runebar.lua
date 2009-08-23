--[[ Runebar:
	Author: Zariel
	Usage: expects self.Runes to be a frame, setup and positiononed by the layout itself, it also requires self.Runes through 6 to be a statusbar again setup by the user.

	Options

	Required:
	.height: (int)          Height of the bar
	.width: (int)           Width of each bar

	Optional:
	.spacing: (float)       Spacing between each bar
	.anchor: (string)       Initial anchor to the parent rune frame
	.growth: (string)       LEFT or RIGHT or UP or DOWN
	.order: (table)         Set custom order, full table of 1 -> 6 required
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
	local bar = self.Runes[i]
	local r, g, b = unpack(self.colors.runes[GetRuneType(i)])
	bar:SetStatusBarColor(r, g, b)

	if(bar.bg) then
		local mu = bar.bg.multiplier or 1
		bar.bg:SetVertexColor(r * mu, g * mu, b * mu)
	end
end

local Update = function(self, event, rune)
	if event == "PLAYER_ENTERING_WORLD" then
		for i = 1, 6 do
			TypeUpdate(self, event, i)
		end
		return
	end

	-- Bar could be 7, 8 for some reason
	local bar = self.Runes[rune]
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
	local runes = self.Runes
	if not runes or self.unit ~= "player" then return end

	RuneFrame:Hide()

	local spacing = runes.spacing or 1
	local anchor = runes.anchor or "BOTTOMLEFT"

	local growthX, growthY = 0, 0

	if runes.growth == "LEFT" then
		growthX = - 1
	elseif runes.growth == "DOWN" then
		growthY = - 1
	elseif runes.growth == "UP" then
		growthY = 1
	else
		growthX = 1
	end

	local width = runes.width
	local height = runes.height

	local order = runes.order

	for i = 1, 6 do
		local bar = runes[i]
		if(bar) then
			bar:SetWidth(width)
			bar:SetHeight(height)
			bar:SetMinMaxValues(0, 10)

			bar:SetPoint(anchor, runes, anchor, ((order and order[i] or i) - 1) * (width + spacing) * growthX, ((order and order[i] or i) - 1) * (height + spacing) * growthY)
		end
	end

	self:RegisterEvent("RUNE_POWER_UPDATE", Update)
	self:RegisterEvent("RUNE_TYPE_UPDATE", TypeUpdate)

	return true
end

local Disable = function(self)
	self.Runes:Hide()

	RuneFrame:Show()

	self:UnregisterEvent("RUNE_POWER_UPDATE", Update)
	self:UnregisterEvent("RUNE_TYPE_UPDATE", TypeUpdate)
end

oUF:AddElement("Runes", Update, Enable, Disable)
