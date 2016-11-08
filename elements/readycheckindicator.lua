--[[
# Element: Ready Check Indicator

Handles updating and visibility of `self.ReadyCheckIndicator` based upon the units ready check status.

## Widget

ReadyCheckIndicator - A Texture representing ready check status.

## Notes

This element updates by changing the texture.

## Options

.finishedTime    - The number of seconds the icon should stick after a check has completed. Defaults to 10 seconds.
.fadeTime        - The number of seconds the icon should use to fade away after the stick duration has completed.
                   Defaults to 1.5 seconds.
.readyTexture    - Path to alternate texture for the ready check 'ready' status.
.notReadyTexture - Path to alternate texture for the ready check 'notready' status.
.waitingTexture  - Path to alternate texture for the ready check 'waiting' status.

## Examples

    -- Position and size
    local ReadyCheckIndicator = self:CreateTexture(nil, 'OVERLAY')
    ReadyCheckIndicator:SetSize(16, 16)
    ReadyCheckIndicator:SetPoint('TOP')

    -- Register with oUF
    self.ReadyCheckIndicator = ReadyCheckIndicator
--]]

local parent, ns = ...
local oUF = ns.oUF

local function OnFinished(self)
	local element = self:GetParent()
	element:Hide()

	--[[ Callback: ReadyCheckIndicator:PostUpdateFadeOut()
	Called after the element has been faded out.

	* self - the ReadyCheckIndicator element
	--]]
	if(element.PostUpdateFadeOut) then
		element:PostUpdateFadeOut()
	end
end

local function Update(self, event)
	local element = self.ReadyCheckIndicator

	--[[ Callback: ReadyCheckIndicator:PreUpdate()
	Called before the element has been updated.

	* self - the ReadyCheckIndicator element
	--]]
	if(element.PreUpdate) then
		element:PreUpdate()
	end

	local unit = self.unit
	local status = GetReadyCheckStatus(unit)
	if(UnitExists(unit) and status) then
		if(status == 'ready') then
			element:SetTexture(element.readyTexture or READY_CHECK_READY_TEXTURE)
		elseif(status == 'notready') then
			element:SetTexture(element.notReadyTexture or READY_CHECK_NOT_READY_TEXTURE)
		else
			element:SetTexture(element.waitingTexture or READY_CHECK_WAITING_TEXTURE)
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

	--[[ Callback: ReadyCheckIndicator:PostUpdate(status)
	Called after the element has been updated.

	* self   - the ReadyCheckIndicator element
	* status - a String representing the unit's ready check status ('ready', 'notready', 'waiting' or nil)
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(status)
	end
end

local function Path(self, ...)
	--[[ Override: ReadyCheckIndicator:Override(...)
	Used to completely override the internal update function.

	* self - the ReadyCheckIndicator element
	* ...  - the event and the argument that accompany it
	--]]
	return (self.ReadyCheckIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate')
end

local function Enable(self, unit)
	local element = self.ReadyCheckIndicator
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

local function Disable(self)
	local element = self.ReadyCheckIndicator
	if(element) then
		element:Hide()

		self:UnregisterEvent('READY_CHECK', Path)
		self:UnregisterEvent('READY_CHECK_CONFIRM', Path)
		self:UnregisterEvent('READY_CHECK_FINISHED', Path)
	end
end

oUF:AddElement('ReadyCheckIndicator', Path, Enable, Disable)
