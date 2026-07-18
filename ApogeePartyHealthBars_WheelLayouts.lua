local Factory = ApogeePartyHealthBars_BoundActionLayouts
local WD = ApogeePartyHealthBars_WheelData

ApogeePartyHealthBars_WheelLayouts = Factory.Create({
    stateKey = "wheelMacros",
    slots = WD.SLOTS,
    schemaVersion = 6,
    acceptedSchemaVersions = { [3] = true, [4] = true, [5] = true, [6] = true },
})
