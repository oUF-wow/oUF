--[[
# Element: Range Fader

Changes the opacity of a unit frame based on whether the frame's unit is in the player's range.

## Widget

Range - A table containing opacity values.

## Notes

Offline units are handled as if they are in range.

## Options

.outsideAlpha - Opacity when the unit is out of range. Defaults to 0.55 (number)[0-1].
.insideAlpha  - Opacity when the unit is within range. Defaults to 1 (number)[0-1].

## Examples

    -- Register with oUF
    self.Range = {
        insideAlpha = 1,
        outsideAlpha = 1/2,
    }
--]]

local _, ns = ...
local oUF = ns.oUF

local _FRAMES = {}
local OnRangeFrame

local UnitInRange, UnitIsConnected = UnitInRange, UnitIsConnected

-- updating of range.
local timer = 0
local function OnRangeUpdate(self, elapsed)
	timer = timer + elapsed

	if(timer >= .20) then
		for _, object in next, _FRAMES do
			if(object:IsShown()) then
				local element = object.Range
				if(UnitIsConnected(object.unit)) then
					local inRange, checkedRange = UnitInRange(object.unit)
					if(checkedRange and not inRange) then
						--[[ Override: Range:Override(status)
						Used to override the calls to :SetAlpha().

						* self   - the unit frame holding the Range element
						* status - the unit's range status (string)['inside', 'outside', 'offline']
						--]]
						if(element.Override) then
							element.Override(object, 'outside')
						else
							object:SetAlpha(element.outsideAlpha)
						end
					else
						if(element.Override) then
							element.Override(object, 'inside')
						elseif(object:GetAlpha() ~= element.insideAlpha) then
							object:SetAlpha(element.insideAlpha)
						end
					end
				else
					if(element.Override) then
						element.Override(object, 'offline')
					elseif(object:GetAlpha() ~= element.insideAlpha) then
						object:SetAlpha(element.insideAlpha)
					end
				end
			end
		end

		timer = 0
	end
end

local function Enable(self)
	local element = self.Range
	if(element) then
		element.insideAlpha = element.insideAlpha or 1
		element.outsideAlpha = element.outsideAlpha or 0.55
		table.insert(_FRAMES, self)

		if(not OnRangeFrame) then
			OnRangeFrame = CreateFrame('Frame')
			OnRangeFrame:SetScript('OnUpdate', OnRangeUpdate)
		end

		OnRangeFrame:Show()

		return true
	end
end

local function Disable(self)
	local element = self.Range
	if(element) then
		for index, frame in next, _FRAMES do
			if(frame == self) then
				table.remove(_FRAMES, index)
				break
			end
		end
		self:SetAlpha(1)

		if(#_FRAMES == 0) then
			OnRangeFrame:Hide()
		end
	end
end

oUF:AddElement('Range', nil, Enable, Disable)
