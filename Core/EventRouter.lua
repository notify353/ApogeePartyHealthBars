-- Single-frame event routing with optional-event support and per-owner isolation.
ApogeePartyHealthBars_EventRouter = {}
local R = ApogeePartyHealthBars_EventRouter

local frame = CreateFrame("Frame")
local subscribers = {}
local printer

local function eventIsValid(event)
    if C_EventUtils and C_EventUtils.IsEventValid then
        return C_EventUtils.IsEventValid(event)
    end
    return true
end

function R.Initialize(printFn)
    printer = printFn
end

function R.Subscribe(event, owner, callback, optional)
    assert(type(event) == "string" and type(callback) == "function", "invalid event subscription")
    if optional and not eventIsValid(event) then return false end
    if not subscribers[event] then
        subscribers[event] = {}
        local ok = pcall(frame.RegisterEvent, frame, event)
        if not ok then
            subscribers[event] = nil
            if optional then return false end
            error("could not register required event: " .. event)
        end
    end
    subscribers[event][#subscribers[event] + 1] = { owner = owner or "anonymous", callback = callback }
    return true
end

function R.RegisterOptional(event, owner, callback)
    return R.Subscribe(event, owner, callback, true)
end

function R.Dispatch(event, ...)
    for _, subscriber in ipairs(subscribers[event] or {}) do
        local ok, err = pcall(subscriber.callback, event, ...)
        if not ok and printer then
            printer("event error [" .. subscriber.owner .. "/" .. event .. "]: " .. tostring(err))
        end
    end
end

function R.GetFrame()
    return frame
end

frame:SetScript("OnEvent", function(_, event, ...)
    R.Dispatch(event, ...)
end)

