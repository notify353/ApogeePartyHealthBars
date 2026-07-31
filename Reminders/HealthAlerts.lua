-- Edge-triggered party health warnings. Health state is keyed by GUID so party
-- slot reordering cannot transfer an armed or low state to another character.
local C = ApogeePartyHealthBars_C
local S = ApogeePartyHealthBars_S
local UnitAPI = ApogeePartyHealthBars_UnitAPI
local Sounds = ApogeePartyHealthBars_Sounds

ApogeePartyHealthBars_HealthAlerts = {}
local H = ApogeePartyHealthBars_HealthAlerts

local trackedUnits = {}
local trackedUnitSet = {}
for _, unitId in ipairs(C.SLOT_UNITS) do
    trackedUnits[#trackedUnits + 1] = unitId
    trackedUnitSet[unitId] = true
end

local statesByGuid = {}
local lastSoundAt

local function NormalizeThreshold(value)
    local threshold = tonumber(value)
    if not threshold or threshold ~= threshold then
        threshold = C.LOW_HEALTH_DEFAULT_THRESHOLD
    end

    local step = C.LOW_HEALTH_THRESHOLD_STEP
    threshold = math.floor(threshold / step + 0.5) * step
    threshold = math.max(C.LOW_HEALTH_MIN_THRESHOLD, threshold)
    return math.min(C.LOW_HEALTH_MAX_THRESHOLD, threshold)
end

function H.GetThreshold()
    local savedThreshold = S.sv and S.sv.lowHealthThreshold
    local normalized = NormalizeThreshold(savedThreshold)
    if S.sv and savedThreshold ~= normalized then
        S.sv.lowHealthThreshold = normalized
    end
    return normalized
end

local function GetThresholdFractions()
    local triggerPercent = H.GetThreshold()
    local rearmPercent = math.min(100, triggerPercent + C.LOW_HEALTH_REARM_MARGIN)
    return triggerPercent / 100, rearmPercent / 100
end

local function ClearStates()
    for guid in pairs(statesByGuid) do statesByGuid[guid] = nil end
end

local function PartyExists()
    for index = 2, #trackedUnits do
        if UnitExists(trackedUnits[index]) then return true end
    end
    return false
end

local function GetHealthFraction(unitId)
    if not UnitExists(unitId) then return nil end
    if UnitIsConnected and not UnitIsConnected(unitId) then return nil end
    local health, maximum, validMaximum = UnitAPI.GetHealth(unitId)
    if not validMaximum then return nil end
    return health / maximum
end

local function PlayLowHealthSound()
    return Sounds.Play(H.GetSoundKey())
end

local function IsSoundEnabled()
    return S.sv and S.sv.enabled ~= false and H.GetSoundKey() ~= "none"
end

local function BaselineUnit(unitId)
    if not trackedUnitSet[unitId] then return end
    local guid = UnitGUID(unitId)
    local fraction = guid and GetHealthFraction(unitId)
    if not guid or fraction == nil then return end
    local triggerFraction = GetThresholdFractions()
    statesByGuid[guid] = { low = fraction < triggerFraction }
end

local function OnUnitConnection(unitId)
    if not trackedUnitSet[unitId] then return end
    local guid = UnitGUID(unitId)
    if guid then statesByGuid[guid] = nil end
    BaselineUnit(unitId)
end

function H.Rebaseline()
    ClearStates()
    if not PartyExists() then return end
    for _, unitId in ipairs(trackedUnits) do BaselineUnit(unitId) end
end

function H.SetThreshold(value)
    if not S.sv then return H.GetThreshold() end
    local current = H.GetThreshold()
    local threshold = NormalizeThreshold(value)
    S.sv.lowHealthThreshold = threshold
    if threshold ~= current then H.Rebaseline() end
    return threshold
end

function H.AdjustThreshold(direction)
    local numericDirection = tonumber(direction) or 0
    if numericDirection == 0 then return H.GetThreshold() end
    local delta = numericDirection < 0
        and -C.LOW_HEALTH_THRESHOLD_STEP
        or C.LOW_HEALTH_THRESHOLD_STEP
    return H.SetThreshold(H.GetThreshold() + delta)
end

function H.GetSoundKey()
    local savedKey = S.sv and S.sv.lowHealthSoundKey
    local normalized = Sounds.NormalizeKey(savedKey, C.LOW_HEALTH_DEFAULT_SOUND, true)
    if S.sv and savedKey ~= normalized then S.sv.lowHealthSoundKey = normalized end
    return normalized
end

function H.GetSoundLabel()
    return Sounds.GetLabel(H.GetSoundKey(), C.LOW_HEALTH_DEFAULT_SOUND, true)
end

function H.SetSoundKey(key)
    if not S.sv then return H.GetSoundKey() end
    S.sv.lowHealthSoundKey = Sounds.NormalizeKey(
        key, C.LOW_HEALTH_DEFAULT_SOUND, true)
    return S.sv.lowHealthSoundKey
end

function H.CycleSound(direction)
    return H.SetSoundKey(Sounds.CycleKey(
        H.GetSoundKey(), direction, true, C.LOW_HEALTH_DEFAULT_SOUND))
end

function H.PreviewSound()
    return Sounds.Play(H.GetSoundKey())
end

local function OnUnitHealth(unitId)
    if not trackedUnitSet[unitId] then return end
    if not PartyExists() then
        ClearStates()
        return
    end

    local guid = UnitGUID(unitId)
    local fraction = guid and GetHealthFraction(unitId)
    if not guid or fraction == nil then return end
    local triggerFraction, rearmFraction = GetThresholdFractions()

    local state = statesByGuid[guid]
    if not state then
        statesByGuid[guid] = { low = fraction < triggerFraction }
        return
    end

    if state.low then
        if fraction >= rearmFraction then state.low = false end
        return
    end
    if fraction >= triggerFraction then return end

    state.low = true
    if not IsSoundEnabled() then return end

    local now = GetTime and GetTime() or 0
    if lastSoundAt and now - lastSoundAt < C.LOW_HEALTH_SOUND_DEBOUNCE then return end
    if PlayLowHealthSound() then lastSoundAt = now end
end

function H.Register(eventRouter)
    assert(eventRouter and eventRouter.Subscribe and eventRouter.RegisterOptional,
        "health alerts require an event router")
    for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE" }) do
        eventRouter.Subscribe(event, "HealthAlerts", H.Rebaseline)
    end
    eventRouter.Subscribe("UNIT_HEALTH", "HealthAlerts", function(_, unitId) OnUnitHealth(unitId) end)
    eventRouter.Subscribe("UNIT_MAXHEALTH", "HealthAlerts", function(_, unitId) OnUnitHealth(unitId) end)
    eventRouter.RegisterOptional("UNIT_CONNECTION", "HealthAlerts", function(_, unitId)
        OnUnitConnection(unitId)
    end)
end
