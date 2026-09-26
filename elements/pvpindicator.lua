--[[
# Element: PvP and Honor Level Icons

Handles the visibility and updating of an indicator based on the unit's PvP status and honor level.

## Widget

PvPIndicator - A `Texture` used to display faction or FFA PvP status.

## Sub-Widgets

Badge - An optional `Texture` used to display the honor level background image.
Portrait - An optional `Texture` used to display the honor level portrait image.

## Notes

This element updates by changing the texture and alpha.
The `Badge` sub-widget should be on a lower sub-layer than the element.
If the `Badge` sub-widget is provided the faction-based textures will not be used.

## Examples

    -- Position and size
    local PvPIndicator = self:CreateTexture(nil, 'ARTWORK')
    PvPIndicator:SetSize(30, 30)
    PvPIndicator:SetPoint('RIGHT', self, 'LEFT')

    local layer, sublayer = PvPIndicator:GetDrawLayer()
    local Badge = self:CreateTexture(nil, layer, nil, sublayer - 1)
    Badge:SetSize(50, 52)
    Badge:SetPoint('CENTER', PvPIndicator)

    -- Register it with oUF
    PvPIndicator.Badge = Badge
    self.PvPIndicator = PvPIndicator
--]]

local _, ns = ...
local oUF = ns.oUF
local Private = oUF.Private

local GameVersion = Private.GameVersion
local GameCompatibility = Private.GameCompatibility

local function Update(self, event, unit)
	if(unit and unit ~= self.__unit) then return end

	local element = self.PvPIndicator
	unit = unit or self.__unit

	--[[ Callback: PvPIndicator:PreUpdate(unit)
	Called before the element has been updated.

	* self - the PvPIndicator element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local status, info
	if(GameVersion.PTR or GameVersion.Forever) then
		if(element.Badge and GameCompatibility.BattleForAzeroth and UnitIsHumanPlayer(unit)) then
			info = UnitFrameUtil.GetUnitPvPIndicatorDisplayInfo(unit, true)

			element:SetTexture(info.prestigeBadgeTexture)
			element:SetAlphaFromBoolean(info.showPrestigeBadge, 1, 0)

			element.Badge:SetAtlas(info.prestigePortraitTexture)
			element.Badge:SetAlphaFromBoolean(info.showPrestigePortrait, 1, 0)
		else
			if(element.Badge) then
				-- hide it in case we're not on a compatible version of the game
				element.Badge:SetAlpha(0)
			end

			-- we can't use the UnitFrameUtil to determine the pvp icon, as it doesn't provide it
			-- if the honor reward API returns data (a bug in the util, Blizzard is aware)
			if(UnitIsPVPFreeForAll(unit)) then
				status = 'FFA'
			else
				local factionGroup = UnitFactionGroup(unit)
				if(unit == 'player' and UnitIsMercenary(unit)) then
					if(factionGroup == 'Horde') then
						factionGroup = 'Alliance'
					elseif(factionGroup == 'Alliance') then
						factionGroup = 'Horde'
					end
				elseif(not UnitIsHumanPlayer(unit)) then
					local playerFactionGroup = UnitFactionGroup('player')
					if(UnitIsEnemy('player', unit)) then
						if(playerFactionGroup == 'Alliance') then
							factionGroup = 'Horde'
						elseif(playerFactionGroup == 'Horde') then
							factionGroup = 'Alliance'
						end
					else
						factionGroup = playerFactionGroup
					end
				end

				if(factionGroup ~= 'Neutral') then
					status = factionGroup
				end
			end

			if(status) then
				element:SetAtlas('UI-HUD-UnitFrame-Player-PVP-' .. status .. 'Icon', true)
				element:SetAlphaFromBoolean(UnitIsPVP(unit), 1, 0)
			end
		end
	else
		local factionGroup = UnitFactionGroup(unit) or 'Neutral'
		if(unit == 'player' and UnitIsMercenary(unit)) then
			if(factionGroup == 'Horde') then
				factionGroup = 'Alliance'
			elseif(factionGroup == 'Alliance') then
				factionGroup = 'Horde'
			end
		end

		if(UnitIsPVPFreeForAll(unit)) then
			status = 'FFA'
		else
			local isPvP = UnitIsPVP(unit)
			if(factionGroup ~= 'Neutral' and not issecretvalue(isPvP) and isPvP) then
				status = factionGroup
			end
		end

		if(status) then
			element:Show()

			local honorRewardInfo
			local honorLevel = UnitHonorLevel(unit)
			if(not issecretvalue(honorLevel)) then
				honorRewardInfo = C_PvP.GetHonorRewardInfo(honorLevel)
			end

			if(element.Badge and honorRewardInfo) then
				element:SetTexture(honorRewardInfo.badgeFileDataID)
				element:SetTexCoord(0, 1, 0, 1)
				element.Badge:SetAtlas('honorsystem-portrait-' .. factionGroup, false)
				element.Badge:Show()
			else
				element:SetTexture([[Interface\TargetingFrame\UI-PVP-]] .. status)
				element:SetTexCoord(0, 0.65625, 0, 0.65625)

				if(element.Badge) then
					element.Badge:Hide()
				end
			end
		else
			element:Hide()

			if(element.Badge) then
				element.Badge:Hide()
			end
		end
	end

	--[[ Callback: PvPIndicator:PostUpdate(unit)
	Called after the element has been updated.

	* self   - the PvPIndicator element
	* unit   - the unit for which the update has been triggered (string)
	* status - the unit's current PvP status or faction accounting for mercenary mode (string?)
	* info   - information about the badge and portrait textures (table?)
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, status, info)
	end
end

local function Path(self, ...)
	--[[Override: PvPIndicator.Override(self, event, ...)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* ...   - the arguments accompanying the event
	--]]
	return (self.PvPIndicator.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.__unit)
end

local function Enable(self)
	local element = self.PvPIndicator
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent('UNIT_FACTION', Path)
		self:RegisterEvent('HONOR_LEVEL_UPDATE', Path, true)
		self:RegisterEvent('PLAYER_REGEN_ENABLED', Path, true)

		return true
	end
end

local function Disable(self)
	local element = self.PvPIndicator
	if(element) then
		element:Hide()

		if(element.Badge) then
			element.Badge:Hide()
		end

		self:UnregisterEvent('UNIT_FACTION', Path)
		self:UnregisterEvent('HONOR_LEVEL_UPDATE', Path)
		self:UnregisterEvent('PLAYER_REGEN_ENABLED', Path)
	end
end

oUF:AddElement('PvPIndicator', Path, Enable, Disable)
