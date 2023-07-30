local _, ns = ...
ns.oUF = {}
ns.oUF.Private = {}

-- toc file
local Interface = select(4, GetBuildInfo())
ns.oUF.Interface = Interface

-- https://wowpedia.fandom.com/wiki/WOW_PROJECT_ID
ns.oUF.isRetail = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE)
ns.oUF.isClassic = (WOW_PROJECT_ID == WOW_PROJECT_CLASSIC)
ns.oUF.isTBC = (WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
ns.oUF.isWotLK = (WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC)
