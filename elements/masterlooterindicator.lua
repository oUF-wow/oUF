--[[
# Element: Master Looter Indicator

Toggles visibility of the master looter icon.

## Widget

MasterLooterIndicator - Any UI widget.

## Notes

The default master looter icon will be applied if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local MasterLooterIndicator = self:CreateTexture(nil, 'OVERLAY')
    MasterLooterIndicator:SetSize(16, 16)
    MasterLooterIndicator:SetPoint('TOPRIGHT', self)

    -- Register it with oUF
    self.MasterLooterIndicator = MasterLooterIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local unit = self.unit
	local element = self.MasterLooterIndicator
	if(not (UnitInParty(unit) or UnitInRaid(unit))) then
		return element:Hide()
	end

	--[[ Callback: MasterLooterIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the MasterLooterIndicator element
	--]]
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

	--[[ Callback: MasterLooterIndicator:PostUpdate(isShown)
	Called after the element has been updated.

	* self - the MasterLooterIndicator element
	* isShown - a Boolean indicating whether the element is shown
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(element:IsShown())
	end
end

local function Path(self, ...)
	--[[ Override: MasterLooterIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the MasterLooterIndicator element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.MasterLooterIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.MasterLooterIndicator
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
	local element = self.MasterLooterIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('PARTY_LOOT_METHOD_CHANGED', Path)
		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('MasterLooterIndicator', Path, Enable, Disable)
