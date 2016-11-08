--[[
# Element: Phasing Indicator

Toggles visibility of the phase icon based on the units phasing compared to the player.

## Widget

PhaseIndicator - Any UI widget.

## Notes

The default phasing icon will be used if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local PhaseIndicator = self:CreateTexture(nil, 'OVERLAY')
    PhaseIndicator:SetSize(16, 16)
    PhaseIndicator:SetPoint('TOPLEFT', self)

    -- Register it with oUF
    self.PhaseIndicator = PhaseIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.PhaseIndicator

	--[[ Callback: PhaseIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the PhaseIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local inPhase = UnitInPhase(self.unit)
	if(inPhase) then
		element:Hide()
	else
		element:Show()
	end

	--[[ Callback: PhaseIndicator:PostUpdate(inPhase)
	Called after the element has been updated.

	* self    - the PhaseIndicator element
	* inPhase - a Boolean indicating whether the element is shown
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(inPhase)
	end
end

local function Path(self, ...)
	--[[ Override: PhaseIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the PhaseIndicator element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.PhaseIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.PhaseIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_PHASE', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\TargetingFrame\UI-PhasingIcon]])
		end

		return true
	end
end

local function Disable(self)
	local element = self.PhaseIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_PHASE', Path)
	end
end

oUF:AddElement('PhaseIndicator', Path, Enable, Disable)
