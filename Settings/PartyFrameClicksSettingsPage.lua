local C = ApogeePartyHealthBars_C
local AC = ApogeePartyHealthBars_ActionSettingsComponents

ApogeePartyHealthBars_PartyFrameClicksSettingsPage = {}
local H = ApogeePartyHealthBars_PartyFrameClicksSettingsPage

local D, page, list
local slotRows = {}

local function setStatus(message, good)
    AC.SetActionListStatus(list, message, good)
end

function H.Refresh()
    if not page then return end
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

function H.Create(parent, deps)
    if page then return page end
    assert(type(deps) == "table", "PartyFrameClicksSettingsPage requires dependencies")
    for _, key in ipairs({
        "ClearBinding", "MoveBinding", "GetBinding", "GetBindingDisplay",
    }) do
        assert(deps[key] ~= nil, "PartyFrameClicksSettingsPage missing dependency: " .. key)
    end
    D = deps

    page = CreateFrame("Frame", nil, parent)
    page:SetPoint("TOPLEFT", parent, "TOPLEFT", C.BIND_PAD,
        -(C.CONFIG_HEADER_H + C.BIND_PAD + C.CONFIG_PAGE_SELECTOR_H + 4))
    page:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -C.BIND_PAD, C.BIND_PAD)
    page:Hide()

    list = AC.CreateActionList(page, "ApogeePartyHealthBarsPartyFrameClicksSettingsPageScroll")

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
                D.AssignCursorDrop("partyFrameClicks", slotKey)
            end
        end)
        row:SetScript("OnReceiveDrag", function()
            if D.AssignCursorDrop then D.AssignCursorDrop("partyFrameClicks", slotKey) end
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
    return page
end

H.GetRows = function() return slotRows end
H.GetHint = function() return list and list.hint end
H.GetList = function() return list end
H.GetFrame = function() return page end
