-- Automatic gratitude prompts for lasting drive-by buffs and player cleanses.
local S = ApogeePartyHealthBars_S

ApogeePartyHealthBars_BuffThanks = {}
local Thanks = ApogeePartyHealthBars_BuffThanks

local MAX_ENTRIES = 3
local ENTRY_LIFETIME = 30
local PENDING_LIFETIME = 1
local MIN_DURATION = 30
local DEFAULT_POINT, DEFAULT_REL_POINT = "TOP", "TOP"
local DEFAULT_X, DEFAULT_Y = 0, -120
local FRAME_WIDTH, ROW_HEIGHT, ROW_GAP = 326, 24, 1
local ACTION_WIDTH, ACTION_HEIGHT, ACTION_GAP = 20, 20, 2
local GESTURES = {
    {
        token = "THANK",
        label = "Thank",
        texture = "Interface\\AddOns\\ApogeePartyHealthBars\\Media\\Textures\\ApogeePartyHealthBarsLogo.png",
    },
}
local DEFAULT_RAIL_R, DEFAULT_RAIL_G, DEFAULT_RAIL_B = 0.62, 0.48, 0.12

local D, frame
local rows = {}
local entries = {}
local pending = {}
local unlocked = false

local function saved() return S.sv or {} end
local function now() return D and D.Now and D.Now() or 0 end
local function isSupported()
    return not D or not D.ClientCapabilities
        or D.ClientCapabilities.IsFeatureAvailable("buffThanks")
end
local function isEnabled()
    return saved().enabled ~= false and saved().buffThanksEnabled == true and isSupported()
end

local function findEntry(guid)
    for index, entry in ipairs(entries) do
        if entry.guid == guid then return entry, index end
    end
    return nil, nil
end

local function getPlayerClassToken(guid)
    if type(guid) ~= "string" or not UnitClassFromGUID then return nil end
    local ok, _, classToken = pcall(UnitClassFromGUID, guid)
    return ok and type(classToken) == "string" and classToken ~= "" and classToken or nil
end

local function getClassColor(classToken)
    if classToken and C_ClassColor and C_ClassColor.GetClassColor then
        local ok, color = pcall(C_ClassColor.GetClassColor, classToken)
        if ok and color and color.r and color.g and color.b then
            return color.r, color.g, color.b
        end
    end
    local color = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    if color then return color.r, color.g, color.b end
    return DEFAULT_RAIL_R, DEFAULT_RAIL_G, DEFAULT_RAIL_B
end

