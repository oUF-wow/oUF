--[[ Element: Runes Bar

 Handle updating and visibility of the Death Knight's Rune indicators.

 Widget

 Runes - An array holding six StatusBar's.

 Sub-Widgets

 .bg - A Texture which functions as a background. It will inherit the color of
       the main StatusBar.

 Notes

 The default StatusBar texture will be applied if the UI widget doesn't have a
             status bar texture or color defined.

 Sub-Widgets Options

 .multiplier - Defines a multiplier, which is used to tint the background based
               on the main widgets R, G and B values. Defaults to 1 if not
               present.

 Examples

   local Runes = {}
   for index = 1, 6 do
      -- Position and size of the rune bar indicators
      local Rune = CreateFrame('StatusBar', nil, self)
      Rune:SetSize(120 / 6, 20)
      Rune:SetPoint('TOPLEFT', self, 'BOTTOMLEFT', index * 120 / 6, 0)
   
      Runes[index] = Rune
   end
   
   -- Register with oUF
   self.Runes = Runes
]]

if select(2, UnitClass("player")) ~= "DEATHKNIGHT" then return end

local parent, ns = ...
local oUF = ns.oUF

oUF.colors.runes = {
	{1, 0, 0},   -- blood
	{0, .5, 0},  -- unholy
	{0, 1, 1},   -- frost
	{.9, .1, 1}, -- death
}

local runemap = { 1, 2, 5, 6, 3, 4 }

local OnUpdate = function(self, elapsed)
	local duration = self.duration + elapsed
	if(duration >= self.max) then
		return self:SetScript("OnUpdate", nil)
	else
		self.duration = duration
		return self:SetValue(duration)
	end
end


local UpdateType = function(self, event, rid, alt)

	local otherID = rid + 1
	if rid % 2 == 0 then
		otherID = rid - 1 
	end

	local currentStart, currentDuration, currentReady = GetRuneCooldown(rid)
	local otherStart, otherDuration, otherReady = GetRuneCooldown(otherID)

	local time = GetTime()

	local rune = self.Runes[runemap[rid]]
	local other = self.Runes[runemap[otherID]]

	if rid > otherID then
		rune, other = other, rune
	end

	if (time - currentStart) < (time - otherStart) then
		rune, other = other, rune
	end

	rune:SetStatusBarColor(unpack(self.colors.runes[GetRuneType(rid)]))
	other:SetStatusBarColor(unpack(self.colors.runes[GetRuneType(otherID)]))

end

local UpdateRune = function(self, event, rid)

	local otherID = rid + 1
	if rid % 2 == 0 then
		otherID = rid - 1 
	end

	local currentStart, currentDuration, currentReady = GetRuneCooldown(rid)
	local otherStart, otherDuration, otherReady = GetRuneCooldown(otherID)

	local time = GetTime()

	local rune = self.Runes[runemap[rid]]
	local other = self.Runes[runemap[otherID]]

	if rune and other then
		
		if rid > otherID then
			rune, other = other, rune
		end

		if (time - currentStart) < (time - otherStart) then
			rune, other = other, rune
		end

		if currentReady then
			rune:SetMinMaxValues(0, 1)
			rune:SetValue(1)
			rune:SetScript("OnUpdate", nil)
		else
			rune.duration = GetTime() - currentStart
			rune.max = currentDuration
			rune:SetMinMaxValues(1, currentDuration)
			rune:SetScript("OnUpdate", OnUpdate)

			if rune.duration < 0 then
				rune:SetValue(0)
			end
		end

		if otherReady then
			other:SetMinMaxValues(0, 1)  
			other:SetValue(1)
			other:SetScript("OnUpdate", nil)
		else
			other.duration = GetTime() - otherStart
			other.max = otherDuration
			other:SetMinMaxValues(1, otherDuration)
			other:SetScript("OnUpdate", OnUpdate)

			if other.duration < 0 then
				other:SetValue(0)
			end
		end
		
		UpdateType(self, event, rid)

	end

end

local Update = function(self, event)
	for i=1, 6 do
		UpdateRune(self, event, i)
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, 'ForceUpdate')
end

local Enable = function(self, unit)
	local runes = self.Runes
	if(runes and unit == 'player') then
		runes.__owner = self
		runes.ForceUpdate = ForceUpdate

		for i=1, 6 do
			local rune = runes[i]
			-- From my minor testing this is a okey solution. A full login always remove
			-- the death runes, or at least the clients knowledge about them.
			UpdateType(self, nil, i, math.floor((runemap[i]+1)/2))

			if(rune:IsObjectType'StatusBar' and not rune:GetStatusBarTexture()) then
				rune:SetStatusBarTexture[[Interface\TargetingFrame\UI-StatusBar]]
			end
		end

		self:RegisterEvent("RUNE_POWER_UPDATE", UpdateRune, true)
		self:RegisterEvent("RUNE_TYPE_UPDATE", UpdateType, true)

		-- oUF leaves the vehicle events registered on the player frame, so
		-- buffs and such are correctly updated when entering/exiting vehicles.
		--
		-- This however makes the code also show/hide the RuneFrame.
		RuneFrame.Show = RuneFrame.Hide
		RuneFrame:Hide()

		return true
	end
end

local Disable = function(self)
	RuneFrame.Show = nil
	RuneFrame:Show()

	self:UnregisterEvent("RUNE_POWER_UPDATE", UpdateRune)
	self:UnregisterEvent("RUNE_TYPE_UPDATE", UpdateType)
end

oUF:AddElement("Runes", Update, Enable, Disable)
