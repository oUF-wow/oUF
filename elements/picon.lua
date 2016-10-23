--[[ Element: Phasing Icon

 Toggles visibility of the phase icon based on the units phasing compared to the
 player.

 Widget

 PhaseIcon - Any UI widget.

 Notes

 The default phasing icon will be used if the UI widget is a texture and doesn't
 have a texture or color defined.

 Examples

   -- Position and size
   local PhaseIcon = self:CreateTexture(nil, 'OVERLAY')
   PhaseIcon:SetSize(16, 16)
   PhaseIcon:SetPoint('TOPLEFT', self)

   -- Register it with oUF
   self.PhaseIcon = PhaseIcon

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.PhaseIcon
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local inPhase = UnitInPhase(self.unit)
	if(inPhase) then
		element:Hide()
	else
		element:Show()
	end

	if(element.PostUpdate) then
		return element:PostUpdate(inPhase)
	end
end

local function Path(self, ...)
	return (self.PhaseIcon.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.PhaseIcon
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
	local element = self.PhaseIcon
	if(element) then
		element:Hide()

		self:UnregisterEvent('UNIT_PHASE', Path)
	end
end

oUF:AddElement('PhaseIcon', Path, Enable, Disable)
