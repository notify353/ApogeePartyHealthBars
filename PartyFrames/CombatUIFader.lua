-- Fades selected Blizzard UI roots during combat while preserving their
-- original alpha and normal mouse interaction.
ApogeePartyHealthBars_CombatUIFader = {}

local F = ApogeePartyHealthBars_CombatUIFader

local FADE_DURATION = 0.20
local LEAVE_DELAY = 0.35
local HOVER_POLL_INTERVAL = 0.05

local FRAME_NAMES = {
    -- Action bars and their artwork.
    "MainMenuBar",
    "MainActionBar",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarLeft",
    "MultiBarRight",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7",
    "PetActionBar",
    "StanceBar",

    -- Unit frame, bags, minimap, micro menu, and status tracking.
    "PlayerFrame",
    "BagsBar",
    "MinimapCluster",
    "MicroMenu",
    "StatusTrackingBarManager",
}

local frames = {}
local frameSet = {}
local savedAlpha = {}
local transitionStarts = {}
local enabled = false
local combatActive = false
local targetVisible = false
local transitionActive = false
local transitionElapsed = 0
local hoverPollElapsed = 0
local hoveringTracked = false
local hoverRevealed = false
local leaveElapsed

local driver = CreateFrame("Frame")
driver:Hide()

local function AddFrame(frame)
    if not frame or frameSet[frame] then return end
    frames[#frames + 1] = frame
    frameSet[frame] = true
end

function F.ResolveFrames()
    wipe(frames)
    wipe(frameSet)

    for _, name in ipairs(FRAME_NAMES) do
        AddFrame(_G[name])
    end

    return frames
end

local function IsTrackedFocus(focus)
    local visited = {}
    while focus and not visited[focus] do
        if frameSet[focus] then return true end
        visited[focus] = true
        if type(focus.GetParent) ~= "function" then break end
        local ok, parent = pcall(focus.GetParent, focus)
        if not ok then break end
        focus = parent
    end
    return false
end

local function IsHoveringTrackedUI()
    if type(GetMouseFoci) ~= "function" then return false end
    local mouseFoci = GetMouseFoci()
    if type(mouseFoci) ~= "table" then return false end
    for _, focus in ipairs(mouseFoci) do
        if IsTrackedFocus(focus) then return true end
    end
    return false
end

local function StartTransition(show)
    if targetVisible == show and transitionActive then return end

    targetVisible = show
    transitionElapsed = 0
    transitionActive = true
    wipe(transitionStarts)
    for _, frame in ipairs(frames) do
        transitionStarts[frame] = frame:GetAlpha()
    end
end

local function UpdateTransition(elapsed)
    if not transitionActive then return end

    transitionElapsed = transitionElapsed + elapsed
    local progress = transitionElapsed + 0.0001 >= FADE_DURATION
        and 1 or transitionElapsed / FADE_DURATION
    for _, frame in ipairs(frames) do
        local startAlpha = transitionStarts[frame] or frame:GetAlpha()
        local endAlpha = targetVisible and (savedAlpha[frame] or 1) or 0
        frame:SetAlpha(startAlpha + (endAlpha - startAlpha) * progress)
    end

    if progress >= 1 then
        transitionActive = false
        if not targetVisible then hoverRevealed = false end
    end
end

local function UpdateHover(elapsed)
    hoverPollElapsed = hoverPollElapsed + elapsed
    if hoverPollElapsed >= HOVER_POLL_INTERVAL then
        hoverPollElapsed = 0
        hoveringTracked = IsHoveringTrackedUI()
    end

    if hoveringTracked then
        leaveElapsed = nil
        hoverRevealed = true
        if not targetVisible then StartTransition(true) end
    elseif hoverRevealed then
        leaveElapsed = (leaveElapsed or 0) + elapsed
        if leaveElapsed >= LEAVE_DELAY - 0.0001 then
            leaveElapsed = nil
            StartTransition(false)
        end
    end
end

driver:SetScript("OnUpdate", function(_, elapsed)
    UpdateHover(elapsed)
    UpdateTransition(elapsed)
end)

local function Restore()
    driver:Hide()
    combatActive = false
    targetVisible = false
    transitionActive = false
    transitionElapsed = 0
    hoverPollElapsed = 0
    hoveringTracked = false
    hoverRevealed = false
    leaveElapsed = nil

    for _, frame in ipairs(frames) do
        local alpha = savedAlpha[frame]
        if alpha ~= nil then frame:SetAlpha(alpha) end
    end
    wipe(savedAlpha)
    wipe(transitionStarts)
end

function F.OnCombatStart()
    if not enabled or combatActive then return end
    if #frames == 0 then F.ResolveFrames() end

    combatActive = true
    hoverPollElapsed = 0
    hoveringTracked = false
    hoverRevealed = false
    leaveElapsed = nil
    wipe(savedAlpha)
    for _, frame in ipairs(frames) do
        savedAlpha[frame] = frame:GetAlpha()
    end

    targetVisible = true
    StartTransition(false)
    driver:Show()
end

function F.OnCombatEnd()
    if combatActive then Restore() end
end

function F.ApplyEnabledState(shouldEnable)
    enabled = shouldEnable == true
    if not enabled then
        Restore()
    elseif UnitAffectingCombat and UnitAffectingCombat("player") then
        F.OnCombatStart()
    end
end

function F.Initialize(shouldEnable)
    F.ResolveFrames()
    F.ApplyEnabledState(shouldEnable)
end

function F.IsEnabled()
    return enabled
end
