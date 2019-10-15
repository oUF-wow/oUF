local parent, ns = ...
ns.oUF = {}
ns.oUF.Private = {}

ns.oUF.isClassic = select(4, GetBuildInfo()) == 11302
ns.oUF.isRetail = not ns.oUF.isClassic
