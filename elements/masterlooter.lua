--[[ Element: Master Looter Icon

 Toggles visibility of the master looter icon.

 Widget

 MasterLooter - Any UI widget.

 Notes

 The default master looter icon will be applied if the UI widget is a texture
 and doesn't have a texture or color defined.

 Examples

   -- Position and size
   local MasterLooter = self:CreateTexture(nil, 'OVERLAY')
   MasterLooter:SetSize(16, 16)
   MasterLooter:SetPoint('TOPRIGHT', self)

   -- Register it with oUF
   self.MasterLooter = MasterLooter

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.

]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local unit = self.unit
	local element = self.MasterLooter
	if(not (UnitInParty(unit) or UnitInRaid(unit))) then
		return element:Hide()
	end

	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local method, partyIndex, raidIndex = GetLootMethod()
	if(method == 'master') then
		local mlUnit
		if(partyIndex) then
			if(partyIndex == 0) then
				mlUnit = 'player'
			else
				mlUnit = 'party' .. partyIndex
			end
		elseif(raidIndex) then
			mlUnit = 'raid' .. raidIndex
		end

		if(UnitIsUnit(unit, mlUnit)) then
			element:Show()
		elseif(element:IsShown()) then
			element:Hide()
		end
	else
		element:Hide()
	end

	if(element.PostUpdate) then
		return element:PostUpdate(element:IsShown())
	end
end

local function Path(self, ...)
	return (self.MasterLooter.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.MasterLooter
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('PARTY_LOOT_METHOD_CHANGED', Path, true)
		self:RegisterEvent('GROUP_ROSTER_UPDATE', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\GroupFrame\UI-Group-MasterLooter]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.MasterLooter
	if(element) then
		element:Hide()

		self:UnregisterEvent('PARTY_LOOT_METHOD_CHANGED', Path)
		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('MasterLooter', Path, Enable, Disable)
