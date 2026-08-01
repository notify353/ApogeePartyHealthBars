local rules = {
    {
        token = "C_AddOns.GetAddOnMetadata(",
        allowed = { ApogeePartyHealthBars_ClientCapabilities = true },
    },
    {
        token = "UnitBuff(",
        allowed = { ApogeePartyHealthBars_Auras = true },
    },
    {
        token = "UnitHealth",
        pattern = "%f[%a]UnitHealth%s*%(",
        allowed = { ApogeePartyHealthBars_UnitAPI = true },
    },
    {
        token = "UnitHealthMax",
        pattern = "%f[%a]UnitHealthMax%s*%(",
        allowed = { ApogeePartyHealthBars_UnitAPI = true },
    },
    {
        token = "GetSpellBookItemInfo(",
        allowed = { ApogeePartyHealthBars_PlayerSpells = true },
    },
    {
        token = "GetSpellBookItemName(",
        allowed = { ApogeePartyHealthBars_PlayerSpells = true },
    },
    {
        token = "C_Spell.GetSpellDescription(",
        allowed = { ApogeePartyHealthBars_PlayerSpells = true },
    },
    {
        token = "SetBinding(",
        allowed = { ApogeePartyHealthBars_BoundActionBindings = true },
    },
    {
        token = "UnitGetIncomingHeals(",
        allowed = { ApogeePartyHealthBars_IncomingHeals = true },
    },
    {
        token = "UnitDetailedThreatSituation(",
        allowed = {
            ApogeePartyHealthBars_Threat = true,
            ApogeePartyHealthBars_ThreatObserver = true,
        },
    },
    {
        token = "SetRaidTarget(",
        allowed = { ApogeePartyHealthBars_RaidMarkers = true },
    },
    {
        token = "C_NamePlate.GetNamePlateForUnit",
        allowed = {
            ApogeePartyHealthBars_ClientCapabilities = true,
            ApogeePartyHealthBars_TargetNameplateHud = true,
        },
    },
}

local toc = assert(io.open("ApogeePartyHealthBars.toc", "rb"))
local sources = {}
for line in toc:lines() do
    local path = line:match("^([^#].-%.lua)%s*$")
    if path then sources[#sources + 1] = path end
end
toc:close()

for _, path in ipairs(sources) do
    local file = assert(io.open(path, "rb"))
    local body = file:read("*a")
    file:close()
    local shortName = body:match("ApogeePartyHealthBars_([%w]+)%s*=%s*{}")
    local module = shortName and ("ApogeePartyHealthBars_" .. shortName) or path
    for _, rule in ipairs(rules) do
        local found
        if rule.pattern then
            found = body:find(rule.pattern)
        else
            found = body:find(rule.token, 1, true)
        end
        if found then
            assert(rule.allowed[module], path .. " bypasses the compatibility boundary for "
                .. rule.token)
        end
    end
end

print("PASS volatile API compatibility boundaries")
