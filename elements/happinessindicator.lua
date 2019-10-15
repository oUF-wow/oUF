--[[
# Element: HappinessIndicator

Handles the visibility and updating of player'a pet happiness.

## Widget

HappinessIndicator - A `Texture` used to display the current happiness level.

The element works by changing the texture's coordinates.

## Notes

A default texture will be applied if the widget is a Texture and doesn't have a texture or a color set.

## Examples

    -- Position and size
    local HappinessIndicator = self:CreateTexture(nil, 'OVERLAY')
    HappinessIndicator:SetSize(16, 16)
	HappinessIndicator:SetPoint('TOPRIGHT')

    -- Register it with oUF
    self.HappinessIndicator = HappinessIndicator
--]]

local _, ns = ...
local oUF = ns.oUF

if(oUF.isRetail) then return end

local function Update(self, event, unit)
	if(not unit or not UnitIsUnit(unit, 'pet')) then
		return
	end

	local element = self.HappinessIndicator

	if(element.PreUpdate) then
		--[[ Callback: HappinessIndicator:PreUpdate(unit)
		Called after the element has been updated.

		* self - the HappinessIndicator element
		* unit - the unit for which the update has been triggered (string)
		--]]
		element:PreUpdate(unit)
	end

	local happiness, damagePercentage, loyaltyRate = GetPetHappiness(unit)
	if(happiness) then
		if(happiness == 1) then
			-- unhappy
			element:SetTexCoord(0.375, 0.5625, 0, 0.359375)
		elseif(happiness == 3) then
			-- happy
			element:SetTexCoord(0, 0.1875, 0, 0.359375)
		else
			-- content
			element:SetTexCoord(0.1875, 0.375, 0, 0.359375)
		end

		element:Show()
	else
		element:Hide()
	end

	if(element.PostUpdate) then
		--[[ Callback: HappinessIndicator:PostUpdate(unit, happiness, damagePercentage)
		Called after the element has been updated.

		* self             - the HappinessIndicator element
		* unit             - the unit for which the update has been triggered (string)
		* happiness        - the numerical happiness value of the pet (1 = unhappy, 2 = content, 3 = happy) (number)
		* damagePercentage - damage percentage modifier (unhappy = 75, content = 100, happy = 125) (number)
		* loyaltyRate      - the rate at which the pet gains or loses happiness (number)
		--]]
		element:PostUpdate(unit, happiness, damagePercentage, loyaltyRate)
	end
end

local function Path(self, ...)
	--[[ Override: HappinessIndicator.Override(self, event, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.HappinessIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__pwner, 'ForceUpdate', 'pet')
end

local function Enable(self, unit)
	local element = self.HappinessIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		if(element:IsObjectType('Texture') and not element:GetTexture()) then
			element:SetTexture([[Interface\PetPaperDollFrame\UI-PetHappiness]])
		end

		self:RegisterEvent('UNIT_HAPPINESS', Path)

		return true
	end
end

local function Disable(self, unit)
	local element = self.HappinessIndicator
	if(element) then
		element:Hide()
	end
end

oUF:AddElement('HappinessIndicator', Path, Enable, Disable)
