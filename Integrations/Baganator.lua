-- Optional Baganator view-lifecycle adapter. This module uses only Baganator's
-- public callback registry and never inspects or hooks item buttons.
local I = {}
ApogeePartyHealthBars.Define("Integrations", "Baganator", I)

local callback
local registeredRegistry
local callbackOwner = {}
local trackedFrames = {}
local monitor
local lastVisibility

local function PublishVisibility(active)
    active = active == true
    if lastVisibility == active then return false end
    lastVisibility = active
    if callback then callback(active) end
    return true
end

local function TrackFrame(frame)
    local frameType = type(frame)
    if (frameType ~= "table" and frameType ~= "userdata")
        or (type(frame.IsVisible) ~= "function"
            and type(frame.IsShown) ~= "function") then
        return false
    end
    trackedFrames[frame] = true
    return true
end

local function DiscoverFrames()
    local found = false
    for name, frame in pairs(_G) do
        if type(name) == "string"
            and (name:find("^Baganator_SingleViewBackpackViewFrame")
                or name:find("^Baganator_CategoryViewBackpackViewFrame"))
            and TrackFrame(frame) then
            found = true
        end
    end
    return found
end

local function ReadFrameVisibility()
    local hasFrame = false
    for frame in pairs(trackedFrames) do
        hasFrame = true
        local visibility = type(frame.IsVisible) == "function"
            and frame.IsVisible or frame.IsShown
        local ok, visible = pcall(visibility, frame)
        if ok and visible then return true, true end
    end
    return false, hasFrame
end

local function RefreshFrameVisibility()
    local active, hasFrame = ReadFrameVisibility()
    if not hasFrame then
        DiscoverFrames()
        active = ReadFrameVisibility()
    end
    PublishVisibility(active)
end

local function EnsureMonitor()
    if type(CreateFrame) ~= "function" then return false end
    if not monitor then
        monitor = CreateFrame("Frame")
        monitor.elapsed = 0
        monitor.discoveryElapsed = 0
        monitor:SetScript("OnUpdate", function(self, elapsed)
            self.elapsed = self.elapsed + elapsed
            self.discoveryElapsed = self.discoveryElapsed + elapsed
            if self.discoveryElapsed >= 1 then
                self.discoveryElapsed = 0
                DiscoverFrames()
            end
            if self.elapsed < 0.1 then return end
            self.elapsed = 0
            RefreshFrameVisibility()
        end)
    end
    DiscoverFrames()
    RefreshFrameVisibility()
    monitor:Show()
    return true
end

local function GetRegistry()
    local registry = _G.Baganator and _G.Baganator.CallbackRegistry
    if not registry or type(registry.RegisterCallback) ~= "function" then
        return nil
    end
    return registry
end

function I.EnsureRegistered(force)
    local registry = GetRegistry()
    if not registry then
        registeredRegistry = nil
        return false
    end
    if not force and registeredRegistry == registry then return true end

    -- A stable owner makes retries idempotent: CallbackRegistryMixin replaces
    -- this owner's prior callback for each event instead of accumulating
    -- handlers. Do not record success until both public callbacks attach.
    local ok = pcall(function()
        registry:RegisterCallback("BagShow", function()
            PublishVisibility(true)
        end, callbackOwner)
        registry:RegisterCallback("BagHide", function()
            PublishVisibility(false)
        end, callbackOwner)
        registry:RegisterCallback("BackpackFrameChanged", function(_, frame)
            TrackFrame(frame)
            RefreshFrameVisibility()
        end, callbackOwner)
        registry:RegisterCallback("FrameGroupSwapped", function()
            if C_Timer and C_Timer.After then
                C_Timer.After(0, function()
                    DiscoverFrames()
                    RefreshFrameVisibility()
                end)
            else
                DiscoverFrames()
                RefreshFrameVisibility()
            end
        end, callbackOwner)
    end)
    if not ok then
        registeredRegistry = nil
        return false
    end
    registeredRegistry = registry
    EnsureMonitor()
    return true
end

function I.Register(onVisibilityChanged)
    assert(type(onVisibilityChanged) == "function",
        "Baganator integration requires a visibility callback")
    callback = onVisibilityChanged
    return I.EnsureRegistered()
end

function I.OnAddonLoaded(addonName)
    if addonName ~= "Baganator" then return false end
    return I.EnsureRegistered(true)
end

function I.OnLifecycleEvent()
    return I.EnsureRegistered(true)
end

function I.IsRegistered()
    return registeredRegistry ~= nil and registeredRegistry == GetRegistry()
end
