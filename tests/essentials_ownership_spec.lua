-- APHB validation remains independent of an Essentials checkout.
for _, outcome in ipairs({"absent","owned","failed","unsupported-version"}) do
    local calls={fade=0,errors=0,mentions=0,thanks=0}
    CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
    ApogeePartyHealthBars_CombatUIFader={ApplyEnabledState=function(v) if v then calls.fade=calls.fade+1 end end}
    ApogeePartyHealthBars_UIErrorSuppressor={ApplyEnabledState=function(v) if v then calls.errors=calls.errors+1 end end}
    ApogeePartyHealthBars_MentionAlerts={Register=function() calls.mentions=calls.mentions+1 end,IsEnabled=function() return true end}
    ApogeeEssentialsOwnership=nil
    if outcome~="absent" then ApogeeEssentialsOwnership={version=outcome=="unsupported-version" and 2 or 1,
        Resolve=function() return outcome=="owned" end} end
    dofile("Integrations/EssentialsOwnership.lua")
    local B=ApogeePartyHealthBars_EssentialsOwnership
    ApogeePartyHealthBars_CombatUIFader.ApplyEnabledState(true)
    ApogeePartyHealthBars_UIErrorSuppressor.ApplyEnabledState(true)
    ApogeePartyHealthBars_MentionAlerts.Register({})
    B.WhenLocal(function() calls.thanks=calls.thanks+1 end)
    for _,n in pairs(calls) do assert(n==0,"effect occurred before ownership decision") end
    assert(B.IsSuspended());B.Resolve();B.Resolve()
    for _,n in pairs(calls) do assert(n==(outcome=="owned" and 0 or 1),outcome) end
    assert(ApogeePartyHealthBars_MentionAlerts.IsEnabled()==(outcome~="owned"))
end
print("PASS Essentials ownership defer, success, failure, absent and protocol version")
