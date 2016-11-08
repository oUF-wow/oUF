--[[
# Element: Threat Indicator

Handles updating and toggles visibility of current threat level icon.

## Widget

ThreatIndicator - A Texture used to display the current threat level.

## Notes

The default threat icon will be used if the UI widget is a texture and doesn't have a texture or color defined.

## Examples

    -- Position and size
    local ThreatIndicator = self:CreateTexture(nil, 'OVERLAY')
    ThreatIndicator:SetSize(16, 16)
    ThreatIndicator:SetPoint('TOPRIGHT', self)

    -- Register it with oUF
    self.ThreatIndicator = ThreatIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event, unit)
	if(unit ~= self.unit) then return end

	local element = self.ThreatIndicator
	--[[ Callback: ThreatIndicator:PreUpdate(unit)
	Called before the element has been updated.

	* self - the ThreatIndicator element
	* unit - the event unit that the update has been triggered for
	--]]
	if(element.PreUpdate) then element:PreUpdate(unit) end

	unit = unit or self.unit
	local status = UnitThreatSituation(unit)

	local r, g, b
	if(status and status > 0) then
		r, g, b = GetThreatStatusColor(status)
		element:SetVertexColor(r, g, b)
		element:Show()
	else
		element:Hide()
	end

	--[[ Callback: ThreatIndicator:PostUpdate(unit, status, r, g, b)
	Called after the element has been updated.

	* self   - the ThreatIndicator element
	* unit   - the event unit that the update has been triggered for
	* status - a Number representing the unit's threat status
	           (see [UnitThreatSituation](http://wowprogramming.com/docs/api/UnitThreatSituation))
	* r      - the red color component of the StatusBar color based on the unit's threat status
	* g      - the green color component of the StatusBar color based on the unit's threat status
	* b      - the green color component of the StatusBar color based on the unit's threat status
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, status, r, g, b)
	end
end

local function Path(self, ...)
	--[[ Override: ThreatIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the ThreatIndicator element
	* ...  - the event and the arguments that accompany it
	--]]
	return (self.ThreatIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.ThreatIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_THREAT_SITUATION_UPDATE', Path)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\Minimap\ObjectIcons]])
			element:SetTexCoord(6/8, 7/8, 1/8, 2/8)
		end

		return true
	end
end

local function Disable(self)
	local element = self.ThreatIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_THREAT_SITUATION_UPDATE', Path)
	end
end

oUF:AddElement('ThreatIndicator', Path, Enable, Disable)
