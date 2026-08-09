dofile("Core/Data.lua")

assert(ApogeePartyHealthBars_C.SECURE_OVERLAY_STRATA == "LOW",
    "secure input overlays must remain below standard Blizzard panels")

local overlaySources = {
    "PartyFrames/UnitBar.lua",
    "Actions/ShortcutBar.lua",
    "Actions/ConsumableBar.lua",
    "Actions/BoundActionSecureController.lua",
    "PartyFrames/PlayerUtility.lua",
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
