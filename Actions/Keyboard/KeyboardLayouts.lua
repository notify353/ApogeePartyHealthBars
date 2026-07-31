local Factory = ApogeePartyHealthBars_BoundActionLayouts
local KD = ApogeePartyHealthBars_KeyboardData

ApogeePartyHealthBars_KeyboardLayouts = Factory.Create({
    stateKey = "keyboardActions",
    slots = KD.SLOTS,
    schemaVersion = 2,
    acceptedSchemaVersions = { [1] = true, [2] = true },
})