local function reasonListText(entry)
    local names = {}
    for _, name in ipairs(entry.reasonNames or {}) do names[#names + 1] = name end
    return table.concat(names, ", ")
end

local function updateFrameHeight(count)
    if not frame then return end
    count = math.max(1, count or 1)
    frame:SetHeight(count * ROW_HEIGHT + math.max(0, count - 1) * ROW_GAP)
end

local function setButtonStyle(button, active)
    button.isActive = active == true
    if button.icon then button.icon:SetAlpha(active and 1 or 0.45) end
end

local function getPresentationEntries()
    if unlocked then
        return {
            {
                guid = "preview-priest",
                playerName = "Helpfulplayer",
                classToken = "PRIEST",
                reasonNames = { "Power Word: Fortitude" },
                isPreview = true,
            },
            {
                guid = "preview-druid",
                playerName = "Kinddruid",
                classToken = "DRUID",
                reasonNames = { "Cleansed: Crippling Poison" },
                isPreview = true,
            },
            {
                guid = "preview-mage",
                playerName = "Arcanehelper",
                classToken = "MAGE",
                reasonNames = { "Arcane Intellect" },
                isPreview = true,
            },
        }
    end
    return entries
end

local function render()
    if not frame then return end
    local presentation = getPresentationEntries()
    local visible = unlocked or (isEnabled() and #entries > 0)
    updateFrameHeight(#presentation)
    for index, row in ipairs(rows) do
        local entry = presentation[index]
        if entry then
            row.entryGuid = entry.guid
            local railR, railG, railB = getClassColor(entry.classToken)
            row.rail:SetColorTexture(railR, railG, railB, 0.95)
            row.summary:SetText((entry.playerName or "Unknown player")
                .. "  |cff77777f>  " .. reasonListText(entry) .. "|r")
            for _, button in ipairs(row.gestureButtons) do
                button.tooltip = "Thank " .. (entry.playerName or "the helpful player") .. "."
                if button.SetEnabled then
                    button:SetEnabled(not entry.isPreview)
                elseif entry.isPreview and button.Disable then
                    button:Disable()
                elseif button.Enable then
                    button:Enable()
                end
                setButtonStyle(button, not entry.isPreview)
            end
            row:Show()
        else
            row.entryGuid = nil
            row:Hide()
        end
    end
    frame:SetShown(visible)
end

local function removeEntryByGuid(guid)
    local _, index = findEntry(guid)
    if not index then return false end
    table.remove(entries, index)
    render()
    return true
end

function Thanks.AddOpportunity(guid, playerName, reasonKind, spellId, spellName, timestamp)
    if type(guid) ~= "string" or guid == ""
        or type(playerName) ~= "string" or playerName == ""
        or type(spellId) ~= "number"
        or type(spellName) ~= "string" or spellName == ""
        or (reasonKind ~= "buff" and reasonKind ~= "cleanse") then
        return false
    end
    timestamp = tonumber(timestamp) or now()
    local entry = findEntry(guid)
    if not entry then
        if #entries >= MAX_ENTRIES then table.remove(entries, 1) end
        entry = {
            guid = guid,
            playerName = playerName,
            reasonNames = {},
            reasonKeys = {},
            createdAt = timestamp,
        }
        entries[#entries + 1] = entry
    end
    entry.playerName = playerName
    entry.classToken = getPlayerClassToken(guid) or entry.classToken
    entry.expiresAt = timestamp + ENTRY_LIFETIME
    local key = reasonKind .. "\031" .. tostring(spellId or "") .. "\031" .. spellName
    if not entry.reasonKeys[key] then
        entry.reasonKeys[key] = true
        entry.reasonNames[#entry.reasonNames + 1] = reasonKind == "cleanse"
            and ("Cleansed: " .. spellName) or spellName
    end
    render()
    return true
end

local function auraQualifies(aura, spellId)
    if not aura or aura.spellId ~= spellId then return false end
    local duration = tonumber(aura.duration)
    return duration == nil or duration == 0 or duration >= MIN_DURATION
end

function Thanks.VerifyPending()
    if not D or not D.Auras then return 0 end
    local timestamp = now()
    for key, candidate in pairs(pending) do
        if candidate.expiresAt <= timestamp then pending[key] = nil end
    end
    local snapshot
    if not D.Auras.FindUnitHelpfulAuraBySpellId then
        if not D.Auras.ScanUnitHelpfulAuras then return 0 end
        snapshot = D.Auras.ScanUnitHelpfulAuras("player")
    end
    local verified = 0
    for key, candidate in pairs(pending) do
        local matched
        if D.Auras.FindUnitHelpfulAuraBySpellId then
            matched = auraQualifies(
                D.Auras.FindUnitHelpfulAuraBySpellId("player", candidate.spellId),
                candidate.spellId)
        else
            matched = false
            for _, aura in ipairs(snapshot.auras or {}) do
                if auraQualifies(aura, candidate.spellId) then
                    matched = true
                    break
                end
            end
        end
        if matched then
            Thanks.AddOpportunity(candidate.sourceGUID, candidate.sourceName,
                "buff", candidate.spellId, candidate.spellName, timestamp)
            pending[key] = nil
            verified = verified + 1
        end
    end
    return verified
end

local function matchesCombatLogFlag(flags, flag)
    if type(flags) ~= "number" or type(flag) ~= "number" then return false end
    if bit and bit.band then return bit.band(flags, flag) ~= 0 end
    if bit32 and bit32.band then return bit32.band(flags, flag) ~= 0 end
    if C_CombatLog and C_CombatLog.DoesObjectMatchFilter then
        local ok, matched = pcall(C_CombatLog.DoesObjectMatchFilter, flag, flags)
        if ok then return matched == true end
    end
    return false
end

local function isPlayerGuid(guid)
    if not guid then return false end
    if C_PlayerInfo and C_PlayerInfo.GUIDIsPlayer then
        local ok, isPlayer = pcall(C_PlayerInfo.GUIDIsPlayer, guid)
        return ok and isPlayer == true
    end
    if GUIDIsPlayer then
        local ok, isPlayer = pcall(GUIDIsPlayer, guid)
        return ok and isPlayer == true
    end
    return false
end

local function isOtherPlayer(sourceGUID, sourceFlags)
    if not sourceGUID or sourceGUID == (UnitGUID and UnitGUID("player")) then return false end
    if not isPlayerGuid(sourceGUID) then return false end
    local object = Enum and Enum.CombatLogObject or nil
    if not object or not matchesCombatLogFlag(sourceFlags, object.TypePlayer) then
        return false
    end
    return true
end

local function isOutsideGroupPlayer(sourceGUID, sourceFlags)
    if not isOtherPlayer(sourceGUID, sourceFlags) then return false end
    local object = Enum.CombatLogObject
    if matchesCombatLogFlag(sourceFlags, object.AffiliationMine)
        or matchesCombatLogFlag(sourceFlags, object.AffiliationParty)
        or matchesCombatLogFlag(sourceFlags, object.AffiliationRaid) then
        return false
    end
    return true
end

function Thanks.HandleCombatLogInfo(info)
    if not isEnabled() or type(info) ~= "table" then return false end
    local playerGUID = UnitGUID and UnitGUID("player")
    if not playerGUID or info[8] ~= playerGUID then return false end
    if info[2] == "SPELL_DISPEL" then
        if not isOtherPlayer(info[4], info[6]) or info[18] ~= "DEBUFF" then return false end
        local cleanseSpellId, cleanseSpellName = info[12], info[13]
        local removedSpellId, removedSpellName = info[15], info[16]
        if type(cleanseSpellId) ~= "number" or type(cleanseSpellName) ~= "string"
            or cleanseSpellName == "" or type(removedSpellId) ~= "number"
            or type(removedSpellName) ~= "string" or removedSpellName == "" then
            return false
        end
        return Thanks.AddOpportunity(info[4], info[5], "cleanse",
            removedSpellId, removedSpellName, now())
    end
    if info[2] ~= "SPELL_AURA_APPLIED" or info[15] ~= "BUFF" then return false end
    if not isOutsideGroupPlayer(info[4], info[6]) then return false end
    local spellId, spellName = info[12], info[13]
    if type(spellId) ~= "number" or type(spellName) ~= "string" or spellName == "" then
        return false
    end
    local key = tostring(info[4]) .. "\031" .. tostring(spellId)
    pending[key] = {
        sourceGUID = info[4], sourceName = info[5], sourceFlags = info[6],
        spellId = spellId, spellName = spellName, expiresAt = now() + PENDING_LIFETIME,
    }
    Thanks.VerifyPending()
    return true
end

function Thanks.OnCombatLog()
    if C_CombatLog and C_CombatLog.GetCurrentEventInfo then
        return Thanks.HandleCombatLogInfo({ C_CombatLog.GetCurrentEventInfo() })
    end
    if CombatLogGetCurrentEventInfo then
        return Thanks.HandleCombatLogInfo({ CombatLogGetCurrentEventInfo() })
    end
    return false
end

function Thanks.Expire(timestamp)
    timestamp = tonumber(timestamp) or now()
    for key, candidate in pairs(pending) do
        if candidate.expiresAt <= timestamp then pending[key] = nil end
    end
    local changed = false
    for index = #entries, 1, -1 do
        if entries[index].expiresAt <= timestamp then
            table.remove(entries, index)
            changed = true
        end
    end
    if changed then render() end
    return changed
end

function Thanks.PerformGesture(guid, token)
    local entry = findEntry(guid)
    local valid = false
    for _, gesture in ipairs(GESTURES) do
        if gesture.token == token then valid = true; break end
    end
    if not entry or not valid or not DoEmote then return false end
    local restricted = DoEmote(token, entry.playerName)
    if restricted then return false end
    removeEntryByGuid(guid)
    return true
end

function Thanks.Dismiss(guid) return removeEntryByGuid(guid) end

local function createRow(index)
    local row = CreateFrame("Frame", nil, frame)
    local top = (index - 1) * (ROW_HEIGHT + ROW_GAP)
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -top)
    row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -top)
    row:SetHeight(ROW_HEIGHT)
    local background = row:CreateTexture(nil, "BACKGROUND")
    background:SetAllPoints()
    background:SetColorTexture(0.025, 0.03, 0.04, 0.82)
    local rail = row:CreateTexture(nil, "ARTWORK")
    rail:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    rail:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    rail:SetWidth(3)
    rail:SetColorTexture(DEFAULT_RAIL_R, DEFAULT_RAIL_G, DEFAULT_RAIL_B, 0.95)
    local summary = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    summary:SetPoint("LEFT", row, "LEFT", 10, 0)
    summary:SetPoint("RIGHT", row, "RIGHT", -(ACTION_WIDTH + ACTION_GAP + 4), 0)
    summary:SetJustifyH("LEFT"); summary:SetWordWrap(false)
    row.gestureButtons = {}
    for _, gesture in ipairs(GESTURES) do
        local button = CreateFrame("Button", nil, row)
        button:SetSize(ACTION_WIDTH, ACTION_HEIGHT)
        button:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        button:RegisterForClicks("LeftButtonUp")
        local icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
        icon:SetTexture(gesture.texture)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        button.icon, button.token = icon, gesture.token
        button:SetScript("OnClick", function(self)
            Thanks.PerformGesture(row.entryGuid, self.token)
        end)
        button:SetScript("OnEnter", function(self)
            if self.isActive then self.icon:SetAlpha(1) end
            if not GameTooltip then return end
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(self.isActive and self.tooltip or "Preview only.",
                1, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            setButtonStyle(self, self.isActive)
            if GameTooltip then GameTooltip:Hide() end
        end)
        row.gestureButtons[#row.gestureButtons + 1] = button
    end
    row.background, row.rail, row.summary = background, rail, summary
    rows[index] = row
end

function Thanks.Build()
    if frame then return Thanks end
    frame = CreateFrame("Frame", "ApogeePartyHealthBarsBuffThanks", UIParent)
    frame:SetSize(FRAME_WIDTH, ROW_HEIGHT)
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    D.SettingsSurfaces.Register("buffThanks", frame, { automaticChrome = false })
    for index = 1, MAX_ENTRIES do createRow(index) end
    frame:SetScript("OnDragStart", function(self)
        if unlocked and not (InCombatLockdown and InCombatLockdown()) then
            self:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint(1)
        Thanks.SetPosition(point, relativePoint, x, y)
    end)
    frame:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed >= 0.2 then self.elapsed = 0; Thanks.Expire() end
    end)
    Thanks.RestorePosition()
    render()
    return Thanks
end

function Thanks.Initialize(deps)
    D = assert(deps, "BuffThanks requires dependencies")
    for _, key in ipairs({ "Auras", "ClientCapabilities", "SettingsSurfaces", "Now" }) do
        assert(D[key] ~= nil, "BuffThanks missing dependency: " .. key)
    end
end

function Thanks.SetUnlocked(value)
    unlocked = value == true
    if frame then
        frame:EnableMouse(unlocked)
        if unlocked then frame:RegisterForDrag("LeftButton") else frame:RegisterForDrag() end
    end
    D.SettingsSurfaces.SetSurfaceChromeShown("buffThanks", false)
    render()
    return true
end

function Thanks.SetPosition(point, relativePoint, x, y)
    if not S.sv then return end
    S.sv.buffThanksPoint = point or DEFAULT_POINT
    S.sv.buffThanksRelPoint = relativePoint or point or DEFAULT_REL_POINT
    S.sv.buffThanksX = tonumber(x) or DEFAULT_X
    S.sv.buffThanksY = tonumber(y) or DEFAULT_Y
end

function Thanks.RestorePosition()
    if not frame then return false end
    local values = saved()
    frame:ClearAllPoints()
    frame:SetPoint(values.buffThanksPoint or DEFAULT_POINT, UIParent,
        values.buffThanksRelPoint or DEFAULT_REL_POINT,
        tonumber(values.buffThanksX) or DEFAULT_X, tonumber(values.buffThanksY) or DEFAULT_Y)
    return true
end

function Thanks.ResetPosition()
    if not frame then return false end
    frame:ClearAllPoints()
    frame:SetPoint(DEFAULT_POINT, UIParent, DEFAULT_REL_POINT, DEFAULT_X, DEFAULT_Y)
    Thanks.SetPosition(DEFAULT_POINT, DEFAULT_REL_POINT, DEFAULT_X, DEFAULT_Y)
    render()
    return true
end

function Thanks.Refresh()
    Thanks.Expire()
    render()
end
function Thanks.Hide() if frame then frame:Hide() end end
function Thanks.GetFrame() return frame end
function Thanks.GetRows() return rows end
function Thanks.GetEntries() return entries end
function Thanks.GetPending() return pending end
function Thanks.IsEnabled() return isEnabled() end
function Thanks.IsUnlocked() return unlocked end
function Thanks.IsSupported() return isSupported() end
function Thanks.GetUnavailableReason()
    return isSupported() and nil or D.ClientCapabilities.GetFeatureReason("buffThanks")
end
function Thanks.ResetSession()
    entries, pending = {}, {}
    render()
end
Thanks.GESTURES = GESTURES
Thanks.MAX_ENTRIES = MAX_ENTRIES
Thanks.ENTRY_LIFETIME = ENTRY_LIFETIME
Thanks.MIN_DURATION = MIN_DURATION
