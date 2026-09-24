-- Actual generated chunks must stop before side effects when their family is denied.
local root = arg[1]
local children = {"ApogeeHeals", "ApogeeKeybinds", "ApogeeGroupAlert", "ApogeeEssentials", "ApogeeTank"}
local savedPrint = print
local secret = {}
local logs, scenarios = {}, 0
local function setup(name, family, option)
    _G.ApogeeDistributionFamilyLease = nil
    local inventory = {name}
    if family == "DEV" then inventory[#inventory+1] = "ApogeeHeals" end
    local count = #inventory
    issecretvalue = function(value) return value == secret end
    UnitGUID = function(unit) assert(unit == "player"); return option == "no-guid" and nil or "Player-Fixture" end
    if option == "no-guid" then UnitGUID = function() return nil end end
    Enum = {AddOnEnableState={None=0, Some=1, All=2}}
    C_AddOns = {
        GetNumAddOns = function() return count end,
        GetAddOnName = function(i) return inventory[i] end,
        GetAddOnMetadata = function(addon, key)
            local mode = addon:sub(-3) == "Dev" and "DEV" or "PROD"
            if option == "old-prod" and mode == "PROD" then return nil end
            if option == "bad-metadata" then return "wrong" end
            if option == "secret-metadata" then return secret end
            if key == "X-Apogee-Family-Schema" then return "1" end
            if key == "X-Apogee-Family" then return mode end
        end,
        GetAddOnEnableState = function(addon, character)
            assert(character == "Player-Fixture")
            if option == "secret-state" then return secret end
            return option == "prod-enabled" and 2 or option == "prod-some" and 1 or 0
        end,
        IsAddOnLoaded = function() return option == "prod-loaded" end,
    }
    if option == "missing-api" then C_AddOns.GetAddOnEnableState = nil end
    if option == "error-api" then C_AddOns.GetAddOnMetadata = function() error("private error must not print") end end
    if option == "bad-enum" then Enum.AddOnEnableState.All = 9 end
    if option == "invalid-lease" then ApogeeDistributionFamilyLease = {schema=2, family=family} end
    if option == "opposite-lease" then ApogeeDistributionFamilyLease = {schema=1, family=family=="DEV" and "PROD" or "DEV"} end
    if option == "metatable-lease" then ApogeeDistributionFamilyLease=setmetatable({schema=1,family=family},{}) end
    print = function(message) assert(not message:find("private error")); logs[#logs+1] = message end
    InCombatLockdown = function() return true end
    local function forbidden() error("denied chunk performed a gameplay side effect") end
    CreateFrame, SetOverrideBindingClick, SetBinding, SaveBindings = forbidden, forbidden, forbidden, forbidden
    Settings, StaticPopupDialogs, SlashCmdList, UISpecialFrames = nil, nil, nil, nil
end
local function loadDenied(base, family, option)
    local name = base .. (family == "DEV" and "Dev" or "")
    setup(name, family, option)
    local ns = {}
    local before = {}
    for k, v in pairs(_G) do before[k] = v end
    for line in io.lines(root .. "/" .. family .. "/" .. name .. "/" .. name .. ".toc") do
        if line:match("%.lua$") then
            assert(loadfile(root .. "/" .. family .. "/" .. name .. "/" .. line))(name, ns)
        end
    end
    assert(next(ns) == nil, "denied runtime mutated private namespace")
    for k, v in pairs(_G) do
        if k ~= "ApogeeDistributionFamilyLease" then assert(before[k] == v, "denied runtime changed global "..k) end
    end
    scenarios = scenarios + 1
end
for _, base in ipairs(children) do
    for _, family in ipairs({"PROD", "DEV"}) do
        for _, option in ipairs({"no-guid", "bad-metadata", "secret-metadata", "secret-state", "missing-api",
                                 "error-api", "bad-enum", "invalid-lease", "opposite-lease", "metatable-lease"}) do
            loadDenied(base, family, option)
        end
    end
    for _, option in ipairs({"old-prod", "prod-enabled", "prod-some", "prod-loaded"}) do
        loadDenied(base, "DEV", option)
    end
end
-- PROD wins even when DEV bootstrap runs first; frozen session lease rejects a later opposite family.
for _, base in ipairs(children) do
    local dev = base .. "Dev"
    setup(dev, "DEV", "prod-enabled")
    local ns = {}
    assert(loadfile(root.."/DEV/"..dev.."/__Distribution/FamilyGate.lua"))(dev, ns)
    assert(ApogeeDistributionFamilyLease.family == "PROD" and ns.__ApogeeFamilyAdmission == nil)
    setup(dev, "DEV", "dev-enabled")
    assert(loadfile(root.."/DEV/"..dev.."/__Distribution/FamilyGate.lua"))(dev, ns)
    assert(ApogeeDistributionFamilyLease.family == "DEV" and ns.__ApogeeFamilyAdmission(dev))
    assert(not ns.__ApogeeFamilyAdmission(base))
    local lease = ApogeeDistributionFamilyLease
    C_AddOns.GetNumAddOns = function() return 1 end
    C_AddOns.GetAddOnName = function() return base end
    C_AddOns.GetAddOnEnableState = function() return 2 end
    local prod = {}
    assert(loadfile(root.."/PROD/"..base.."/__Distribution/FamilyGate.lua"))(base, prod)
    assert(ApogeeDistributionFamilyLease == lease and prod.__ApogeeFamilyAdmission == nil)
    ApogeeDistributionFamilyLease = {schema=1, family="DEV"}
    assert(not ns.__ApogeeFamilyAdmission(dev))
    scenarios = scenarios + 1
end
savedPrint("PASS family matrix: " .. scenarios .. " denied/admission scenarios; every actual denied runtime chunk had zero gameplay effects")
