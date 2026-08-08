local Sources = ApogeePartyHealthBars.Require("Actions", "ActionAssignmentSources")
local Baganator = ApogeePartyHealthBars.Require("Integrations", "Baganator")

local E = {}
ApogeePartyHealthBars.Define(
    "Runtime", "ActionAssignmentEvents", E,
    "ApogeePartyHealthBars_ActionAssignmentEvents")

function E.Register(eventRouter, deps)
    assert(type(eventRouter) == "table", "ActionAssignmentEvents requires an event router")
    assert(type(deps) == "table"
        and type(deps.RefreshAssignmentAffordances) == "function",
        "ActionAssignmentEvents requires RefreshAssignmentAffordances")

    local function Refresh(changed)
        if changed and (not InCombatLockdown or not InCombatLockdown()) then
            deps.RefreshAssignmentAffordances()
        end
    end

    local spellbook = _G.SpellBookFrame
    if spellbook and spellbook.HookScript then
        spellbook:HookScript("OnShow", function()
            Refresh(Sources.SetSpellbookOpen(true))
        end)
        spellbook:HookScript("OnHide", function()
            Refresh(Sources.SetSpellbookOpen(false))
        end)
        Refresh(Sources.SetSpellbookOpen(spellbook:IsShown()))
    end

    -- Classic's stock ToggleBag path shows reusable ContainerFrames directly.
    for index = 1, tonumber(NUM_CONTAINER_FRAMES) or 13 do
        local container = _G["ContainerFrame" .. index]
        if container and container.HookScript then
            container:HookScript("OnShow", function(self)
                Refresh(Sources.SetPlayerBagOpen(self:GetID(), true))
            end)
            container:HookScript("OnHide", function(self)
                Refresh(Sources.SetPlayerBagOpen(self:GetID(), false))
            end)
            if container.IsShown and container:IsShown() then
                Sources.SetPlayerBagOpen(container:GetID(), true)
            end
        end
    end

    eventRouter.Subscribe("BAG_OPEN", "ActionAssignmentSources", function(_, bagId)
        Refresh(Sources.SetPlayerBagOpen(bagId, true))
    end)
    eventRouter.Subscribe("BAG_CLOSED", "ActionAssignmentSources", function(_, bagId)
        Refresh(Sources.SetPlayerBagOpen(bagId, false))
    end)
    eventRouter.RegisterOptional("CURSOR_CHANGED", "ActionAssignmentSources", function()
        Refresh(true)
    end)

    Baganator.Register(function(active)
        Refresh(Sources.SetExternalPlayerBagsOpen(active))
    end)
    eventRouter.Subscribe("ADDON_LOADED", "ActionAssignmentSources", function(_, addonName)
        Baganator.OnAddonLoaded(addonName)
    end)
end

