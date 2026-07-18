local Factory = ApogeePartyHealthBars_BoundActionLayouts
local KD = ApogeePartyHealthBars_KeyData

ApogeePartyHealthBars_KeyLayouts = Factory.Create({
    stateKey = "keyActions",
    slots = KD.SLOTS,
    schemaVersion = 2,
    acceptedSchemaVersions = { [1] = true, [2] = true },
    newLayoutsStartEmpty = true,
})
