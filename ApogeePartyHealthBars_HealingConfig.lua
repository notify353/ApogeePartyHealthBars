local C = ApogeePartyHealthBars_C
local AC = ApogeePartyHealthBars_ActionConfig

ApogeePartyHealthBars_HealingConfig = {}
local H = ApogeePartyHealthBars_HealingConfig

local D, tab, list
local slotRows = {}

local function setStatus(message, good)
    AC.SetActionListStatus(list, message, good)
end

function H.Refresh()
    if not tab then return end
    local rows = {}
    for index, slot in ipairs(C.BINDING_SLOTS) do
        local row = slotRows[index]
        local binding = D.GetBinding(slot.key)
        local name, icon, available, kind = D.GetBindingDisplay(binding)
        local active = kind ~= nil
        local kindLabel = active and (kind == "item" and "Item" or "Spell") or "Empty"
        AC.SetActionRowState(row, {
            active = active,
            available = available,
            icon = icon,
            name = name or (active and "Unknown Action" or "Empty"),
            detail = slot.label .. " — " .. kindLabel,
            canMoveUp = active and index > 1,
            canMoveDown = active and index < #C.BINDING_SLOTS,
        })
        rows[#rows + 1] = row
    end
    AC.LayoutActionList(list, rows)
end

function H.Build(parent, deps)
    if tab then return tab end
    assert(type(deps) == "table", "HealingConfig requires dependencies")
    for _, key in ipairs({
        "ClearBinding", "MoveBinding", "GetBinding", "GetBindingDisplay",
    }) do
        assert(deps[key] ~= nil, "HealingConfig missing dependency: " .. key)
    end
    D = deps

    tab = CreateFrame("Frame", nil, parent)
    tab:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_TAB_H + 4))
    tab:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    tab:Hide()

    list = AC.CreateActionList(tab, "ApogeePartyHealthBarsHealingConfigScroll")

    for index, slot in ipairs(C.BINDING_SLOTS) do
        local slotKey, slotLabel = slot.key, slot.label
        local row = AC.CreateActionRow(list.content, list.rowWidth, {
            showSound = false,
            showMacro = false,
        })
        row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        row:SetScript("OnClick", function(_, mouseButton)
            if mouseButton == "RightButton" then
                local ok, message = D.ClearBinding(slotKey)
                setStatus(message or (slotLabel .. " cleared."), ok)
                H.Refresh()
                return
            end
            local cursorType = GetCursorInfo and GetCursorInfo()
            if (cursorType == "spell" or cursorType == "item") and D.AssignCursorDrop then
                D.AssignCursorDrop("healing", slotKey)
            end
        end)
        row:SetScript("OnReceiveDrag", function()
            if D.AssignCursorDrop then D.AssignCursorDrop("healing", slotKey) end
        end)
        row.up:SetScript("OnClick", function()
            local moved, message = D.MoveBinding(slotKey, -1)
            setStatus(message, moved)
            H.Refresh()
        end)
        row.down:SetScript("OnClick", function()
            local moved, message = D.MoveBinding(slotKey, 1)
            setStatus(message, moved)
            H.Refresh()
        end)
        row.clear:SetScript("OnClick", function()
            local ok, message = D.ClearBinding(slotKey)
            setStatus(message or (slotLabel .. " cleared."), ok)
            H.Refresh()
        end)
        row.slotKey = slotKey
        slotRows[index] = row
    end

    H.Refresh()
    return tab
end

H.GetRows = function() return slotRows end
H.GetHint = function() return list and list.hint end
H.GetList = function() return list end
H.GetTab = function() return tab end
