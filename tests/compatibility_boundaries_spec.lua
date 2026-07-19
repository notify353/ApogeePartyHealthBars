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
        token = "SetBinding(",
        allowed = { ApogeePartyHealthBars_BoundActionBindings = true },
    },
    {
        token = "UnitGetIncomingHeals(",
        allowed = { ApogeePartyHealthBars_IncomingHeals = true },
    },
    {
        token = "UnitDetailedThreatSituation(",
        allowed = { ApogeePartyHealthBars_Threat = true },
    },
    {
        token = "SetRaidTarget(",
        allowed = { ApogeePartyHealthBars_RaidMarkers = true },
    },
}

local toc = assert(io.open("ApogeePartyHealthBars.toc", "rb"))
local sources = {}
for line in toc:lines() do
    local module = line:match("^(ApogeePartyHealthBars[^/\\]-)%.lua%s*$")
    if module then sources[#sources + 1] = module end
end
toc:close()

for _, module in ipairs(sources) do
    local file = assert(io.open(module .. ".lua", "rb"))
    local body = file:read("*a")
    file:close()
    for _, rule in ipairs(rules) do
        local found
        if rule.pattern then
            found = body:find(rule.pattern)
        else
            found = body:find(rule.token, 1, true)
        end
        if found then
            assert(rule.allowed[module], module .. " bypasses the compatibility boundary for "
                .. rule.token)
        end
    end
end

print("PASS volatile API compatibility boundaries")
