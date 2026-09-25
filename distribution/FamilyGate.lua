-- Generated package loading safety, schema 1. No gameplay or saved state.
local name, namespace = ...
local expectedName, family = "@NAME@", "@FAMILY@"
if type(namespace) == "table" then namespace.__ApogeeFamilyAdmission = nil end
if type(namespace) ~= "table" or name ~= expectedName then return end
local members = {"ApogeeHeals", "ApogeeKeybinds", "ApogeeGroupAlert", "ApogeeEssentials", "ApogeeTank"}
local function decide()
    if type(issecretvalue) ~= "function" then error("secret-value API unavailable") end
    local function public(v) return not issecretvalue(v) end
    local function exact(v, want) return public(v) and v == want end
    local api = C_AddOns
    if type(api) ~= "table" or type(api.GetNumAddOns) ~= "function"
        or type(api.GetAddOnName) ~= "function" or type(api.GetAddOnMetadata) ~= "function"
        or type(api.GetAddOnEnableState) ~= "function" or type(api.IsAddOnLoaded) ~= "function"
        or type(UnitGUID) ~= "function" then error("addon selection API unavailable") end
    local character = UnitGUID("player")
    if not public(character) or type(character) ~= "string" or character == "" then
        error("current character unavailable; reload after login")
    end
    if type(Enum) ~= "table" or type(Enum.AddOnEnableState) ~= "table"
        or not exact(Enum.AddOnEnableState.None, 0)
        or not exact(Enum.AddOnEnableState.Some, 1)
        or not exact(Enum.AddOnEnableState.All, 2) then error("enable-state schema unavailable") end
    local installed = {}
    local count = api.GetNumAddOns()
    if not public(count) or type(count) ~= "number" or count < 0 or count > 10000 or count % 1 ~= 0 then
        error("addon inventory unavailable")
    end
    for i = 1, count do
        local addon = api.GetAddOnName(i)
        if not public(addon) or type(addon) ~= "string" or addon == "" then error("addon identity unavailable") end
        installed[addon] = true
    end
    local function metadata(addon, mode)
        return exact(api.GetAddOnMetadata(addon, "X-Apogee-Family-Schema"), "1")
            and exact(api.GetAddOnMetadata(addon, "X-Apogee-Family"), mode)
    end
    if not installed[name] or not metadata(name, family) then error("package metadata is unrecognized") end
    if family == "DEV" and installed.ApogeePartyHealthBars then
        if not metadata("ApogeePartyHealthBars", "PROD")
            or not exact(api.GetAddOnMetadata("ApogeePartyHealthBars", "X-Apogee-Distribution-Only"), "1")
            or not exact(api.GetAddOnMetadata("ApogeePartyHealthBars", "X-Apogee-Distribution-Schema"), "1") then
            error("legacy production APHB is installed; compatible distribution marker required")
        end
    end
    local production = false
    for _, addon in ipairs(members) do
        if installed[addon] then
            if family == "DEV" and not metadata(addon, "PROD") then
                error("installed production version lacks family safety; use a compatible release")
            end
            local enabled, loaded = api.GetAddOnEnableState(addon, character), api.IsAddOnLoaded(addon)
            if not public(enabled) or (enabled ~= 0 and enabled ~= 1 and enabled ~= 2)
                or not public(loaded) or type(loaded) ~= "boolean" then error("production state unavailable") end
            if enabled > 0 or loaded then production = true end
        end
    end
    local lease = rawget(_G, "ApogeeDistributionFamilyLease")
    local function valid(value)
        return public(value) and type(value) == "table" and getmetatable(value) == nil
            and exact(rawget(value, "schema"), 1)
            and (exact(rawget(value, "family"), "PROD") or exact(rawget(value, "family"), "DEV"))
    end
    if lease == nil then
        lease = {schema = 1, family = production and "PROD" or "DEV"}
        rawset(_G, "ApogeeDistributionFamilyLease", lease)
    elseif not valid(lease) then
        error("family safety state is unrecognized; reload required")
    end
    if not exact(rawget(lease, "family"), family) then error("other family selected; switch groups and reload") end
    namespace.__ApogeeFamilyAdmission = function(caller)
        local ok, admitted = pcall(function()
            return exact(caller, expectedName) and rawget(_G, "ApogeeDistributionFamilyLease") == lease
                and valid(lease) and exact(rawget(lease, "family"), family)
        end)
        return ok and admitted == true
    end
end
local ok, reason = pcall(decide)
if not ok then
    namespace.__ApogeeFamilyAdmission = nil
    -- Never stringify an API error/secret; diagnostics are intentionally generic.
    if type(print) == "function" then
        print("Apogee " .. family .. ": " .. expectedName .. " inactive. Check family selection/compatible packages and reload.")
    end
end
