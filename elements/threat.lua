--[[ Element: Threat Icon

 Handles updating and toggles visibility of current threat level icon.

 Widget

 Threat - A Texture used to display the current threat level.

 Notes

 This element updates by changing colors of the texture.

 The default threat icon will be used if the UI widget is a texture and doesn't
 have a texture or color defined.

 Examples

   -- Position and size
   local Threat = self:CreateTexture(nil, 'OVERLAY')
   Threat:SetSize(16, 16)
   Threat:SetPoint('TOPRIGHT', self)

   -- Register it with oUF
   self.Threat = Threat

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event, unit)
	if(unit ~= self.unit) then return end

	local element = self.Threat
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

	if(element.PostUpdate) then
		return element:PostUpdate(unit, status, r, g, b)
	end
end

local function Path(self, ...)
	return (self.Threat.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.Threat
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
	local element = self.Threat
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_THREAT_SITUATION_UPDATE', Path)
	end
end

oUF:AddElement('Threat', Path, Enable, Disable)
