--[[ Element: Ready Check Icon

 Handles updating and visibility of `self.ReadyCheck` based upon the units
 ready check status.

 Widget

 ReadyCheck - A Texture representing ready check status.

 Notes

 This element updates by changing the texture.

 Options

 .finishedTime - The number of seconds the icon should stick after a check has
                 completed. Defaults to 10 seconds.
 .fadeTime     - The number of seconds the icon should used to fade away after
                 the stick duration has completed. Defaults to 1.5 seconds.

 Examples

   -- Position and size
   local ReadyCheck = self:CreateTexture(nil, 'OVERLAY')
   ReadyCheck:SetSize(16, 16)
   ReadyCheck:SetPoint('TOP')
   
   -- Register with oUF
   self.ReadyCheck = ReadyCheck

 Hooks

 Override(self) - Used to completely override the internal update function.
                  Removing the table key entry will make the element fall-back
                  to its internal function again.
]]

local parent, ns = ...
local oUF = ns.oUF

local function OnFinished(self)
	self:GetParent():Hide()
end

local Update = function(self, event)
	local element = self.ReadyCheck

	local unit = self.unit
	local status = GetReadyCheckStatus(unit)
	if(UnitExists(unit) and status) then
		if(status == 'ready') then
			element:SetTexture(READY_CHECK_READY_TEXTURE)
		elseif(status == 'notready') then
			element:SetTexture(READY_CHECK_NOT_READY_TEXTURE)
		else
			element:SetTexture(READY_CHECK_WAITING_TEXTURE)
		end

		element.status = status
		element:Show()
	elseif(event ~= 'READY_CHECK_FINISHED') then
		element.status = nil
		element:Hide()
	end

	if(event == 'READY_CHECK_FINISHED') then
		if(element.status == 'waiting') then
			element:SetTexture(element.notReadyTexture or READY_CHECK_NOT_READY_TEXTURE)
		end

		element.Animation:Play()
	end
end

local Path = function(self, ...)
	return (self.ReadyCheck.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, 'ForceUpdate')
end

local Enable = function(self, unit)
	local element = self.ReadyCheck
	if(element and (unit and (unit:sub(1, 5) == 'party' or unit:sub(1,4) == 'raid'))) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		local AnimationGroup = element:CreateAnimationGroup()
		AnimationGroup:HookScript('OnFinished', OnFinished)
		element.Animation = AnimationGroup

		local Animation = AnimationGroup:CreateAnimation('Alpha')
		Animation:SetFromAlpha(1)
		Animation:SetToAlpha(0)
		Animation:SetDuration(element.fadeTime or 1.5)
		Animation:SetStartDelay(element.finishedTime or 10)

		self:RegisterEvent('READY_CHECK', Path, true)
		self:RegisterEvent('READY_CHECK_CONFIRM', Path, true)
		self:RegisterEvent('READY_CHECK_FINISHED', Path, true)

		return true
	end
end

local Disable = function(self)
	local element = self.ReadyCheck
	if(element) then
		element:Hide()

		self:UnregisterEvent('READY_CHECK', Path)
		self:UnregisterEvent('READY_CHECK_CONFIRM', Path)
		self:UnregisterEvent('READY_CHECK_FINISHED', Path)
	end
end

oUF:AddElement('ReadyCheck', Path, Enable, Disable)
