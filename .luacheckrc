std = 'lua51'

quiet = 1 -- suppress report output for files without warnings

ignore = {
	'2/self', -- unused argument self
	'2/event', -- unused argument event
	-- '212', -- unused arguments
	'3/event', -- unused value event
	'4', -- shadowing
	'631', -- line is too long
}

read_globals = {
	'debugstack',
	'geterrorhandler',
	string = {fields = {'join', 'split', 'trim'}},
	table = {fields = {'removemulti', 'wipe'}},

	-- FrameXML
	'CastingBarFrame',
	'CastingBarFrame_OnLoad',
	'CastingBarFrame_SetUnit',
	'ComboFrame',
	'Enum',
	'FocusFrame',
	'MonkStaggerBar',
	'NamePlateDriverFrame',
	'PetCastingBarFrame',
	'PetCastingBarFrame_OnLoad',
	'PetFrame',
	'PlayerFrame',
	'PlayerPowerBarAlt',
	'TargetFrame',
	'TargetFrameToT',
	'TargetofFocusFrame',
	'TotemFrame',
	'UIParent',
	'GameTooltip',
	'GameTooltip_SetDefaultAnchor',

	-- namespaces
	'C_IncomingSummon',
	'C_NamePlate',
	'C_PvP',

	-- API
	'CopyTable',
	'CreateFrame',
	'GetAddOnMetadata',
	'GetArenaOpponentSpec',
	'GetNetStats',
	'GetNumArenaOpponentSpecs',
	'GetPartyAssignment',
	'GetRaidTargetIndex',
	'GetReadyCheckStatus',
	'GetRuneCooldown',
	'GetSpecialization',
	'GetSpecializationInfoByID',
	'GetSpellPowerCost',
	'GetTexCoordsForRoleSmallCircle',
	'GetThreatStatusColor',
	'GetTime',
	'GetTotemInfo',
	'GetUnitChargedPowerPoints',
	'GetUnitPowerBarInfo',
	'GetUnitPowerBarInfoByID',
	'GetUnitPowerBarStringsByID',
	'IsLoggedIn',
	'IsPlayerSpell',
	'IsResting',
	'PartyUtil',
	'PlayerVehicleHasComboPoints',
	'PowerBarColor',
	'RegisterAttributeDriver',
	'RegisterStateDriver',
	'RegisterUnitWatch',
	'SecureButton_GetModifiedUnit',
	'SecureButton_GetUnit',
	'SecureHandlerSetFrameRef',
	'SetCVar',
	'SetPortraitTexture',
	'SetRaidTargetIconTexture',
	'ShowBossFrameWhenUninteractable',
	'UnitAffectingCombat',
	'UnitAura',
	'UnitCastingInfo',
	'UnitChannelInfo',
	'UnitClass',
	'UnitExists',
	'UnitFactionGroup',
	'UnitGUID',
	'UnitGetIncomingHeals',
	'UnitGetTotalAbsorbs',
	'UnitGetTotalHealAbsorbs',
	'UnitGroupRolesAssigned',
	'UnitHasIncomingResurrection',
	'UnitHasVehiclePlayerFrameUI',
	'UnitHasVehicleUI',
	'UnitHealth',
	'UnitHealthMax',
	'UnitHonorLevel',
	'UnitInParty',
	'UnitInRaid',
	'UnitInRange',
	'UnitIsConnected',
	'UnitIsGroupAssistant',
	'UnitIsGroupLeader',
	'UnitIsMercenary',
	'UnitIsPVP',
	'UnitIsPVPFreeForAll',
	'UnitIsPlayer',
	'UnitIsQuestBoss',
	'UnitIsTapDenied',
	'UnitIsUnit',
	'UnitIsVisible',
	'UnitPhaseReason',
	'UnitPlayerControlled',
	'UnitPower',
	'UnitPowerBarID',
	'UnitPowerDisplayMod',
	'UnitPowerMax',
	'UnitPowerType',
	'UnitPvpClassification',
	'UnitRace',
	'UnitReaction',
	'UnitSelectionType',
	'UnitStagger',
	'UnitThreatSituation',
	'UnitWatchRegistered',
	'UnregisterUnitWatch',
}
