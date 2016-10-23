--[[ Element: Assistant Icon
 Toggles visibility of `self.Assistant` based on the units raid officer status.

 Widget

 Assistant - Any UI widget.

 Notes

 The default assistant icon will be applied if the UI widget is a texture and
 doesn't have a texture or color defined.

 Examples

   -- Position and size
   local Assistant = self:CreateTexture(nil, 'OVERLAY')
   Assistant:SetSize(16, 16)
   Assistant:SetPoint('TOP', self)

   -- Register it with oUF
   self.Assistant = Assistant

 Hooks and Callbacks

]]

local parent, ns = ...
local oUF = ns.oUF

local function Update(self, event)
	local element = self.Assistant

	--[[ :PreUpdate()

	 Called before the element has been updated.

	 Arguments

	 self - The Assistant element.
	]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local unit = self.unit
	local isAssistant = UnitInRaid(unit) and UnitIsGroupAssistant(unit) and not UnitIsGroupLeader(unit)
	if(isAssistant) then
		element:Show()
	else
		element:Hide()
	end

	--[[ :PostUpdate(isAssistant)

	 Called after the element has been updated.

	 Arguments

	 self        - The Assistant element.
	 isAssistant - A boolean holding whether the unit is a raid officer or not.
	]]
	if(element.PostUpdate) then
		return element:PostUpdate(isAssistant)
	end
end

local function Path(self, ...)
	--[[ :Override(self, event, ...)

	 Used to completely override the internal update function. Removing the
	 table key entry will make the element fall-back to its internal function
	 again.

	 Arguments

	 self  - The Assistant element.
	 event - The UI event that fired.
	 ...   - A vararg with the arguments that accompany the event.
	]]
	return (self.Assistant.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self)
	local element = self.Assistant
	if(element) then
		self:RegisterEvent('GROUP_ROSTER_UPDATE', Path, true)

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\GroupFrame\UI-Group-AssistantIcon]])
		end

		element.__owner = self
		element.ForceUpdate = ForceUpdate

		return true
	end
end

local function Disable(self)
	local element = self.Assistant
	if(element) then
		element:Hide()

		self:UnregisterEvent('GROUP_ROSTER_UPDATE', Path)
	end
end

oUF:AddElement('Assistant', Path, Enable, Disable)
