--[[ Runebar:
	Authors: Zariel, Haste
]]

if select(2, UnitClass("player")) ~= "DEATHKNIGHT" then return end

local parent, ns = ...
local oUF = ns.oUF

oUF.colors.runes = {
	{1, 0, 0, .5};    -- blood
	{0, .5, 0, .5};	  -- unholy
	{0, 1, 1, .5};    -- frost
	{.9, .1, 1, .5}; -- death
}

local runes = {
    {
        { rune=1, ready = true, runeType = 1, duration = 10, start = 0 },    -- RUNETYPE_BLOOD = 1
        { rune=2, ready = true, runeType = 1, duration = 10, start = 0 },    -- RUNETYPE_DEATH = 2
    },
    {
        { rune=1, ready = true, runeType = 2, duration = 10, start = 0 },    -- RUNETYPE_FROST = 3
        { rune=2, ready = true, runeType = 2, duration = 10, start = 0 },    -- RUNETYPE_CHROMATIC = 4
    },
    {
        { rune=1, ready = true, runeType = 3, duration = 10, start = 0 },
        { rune=2, ready = true, runeType = 3, duration = 10, start = 0 },
    },
}

local colors = {
    { 0.77, 0.12, 0.23, 1 }, -- RUNETYPE_BLOOD = 1
    { 0.3, 0.8, 0.1, 1 }, -- RUNETYPE_DEATH = 2
    { 0, 0.4, 0.7, 1 }, -- RUNETYPE_FROST = 3
    { 0.51, 0.23, 0.65, 1 }, -- RUNETYPE_CHROMATIC = 4
}
local OnUpdate = function(self, elapsed)
	local duration = self.duration + elapsed
	if(duration >= self.max) then
		return self:SetScript("OnUpdate", nil)
	else
		self.duration = duration
		return self:SetValue(duration)
	end
end

local UpdateType = function(self, event, rune, alt)
	-- local colors = colors[GetRuneType(rune) or alt]
	-- local rune = self.Runes[rune]
	-- local r, g, b = colors[1], colors[2], colors[3]

	-- rune:SetStatusBarColor(r, g, b)

	-- if(rune.bg) then
		-- local mu = rune.bg.multiplier or 1
		-- rune.bg:SetVertexColor(r * mu, g * mu, b * mu)
	-- end
	
	   
    local runeType = GetRuneType( rune )
    
    local place, pool, modificator
    if rune==1 then
        pool = 1
        place = 1
    elseif rune==2 then
        pool = 1
        place = 2
    elseif rune==3 then
        pool = 2
        place = 1
    elseif rune==4 then
        pool = 2
        place = 2
    elseif rune==5 then
        pool = 3
        place = 1
    elseif rune==6 then
        pool = 3
        place = 2
    end
    if place==1 then modificator = 1 else modificator = -1 end
    
    runes[pool][place].runeType = runeType
    
    local runeOther = rune+modificator
    local time = GetTime()
    if time-runes[pool][1].start<time-runes[pool][2].start then
        rune, runeOther = runeOther, rune
    end
    
    self.Runes[rune]:SetStatusBarColor( unpack( colors[runes[pool][place].runeType] ) )
    self.Runes[runeOther]:SetStatusBarColor( unpack( colors[runes[pool][place+modificator].runeType] ) )
	
end

local function UpdateSingleRune( self, elapsed )
    
    local duration = self.duration + elapsed
    self.lastDuration = duration
    
    if duration>=self.max then
        self:SetScript( "OnUpdate", nil )
    else
        self.duration = duration
        self:SetValue( duration )
    end
end

local UpdateRune = function(self, event, rune)

