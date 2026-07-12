dofile("ApogeePartyHealthBars_MacroData.lua")
dofile("ApogeePartyHealthBars_MacroLibrary.lua")

MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS = 120, 18
local macros, picked = {}, nil
function InCombatLockdown() return false end
function GetCursorInfo() return nil end
function GetNumMacros() return 0, #macros end
function GetMacroIndexByName(name)
    for index, macro in pairs(macros) do if macro.name == name then return index end end
    return 0
end
function GetMacroInfo(index)
    local macro = macros[index]
    if not macro then return nil end
    return macro.name, macro.icon, macro.body, macro.character
end
function CreateMacro(name, icon, body, character)
    local index = MAX_ACCOUNT_MACROS + 1
    macros[index] = { name = name, icon = icon, body = body, character = character }
    return index
end
function EditMacro(index, name, icon, body, character)
    macros[index] = { name = name, icon = icon, body = body, character = character }
    return index
end
function PickupMacro(index) picked = index end
function GetSpellTexture() return 135274 end

dofile("ApogeePartyHealthBars_MacroInstaller.lua")
local L, I = ApogeePartyHealthBars_MacroLibrary, ApogeePartyHealthBars_MacroInstaller
I.Initialize({})
local entry = L.Resolve("WARRIOR", 1, 10, function() return true end)

local ok, index = I.CreateOrUpdate(entry, false)
assert(ok and index == 121, "character macro was not created")
local name, icon, body, character = GetMacroInfo(index)
assert(character == true, "macro was not character-specific")
assert(type(icon) == "number" and icon ~= 134400, "macro did not receive an explicit spell icon")
assert(name ~= "" and #name <= 16 and body == entry.body, "macro presentation was invalid")
assert(I.PickupManagedMacro() and picked == index, "managed macro was not picked up")

macros[index].body = macros[index].body .. "\n/stopattack"
local replaced, reason = I.CreateOrUpdate(entry, false)
assert(not replaced and reason == "edited", "edited macro was overwritten without confirmation")
assert(I.CreateOrUpdate(entry, true), "confirmed edited macro was not replaced")
print("PASS macro installer")

