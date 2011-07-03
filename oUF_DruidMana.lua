-- Druid Mana Bar for Cat and Bear forms
-- Authors: Califpornia aka Ennie // some code taken from oUF`s EclipseBar element

local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, 'oUF_DruidManaBar was unable to locate oUF install')

if(select(2, UnitClass('player')) ~= 'DRUID') then return end

--tag
oUF.Tags['druidmana']  = function() 
	local min, max = UnitPower('player', SPELL_POWER_MANA), UnitPowerMax('player', SPELL_POWER_MANA)
	if min ~= max then 
		return min
	else
		return max
	end
end
oUF.TagEvents['druidmana'] = 'UNIT_POWER UNIT_MAXPOWER'
	
local function Update(self, event, unit)
	if(self.unit ~= unit) then return end

	local druidmana = self.DruidMana
    if (druidmana.PreUpdate) then druidmana:PreUpdate(unit) end
    
    --check form
	if (UnitPowerType(unit) == SPELL_POWER_MANA) then
        return druidmana:Hide()
    else
        druidmana:Show()
    end
    
	local min, max = UnitPower('player', SPELL_POWER_MANA), UnitPowerMax('player', SPELL_POWER_MANA)
    druidmana:SetMinMaxValues(0, max)
    druidmana:SetValue(min)
    
    local r, g, b, t
    if (druidmana.colorClass and UnitIsPlayer(unit)) then
        t = self.colors.class['DRUID']
    elseif (druidmana.colorSmooth) then
        r, g, b = self.ColorGradient(min / max, unpack(health.smoothGradient or self.colors.smooth))
    else
        t = self.colors.power['MANA']
    end
    
    if (t) then
        r, g, b = t[1], t[2], t[3]
    end        

    if (b) then
        druidmana:SetStatusBarColor(r, g, b)

        local bg = druidmana.bg
        if (bg) then local mu = bg.multiplier or 1
            bg:SetVertexColor(r * mu, g * mu, b * mu)
        end
    end 
    
    if(druidmana.PostUpdate) then
        return druidmana:PostUpdate(unit)
    end
end

local function Path(self, ...)
	return (self.DruidMana.Override or Update) (self, ...)
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local OnPowerUpdate
do
	local UnitPower, UnitPowerType = UnitPower, UnitPowerType
	OnPowerUpdate = function(self)
		local unit = self.__owner.unit
		local mana = UnitPower(unit, SPELL_POWER_MANA)
        local powertype = UnitPowerType(unit)
        
		if(powertype ~= self.powertype or mana ~= self.min) then
			self.min = mana
            self.powertype = powertype
            
			return Path(self.__owner, 'OnPowerUpdate', unit)
		end
	end
end

local Enable = function(self, unit)
    local druidmana = self.DruidMana
    if (druidmana and unit == 'player') then
        druidmana.__owner = self
        druidmana.ForceUpdate = ForceUpdate

        if(druidmana.frequentUpdates and unit == 'player') then
			druidmana:SetScript('OnUpdate', OnPowerUpdate)
		else
			self:RegisterEvent('UNIT_POWER', Path)
		end
        self:RegisterEvent('UNIT_MAXPOWER', Path)
        --self:RegisterEvent('UPDATE_SHAPESHIFT_FORM', Path)

        if (not druidmana:GetStatusBarTexture()) then
			druidmana:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end
        
        return true
    end
end

local Disable = function(self)
    local druidmana = self.DruidMana
    if (druidmana) then
        if(druidmana:GetScript'OnUpdate') then
            druidmana:SetScript("OnUpdate", nil)
        else
            self:UnregisterEvent('UNIT_POWER', Path)
        end
        self:UnregisterEvent('UNIT_MAXPOWER', Path)
        --self:UnregisterEvent('UPDATE_SHAPESHIFT_FORM', Path)
    end
end

oUF:AddElement('DruidMana', Path, Enable, Disable)