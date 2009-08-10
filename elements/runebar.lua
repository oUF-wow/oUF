if select(2, UnitClass("player")) ~= "DEATHKNIGHT" then return end

local parent = debugstack():match[[\AddOns\(.-)\]]
local global = GetAddOnMetadata(parent, 'X-oUF')
assert(global, 'X-oUF needs to be defined in the parent add-on.')
local oUF = _G[global]

local GetTime = GetTime
local GetRuneCooldown = GetRuneCooldown

local colors = {
	[1] = { 1, 0, 0  },
	[2] = { 0, 0.5, 0 },
	[3] = { 0, 1, 1 },
	[4] = { 0.8, 0.1, 1 },
}

local rune
local start, dur
local time

local OnUpdate = function(self, elapsed)
	for i = 1, 6 do
		rune = self.runes[i]
		start, dur = GetRuneCooldown(i)

		time = GetTime() - start

		if time <= dur then
			rune:SetValue(time)
		end
	end
end

local Update = function(self, event, ...)
	local rune, update
	local start, dur, ready

	local runes = self.runes

	local colors = runes.color or colors

	for i = 1, 6 do
		rune = runes[i]
		start, dur, ready = GetRuneCooldown(i)

		if not ready then
			update = true
		end
	end

	if update then
		self:SetScript("OnUpdate", OnUpdate)
	else
		self:SetScript("OnUpdate", nil)
	end
end

local TypeUpdate = function(self, event)
	local runes = self.runes

	for i = 1, 6 do
		self.runes[i]:SetStatusBarColor(unpack(colors[GetRuneType(i)]))
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
	local height = runes.height or runes:GetHeight() or 10
	local texture = runes.texture or self.Health:GetStatusBarTexture():GetTexture()
	local colors = runes.color or colors

	for i = 1, 6 do
		local color = colors[GetRuneType(i) or math.ceil(i / 2)]

		local bar = CreateFrame("Statusbar", nil, runes)

		bar:SetWidth(width)
		bar:SetHeight(height)
		bar:SetStatusBarTexture(texture)
		bar:SetMinMaxValues(0, 10)

		-- Horizontal? Who wants vertical ones you freaks
		bar:SetPoint(anchor, runes, anchor, (i - 1) * (width + spacing) * growth, 0)

		local bg = bar:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints(bar)
		bg:SetTexture(texture)

		local r, g, b = unpack(color)
		bar:SetStatusBarColor(r, g, b)
		bg:SetVertexColor(r, g, b, 0.3)

		bar.bg = bg

		runes[i] = bar
	end

	Update(self)

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