if not rune then return end
local place, pool, modificator

    if rune==1 then
        pool = 1
        place = 1
    elseif rune==2 then
        pool = 1
        place = 2
    elseif rune==3 then
        pool = 2
        place = 1
    elseif rune==4 then
        pool = 2
        place = 2
    elseif rune==5 then
        pool = 3
        place = 1
    elseif rune==6 then
        pool = 3
        place = 2
    end
    if place==1 then modificator = 1 else modificator = -1 end
    
    local runeOther = rune+modificator
    
    local time = GetTime()
    
    local start, duration, runeReady = GetRuneCooldown( rune )
    runes[pool][place].ready = runeReady
    runes[pool][place].duration = time-start
    runes[pool][place].start = start
    runes[pool][place].max = duration
    
    local start, duration, runeReady = GetRuneCooldown( runeOther )
    runes[pool][place+modificator].ready = runeReady
    runes[pool][place+modificator].duration = time-start
    runes[pool][place+modificator].start = start
    runes[pool][place+modificator].max = duration
    
    if time-runes[pool][1].start<time-runes[pool][2].start then
        rune, runeOther = runeOther, rune
    end
    
    if runes[pool][place].ready then
        self.Runes[rune]:SetMinMaxValues( 0, 1 )
        self.Runes[rune]:SetValue( 1 )
        self.Runes[rune]:SetScript( "OnUpdate", nil )
        self.Runes[rune]:SetAlpha( 1 )
        self.Runes[rune].lastDuration = 0
    else
        self.Runes[rune].duration = time-runes[pool][place].start
        self.Runes[rune].max = runes[pool][place].max
        self.Runes[rune].start = runes[pool][place].start
        self.Runes[rune]:SetMinMaxValues( 0, self.Runes[rune].max )
        self.Runes[rune]:SetScript( "OnUpdate", self.Runes[rune].onUpdate )
        self.Runes[rune]:SetAlpha( 0.4 )
        
        if self.Runes[rune].duration<0 then self.Runes[rune]:SetValue( 0 ) end
    end
    self.Runes[rune]:SetStatusBarColor( unpack( colors[runes[pool][place].runeType] ) )
    
    if runes[pool][place+modificator].ready then
        self.Runes[runeOther]:SetMinMaxValues( 0, 1 )
        self.Runes[runeOther]:SetValue( 1 )
        self.Runes[runeOther]:SetScript( "OnUpdate", nil )
        self.Runes[runeOther]:SetAlpha( 1 )
        self.Runes[runeOther].lastDuration = 0
    else
        self.Runes[runeOther].duration = time-runes[pool][place+modificator].start
        self.Runes[runeOther].max = runes[pool][place+modificator].max
        self.Runes[runeOther].start = runes[pool][place+modificator].start
        self.Runes[runeOther]:SetMinMaxValues( 0, self.Runes[runeOther].max )
        self.Runes[runeOther]:SetScript( "OnUpdate", self.Runes[runeOther].onUpdate )
        self.Runes[runeOther]:SetAlpha( 0.4 )
        
        if self.Runes[runeOther].duration<0 then self.Runes[runeOther]:SetValue( 0 ) end
    end
    self.Runes[runeOther]:SetStatusBarColor( unpack( colors[runes[pool][place+modificator].runeType] ) )
	
end

local Update = function(self, event)
	for i=1, 6 do
		UpdateRune(self, event, i)
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, 'ForceUpdate')
end

local Enable = function(self, unit)
	local runes = self.Runes
	if(runes and unit == 'player') then
		runes.__owner = self
		runes.ForceUpdate = ForceUpdate

		for i=1, 6 do
			local rune = runes[i]
			rune:SetID(i)
			rune.start = 0
			rune.max = 0
			rune.duration = 0
			rune.lastDuration = 0
			rune.switched = false
			rune.lastUpdate = 0
			rune.onUpdate = UpdateSingleRune
			
			-- From my minor testing this is a okey solution. A full login always remove
			-- the death runes, or at least the clients knowledge about them.
			UpdateType(self, nil, i, math.floor((i+1)/2))

			if(rune:IsObjectType'StatusBar' and not rune:GetStatusBarTexture()) then
				rune:SetStatusBarTexture[[Interface\TargetingFrame\UI-StatusBar]]
			end
		end

		self:RegisterEvent("RUNE_POWER_UPDATE", UpdateRune, true)
		self:RegisterEvent("RUNE_TYPE_UPDATE", UpdateType, true)

		runes:Show()

		-- oUF leaves the vehicle events registered on the player frame, so
		-- buffs and such are correctly updated when entering/exiting vehicles.
		--
		-- This however makes the code also show/hide the RuneFrame.
		RuneFrame.Show = RuneFrame.Hide
		RuneFrame:Hide()

		return true
	end
end

local Disable = function(self)
	self.Runes:Hide()
	RuneFrame.Show = nil
	RuneFrame:Show()

	self:UnregisterEvent("RUNE_POWER_UPDATE", UpdateRune)
	self:UnregisterEvent("RUNE_TYPE_UPDATE", UpdateType)
end

oUF:AddElement("Runes", Update, Enable, Disable)
