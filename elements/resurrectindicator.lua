--[[
# Element: Resurrect Indicator

Handles updating and toggles visibility of incoming resurrect icon.

## Widget

ResurrectIndicator - A Texture used to display if the unit has an incoming resurrect.

## Notes

The default resurrect icon will be used if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local ResurrectIndicator = self:CreateTexture(nil, 'OVERLAY')
    ResurrectIndicator:SetSize(16, 16)
    ResurrectIndicator:SetPoint('TOPRIGHT', self)

    -- Register it with oUF
    self.ResurrectIndicator = ResurrectIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.ResurrectIndicator

	--[[ Callback: ResurrectIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the ResurrectIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local incomingResurrect = UnitHasIncomingResurrection(self.unit)
	if(incomingResurrect) then
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: ResurrectIndicator:PostUpdate(incomingResurrect)
	Called after the element has been updated.

	* self              - the ResurrectIndicator element
	* incomingResurrect - a Boolean indicating if the unit has an incoming resurrection
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(incomingResurrect)
	end
end

local function Path(self, ...)
	--[[ Override: ResurrectIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the ResurrectIndicator element
	* ...  - the event and the argument that accompany it
	--]]
	return (self.ResurrectIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.ResurrectIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('INCOMING_RESURRECT_CHANGED', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\RaidFrame\Raid-Icon-Rez]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.ResurrectIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('INCOMING_RESURRECT_CHANGED', Path)
	end
end

oUF:AddElement('ResurrectIndicator', Path, Enable, Disable)
