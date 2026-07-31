local Factory = ApogeePartyHealthBars_BoundActionLayouts
local WD = ApogeePartyHealthBars_MouseWheelData

ApogeePartyHealthBars_MouseWheelLayouts = Factory.Create({
    stateKey = "mouseWheelActions",
    slots = WD.SLOTS,
    schemaVersion = 6,
    acceptedSchemaVersions = { [3] = true, [4] = true, [5] = true, [6] = true },
})
