local _, ns = ...
local oUF = ns.oUF

-- we have to do this until Blizzard decides to add an Enum
oUF.Enum = {}
oUF.Enum.DebuffType = {
	-- https://wago.tools/db2/SpellDispelType
	None = 0,
	Magic = 1,
	Curse = 2,
	Disease = 3,
	Poison = 4,
	Enrage = 9,
	Bleed = 11,
}
