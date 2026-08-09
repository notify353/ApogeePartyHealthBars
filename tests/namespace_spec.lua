dofile("Core/Namespace.lua")

local Addon = ApogeePartyHealthBars
local sample = {}
assert(Addon.Define("Actions", "Sample", sample, "ApogeePartyHealthBars_Sample") == sample)
assert(Addon.Require("Actions", "Sample") == sample,
    "registered module was not returned by Require")
assert(ApogeePartyHealthBars_Sample == sample,
    "legacy compatibility alias did not preserve module identity")

local duplicate = pcall(Addon.Define, "Actions", "Sample", {})
assert(not duplicate, "duplicate module registration was accepted")
local missing = pcall(Addon.Require, "Actions", "Missing")
assert(not missing, "missing module requirement was accepted")
local domain = pcall(Addon.Define, "Missing", "Sample", {})
assert(not domain, "unknown namespace domain was accepted")

print("PASS guarded module namespace")
