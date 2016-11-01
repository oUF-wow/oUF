--[[ Element: Resurrect Indicator

 Handles updating and toggles visibility of incoming resurrect icon.

 Widget

 ResurrectIndicator - A Texture used to display if the unit has an incoming
 resurrect.

 Notes

 The default resurrect icon will be used if the UI widget is a texture and
 doesn't have a texture or color defined.

 Examples

   -- Position and size
   local ResurrectIndicator = self:CreateTexture(nil, 'OVERLAY')
   ResurrectIndicator:SetSize(16, 16)
   ResurrectIndicator:SetPoint('TOPRIGHT', self)

   -- Register it with oUF
   self.ResurrectIndicator = ResurrectIndicator

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.ResurrectIndicator
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local incomingResurrect = UnitHasIncomingResurrection(self.unit)
	if(incomingResurrect) then
		element:Show()
	else
		element:Hide()
	end

	if(element.PostUpdate) then
		return element:PostUpdate(incomingResurrect)
	end
end

local function Path(self, ...)
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
