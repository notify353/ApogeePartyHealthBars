-- Coalesces layout/value refresh requests without owning UI domain behavior.
local UpdateScheduler = {}
ApogeePartyHealthBars.Define("Core", "UpdateScheduler", UpdateScheduler)

function UpdateScheduler.Create(deps)
    for _, key in ipairs({ "State", "Constants", "Print" }) do
        assert(deps and deps[key], "UpdateScheduler missing dependency: " .. key)
    end

    local state = deps.State
    local constants = deps.Constants
    local printMessage = deps.Print
    local fullUpdate, valuesUpdate, isEnabled
    local throttleFrame = CreateFrame("Frame")
    local valuesFlushFrame = CreateFrame("Frame")
    throttleFrame:Hide()
    valuesFlushFrame:Hide()

    local Scheduler = {}

    local function requireHandlers()
        assert(fullUpdate and valuesUpdate and isEnabled,
            "UpdateScheduler handlers are not registered")
    end

    local function runFullUpdate()
        requireHandlers()
        local ok, err = pcall(fullUpdate)
        if not ok then printMessage("update error: " .. tostring(err)) end
        return ok
    end

    local function runValuesUpdate()
        requireHandlers()
        if not isEnabled() then
            state.valuesDirty = false
            state.valuesDirtyUnits = nil
            return true
        end
        local ok, err = pcall(valuesUpdate)
        if not ok then
            printMessage("values update error: " .. tostring(err))
            return false
        end
        state.valuesDirty = false
        state.valuesDirtyUnits = nil
        return true
    end

    local function cancelValuesFlush()
        valuesFlushFrame:Hide()
    end

    function Scheduler.RegisterHandlers(handlers)
        assert(type(handlers) == "table", "UpdateScheduler requires handlers")
        assert(type(handlers.FullUpdate) == "function",
            "UpdateScheduler requires FullUpdate handler")
        assert(type(handlers.ValuesUpdate) == "function",
            "UpdateScheduler requires ValuesUpdate handler")
        assert(type(handlers.IsEnabled) == "function",
            "UpdateScheduler requires IsEnabled handler")
        fullUpdate = handlers.FullUpdate
        valuesUpdate = handlers.ValuesUpdate
        isEnabled = handlers.IsEnabled
    end

    function Scheduler.RequestUpdate()
        cancelValuesFlush()
        state.layoutDirty = true
        state.valuesDirty = true
        state.valuesDirtyUnits = nil
        throttleFrame:Show()
    end

    Scheduler.RequestLayoutUpdate = Scheduler.RequestUpdate

    function Scheduler.RequestValuesUpdate(unitId)
        state.valuesDirty = true
        if unitId then
            state.valuesDirtyUnits = state.valuesDirtyUnits or {}
            state.valuesDirtyUnits[unitId] = true
        else
            state.valuesDirtyUnits = nil
        end
        if state.layoutDirty then
            cancelValuesFlush()
            throttleFrame:Show()
        else
            valuesFlushFrame:Show()
        end
    end

    function Scheduler.Clear()
        state.layoutDirty = false
        state.valuesDirty = false
        state.valuesDirtyUnits = nil
    end

    function Scheduler.ForceRefresh()
        cancelValuesFlush()
        state.layoutDirty = true
        state.valuesDirty = true
        state.valuesDirtyUnits = nil
        if runFullUpdate() then
            Scheduler.Clear()
            throttleFrame:Hide()
        end
    end

    function Scheduler.Stop()
        throttleFrame:Hide()
        valuesFlushFrame:Hide()
    end

    valuesFlushFrame:SetScript("OnUpdate", function(self)
        self:Hide()
        if not state.valuesDirty or state.layoutDirty then return end
        runValuesUpdate()
    end)

    throttleFrame:SetScript("OnUpdate", function(_, elapsed)
        if not state.layoutDirty and not state.valuesDirty then return end
        state.uiTimer = state.uiTimer - elapsed
        if state.uiTimer <= 0 then
            state.uiTimer = constants.UPDATE_RATE
            if runFullUpdate() then
                Scheduler.Clear()
                if not state.layoutDirty and not state.valuesDirty then
                    throttleFrame:Hide()
                end
            end
        end
    end)

    return Scheduler
end

