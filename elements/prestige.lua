--[[ Element: Prestige Icon

 Handles updating and visibility of prestige icon based on unit's prestige level.

 Widget

 Prestige - A table containing `Portrait` and `Badge`.

 Sub-Widgets

 Portrait - A Texture used to display prestige background image;
 Badge    - A Texture used to display prestige icon.

 Notes

 This element updates by changing textures.

 Examples

   -- Position and size
   local Portrait = self:CreateTexture(nil, "ARTWORK")
   Portrait:SetSize(50, 52)
   Portrait:SetPoint("RIGHT", self, "LEFT")

   local Badge = self:CreateTexture(nil, "ARTWORK", nil, 1)
   Badge:SetSize(30, 30)
   Badge:SetPoint("CENTER", Portrait, "CENTER")

   -- Register with oUF
   self.Prestige = {
      Portrait = Portrait,
      Badge = Badge
   }

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

if(select(4, GetBuildInfo()) < 70000) then return end

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event, unit)
	if(unit ~= self.unit) then return end

	local prestige = self.Prestige

	if(prestige.PreUpdate) then
		prestige:PreUpdate()
	end

	local factionGroup = UnitFactionGroup(unit)
	local level = UnitPrestige(unit)

	if(level > 0) then
		if(UnitIsPVPFreeForAll(unit)) then
			if(prestige.Portrait) then
				prestige.Portrait:SetAtlas('honorsystem-portrait-neutral', false)
				prestige.Portrait:Show()
			end

			if(prestige.Badge) then
				prestige.Badge:SetTexture(GetPrestigeInfo(level))
				prestige.Badge:Show()
			end
		elseif(factionGroup and factionGroup ~= 'Neutral' and UnitIsPVP(unit)) then

			if(prestige.Portrait) then
				prestige.Portrait:SetAtlas('honorsystem-portrait-'..factionGroup, false)
				prestige.Portrait:Show()
			end

			if(prestige.Badge) then
				prestige.Badge:SetTexture(GetPrestigeInfo(level))
				prestige.Badge:Show()
			end
		else
			if(prestige.Portrait) then
				prestige.Portrait:Hide()
			end

			if(prestige.Badge) then
				prestige.Badge:Hide()
			end
		end
	else
		if(prestige.Portrait) then
			prestige.Portrait:Hide()
		end

		if(prestige.Badge) then
			prestige.Badge:Hide()
		end
	end

	if(prestige.PostUpdate) then
		return prestige:PostUpdate(level)
	end
end

local function Path(self, ...)
	return (self.Prestige.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local prestige = self.Prestige

	if(prestige) then
		prestige.__owner = self
		prestige.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_FACTION', Path)
		self:RegisterEvent('HONOR_PRESTIGE_UPDATE', Path)

		return true
	end
end

local function Disable(self)
	local prestige = self.Prestige

	if(prestige) then
		prestige:Hide()
		self:UnregisterEvent('UNIT_FACTION', Path)
		self:UnregisterEvent('HONOR_PRESTIGE_UPDATE', Path)
	end
end

oUF:AddElement('Prestige', Path, Enable, Disable)
