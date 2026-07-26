dofile("ApogeePartyHealthBars_Data.lua")

assert(ApogeePartyHealthBars_C.SECURE_OVERLAY_STRATA == "LOW",
    "secure input overlays must remain below standard Blizzard panels")

local overlaySources = {
    "ApogeePartyHealthBars_UnitBar.lua",
    "ApogeePartyHealthBars_ShortcutBar.lua",
    "ApogeePartyHealthBars_ConsumableBar.lua",
    "ApogeePartyHealthBars_BoundActionRuntime.lua",
    "ApogeePartyHealthBars_PlayerUtility.lua",
}

for _, path in ipairs(overlaySources) do
    local handle = assert(io.open(path, "r"))
    local source = handle:read("*a")
    handle:close()
    assert(source:find("SetFrameStrata%(C%.SECURE_OVERLAY_STRATA%)"),
        path .. " did not use the shared secure overlay strata")
    assert(not source:find('SetFrameStrata%("TOOLTIP"%)'),
        path .. " raised an input overlay above Blizzard panels")
end

print("PASS secure overlay layering")
