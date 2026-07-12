ApogeePartyHealthBars_MacroInstaller = {}
local I = ApogeePartyHealthBars_MacroInstaller
local L = ApogeePartyHealthBars_MacroLibrary
local charSv

function I.Initialize(saved)
    charSv = saved
    charSv.managedMacro = charSv.managedMacro or {}
end

local function state()
    return charSv and charSv.managedMacro
end

local function findByName(name)
    if not name or not GetNumMacros or not GetMacroInfo then return nil end
    if GetMacroIndexByName then
        local index = GetMacroIndexByName(name)
        if index and index > 0 then return index end
    end
    local globalCount, charCount = GetNumMacros()
    for i = 1, (globalCount or 0) do
        local macroName = GetMacroInfo(i)
        if macroName == name then return i end
    end
    local firstCharacter = (MAX_ACCOUNT_MACROS or 120) + 1
    for i = firstCharacter, firstCharacter + (charCount or 0) - 1 do
        local macroName = GetMacroInfo(i)
        if macroName == name then return i end
    end
end

local function uniqueName(baseName)
    if not findByName(baseName) then return baseName end
    for n = 2, 99 do
        local suffix = " " .. n
        local candidate = baseName:sub(1, 16 - #suffix) .. suffix
        if not findByName(candidate) then return candidate end
    end
end

function I.GetManagedStatus()
    local s = state()
    if not s or not s.name then return "missing" end
    local index
    if s.index then
        local storedName = GetMacroInfo(s.index)
        if storedName == s.name then index = s.index end
    end
    index = index or findByName(s.name)
    if not index then return "missing" end
    local _, _, body, isCharacter = GetMacroInfo(index)
    if isCharacter == false then return "account", index end
    if body ~= s.body then
        if s.index and index ~= s.index then return "conflict", index end
        return "edited", index
    end
    return "managed", index
end

function I.Preflight(entry)
    if InCombatLockdown and InCombatLockdown() then return false, "Leave combat to create or update this macro." end
    if not CreateMacro or not EditMacro or not PickupMacro or not GetMacroInfo then
        return false, "Direct macro creation is unavailable; use Select Text instead."
    end
    local ok, err = L.ValidateEntry(entry)
    if not ok then return false, err end
    if GetCursorInfo and GetCursorInfo() then return false, "Clear the cursor before picking up this macro." end
    local status = I.GetManagedStatus()
    if status == "missing" or status == "conflict" or status == "account" then
        local globalCount, charCount = GetNumMacros()
        local maxCharacter = MAX_CHARACTER_MACROS or 18
        if (charCount or 0) >= maxCharacter then return false, "Character macro slots are full." end
    end
    return true
end

function I.CreateOrUpdate(entry, replaceEdited)
    local ok, err = I.Preflight(entry)
    if not ok then return false, err end
    local s = state()
    if not s then return false, "Character saved variables are not ready." end
    local status, index = I.GetManagedStatus()
    if status == "edited" and not replaceEdited then
        return false, "edited", "This managed macro was edited. Click Replace Edited Macro to overwrite it."
    end
    local desiredName = L.GetMacroName(entry)
    -- Library presentation rule: every managed macro receives an explicit
    -- spell icon, with a class-themed fallback when the spell is not learned.
    -- Never save a managed macro with the generic question-mark icon.
    local icon = L.GetIconForEntry(entry)
    local name = s.name
    if status == "missing" or status == "conflict" or status == "account" then
        name = uniqueName(desiredName)
        if not name then return false, "Could not find a free macro name." end
        index = CreateMacro(name, icon, entry.body, true)
    else
        local desiredIndex = findByName(desiredName)
        if not desiredIndex or desiredIndex == index then name = desiredName end
        index = EditMacro(index, name, icon, entry.body, true)
    end
    if not index then return false, "The game did not create or update the macro." end
    local actualName, _, actualBody, isCharacter = GetMacroInfo(index)
    if actualBody ~= entry.body then return false, "Macro verification failed after saving." end
    if isCharacter == false then return false, "The game created this macro in General scope instead of Character scope." end
    s.index, s.name, s.entryId, s.body = index, actualName, entry.id, entry.body
    return true, index
end

function I.PickupManagedMacro()
    local status, index = I.GetManagedStatus()
    if status ~= "managed" or not index then return false, "The managed macro could not be found." end
    if GetCursorInfo and GetCursorInfo() then return false, "Clear the cursor before picking up this macro." end
    PickupMacro(index)
    return true
end
