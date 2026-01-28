--[[
# Element: PrivateAuras

Handles positioning and configuration of private aura frames on player and group.

## Notes

These auras are fully controlled by Blizzard, so the structure of this element is unconventional.
oUF provides a means to create the auras and initiate them into Blizzard's care, but is otherwise
unable to provide customizations other than size and positioning.

## Options

.disableCooldown     - Disables the cooldown spiral (boolean)
.disableCooldownText - Disables the cooldown duration text (boolean)
.size                - Private aura anchor frame size. Defaults to 16 (number)
.width               - Private aura anchor frame width. Takes priority over `size` (number)
.height              - Private aura anchor frame height. Takes priority over `size` (number)
.spacing             - Spacing between each private aura anchor frame. Defaults to 0 (number)
.spacingX            - Horizontal spacing between each private aura anchor frame. Takes priority over `spacing` (number)
.spacingY            - Vertical spacing between each private aura anchor frame. Takes priority over `spacing` (number)
.growthX             - Horizontal growth direction. Defaults to 'RIGHT' (string)
.growthY             - Vertical growth direction. Defaults to 'UP' (string)
.initialAnchor       - Anchor point for the private aura anchor frame. Defaults to 'BOTTOMLEFT' (string)
.num                 - Number of private aura anchor frames to create. Defaults to 6 (number)
.maxCols             - Maximum number of private aura columns before wrapping to a new row. Defaults to element width divided by private aura anchor frame size (number)
.borderScale         - Scale of the private aura border (number?)

## Examples

    -- Position
    local PrivateAuras = CreateFrame('Frame', nil, self)
    PrivateAuras:SetPoint('CENTER', self)
    PrivateAuras:SetSize(60, 30)

    -- Register with oUF
    self.PrivateAuras = PrivateAuras
--]]

local _, ns = ...
local oUF = ns.oUF

local function CreateAura(element, index)
	-- similar to BuffFramePrivateAuraAnchorTemplate
	local aura = CreateFrame('Frame', nil, element)

	-- each sub-widget just acts as anchor points (frames) and cannot be used to customize things
	-- like texture coordinates or font size
	local icon = CreateFrame('Frame', nil, aura)
	icon:SetAllPoints()
	aura.Icon = icon

	local duration = CreateFrame('Frame', nil, aura)
	duration:SetPoint('CENTER')
	aura.Duration = duration

	--[[ Callback: PrivateAuras:PostCreateAura(aura, auraIndex)
	Called after a private aura anchor frame has been created.

	* self      - the PrivateAuras element
	* aura      - the private aura anchor frame to be positioned
	* auraIndex - the index of the private aura anchor frame
	--]]
	if(element.PostCreateAura) then element:PostCreateAura(aura, index) end

	return aura
end

local function SetPosition(element, aura, auraIndex)
	-- more or less copied straight from Auras
	local width = element.width or element.size or 16
	local height = element.height or element.size or 16
	local sizeX = width + (element.spacingX or element.spacing or 0)
	local sizeY = height + (element.spacingY or element.spacing or 0)
	local anchor = element.initialAnchor or 'BOTTOMLEFT'
	local growthX = (element.growthX == 'LEFT' and -1) or 1
	local growthY = (element.growthY == 'DOWN' and -1) or 1
	local cols = element.maxCols or math.floor(element:GetWidth() / sizeX + 0.5)

	local col = (auraIndex - 1) % cols
	local row = math.floor((auraIndex - 1) / cols)

	aura:ClearAllPoints()
	aura:SetPoint(anchor, element, anchor, col * sizeX * growthX, row * sizeY * growthY)
end

local function resetAnchors(element)
	for _, anchor in next, element.anchors do
		C_UnitAuras.RemovePrivateAuraAnchor(anchor)
	end

	table.wipe(element.anchors)
end

local function Update(element)
	if(element.anchors) then
		resetAnchors(element)
	else
		element.anchors = {}
	end

	for index = 1, (element.num or 6) do -- 5 or 6 is what Blizzard creates, so we default to that
		local aura = element[index]
		if(not aura) then
			--[[ Override: PrivateAuras:CreateAura(auraIndex)
			Used to completely override the internal function for creating private aura anchor frames.

			* self      - the PrivateAuras element
			* auraIndex - the index of the private aura anchor frame
			--]]
			aura = (element.CreateAura or CreateAura) (element, index)
			table.insert(element, aura)
		end

		aura:SetSize(element.width or element.size or 16, element.height or element.size or 16)

		--[[ Override: PrivateAuras:SetPosition(aura, auraIndex)
		Used to completely override the internal function for (re-)positioning private aura anchor
		frames. Called when new auras have been created.

		* self      - the PrivateAuras element
		* aura      - the private aura anchor frame to be positioned
		* auraIndex - the index of the private aura anchor frame
		--]]
		do -- otherwise the below call is "too ambiguous"
			(element.SetPosition or SetPosition) (element, aura, index)
		end

		table.insert(element.anchors, C_UnitAuras.AddPrivateAuraAnchor({
			unitToken = element.__owner.unit,
			auraIndex = index,
			parent = aura,
			showCountdownFrame = not element.disableCooldown,
			showCountdownNumbers = false, -- these are not flexible at all, use duration instead
			iconInfo = {
				iconWidth = aura:GetWidth(),
				iconHeight = aura:GetHeight(),
				iconAnchor = {
					-- we anchor to sub-widgets of each "aura" frame to make it easier to move
					-- after-the-fact
					point = 'CENTER',
					relativeTo = aura.Icon,
					relativePoint = 'CENTER',
					offsetX = 0,
					offsetY = 0,
				},
				borderScale = element.borderScale,
			},
			durationAnchor = not element.disableCooldownText and {
				-- same thing as with iconAnchor
				point = 'CENTER',
				relativeTo = aura.Duration,
				relativePoint = 'CENTER',
				offsetX = 0,
				offsetY = 0,
			},
		}))
	end

	--[[ Callback: PrivateAuras:PostUpdate()
	Called after the element has been updated.

	* self - the PrivateAuras element
	--]]
	if(element.PostUpdate) then element:PostUpdate() end
end

local function ForceUpdate(element)
	return Update(element)
end

local function Disable(self)
	local element = self.PrivateAuras
	if(element and element.anchors) then
		resetAnchors(element)
	end
end

local function Enable(self)
	if(self.unit ~= 'player' and not self.unit:match('raid%d?$') and not self.unit:match('party%d?$')) then
		Disable(self)

		return false
	end

	local element = self.PrivateAuras
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		-- the Update method doesn't really update element, it's just used to create and position
		-- each aura and then register them with Blizzard's system, and as such we don't want to
		-- trigger this frequently (like on UAE).

		--[[ Override: PrivateAuras:Override()
		Used to completely override the internal function for creating, positioning and registering
		all private auras.

		* self - the PrivateAuras element
		--]]
		do -- otherwise the below call is "too ambiguous"
			(element.Override or Update) (element)
		end

		return true
	end
end

oUF:AddElement('PrivateAuras', nil, Enable, Disable)
