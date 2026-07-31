local C = ApogeePartyHealthBars_C

ApogeePartyHealthBars_AccessoryLayout = {}
local A = ApogeePartyHealthBars_AccessoryLayout

function A.GetIconSize()
    return C.ACCESSORY_ICON_SIZE
end

function A.GetStride()
    return C.ACCESSORY_ICON_SIZE + C.ACCESSORY_ICON_GAP
end

function A.GetHeight(count, columns)
    count = math.max(0, tonumber(count) or 0)
    if count == 0 then return 0 end
    columns = math.max(1, tonumber(columns) or count)
    local rows = math.ceil(count / columns)
    return rows * C.ACCESSORY_ICON_SIZE
        + math.max(0, rows - 1) * C.ACCESSORY_ICON_GAP
        + C.ACCESSORY_BOTTOM_GAP
end

function A.SetCompactSize(region)
    region:SetSize(C.ACCESSORY_ICON_SIZE, C.ACCESSORY_ICON_SIZE)
end

function A.InsetTexture(texture, inset)
    inset = tonumber(inset) or 0
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", inset, -inset)
    texture:SetPoint("BOTTOMRIGHT", -inset, inset)
end

function A.CreateBorder(parent, inset, size)
    inset = tonumber(inset) or 0
    size = tonumber(size) or 1
    local edges = {}
    local left = parent:CreateTexture(nil, "OVERLAY")
    left:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    left:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset)
    left:SetWidth(size)
    edges[#edges + 1] = left
    local right = parent:CreateTexture(nil, "OVERLAY")
    right:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    right:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    right:SetWidth(size)
    edges[#edges + 1] = right
    local top = parent:CreateTexture(nil, "OVERLAY")
    top:SetPoint("TOPLEFT", parent, "TOPLEFT", inset, -inset)
    top:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -inset, -inset)
    top:SetHeight(size)
    edges[#edges + 1] = top
    local bottom = parent:CreateTexture(nil, "OVERLAY")
    bottom:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", inset, inset)
    bottom:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -inset, inset)
    bottom:SetHeight(size)
    edges[#edges + 1] = bottom
    return edges
end

function A.Place(region, anchor, side, position, columns)
    assert(side == "left" or side == "right", "AccessoryLayout side must be left or right")
    position = math.max(1, tonumber(position) or 1) - 1
    columns = math.max(1, tonumber(columns) or position + 1)
    local column = position % columns
    local row = math.floor(position / columns)
    local stride = A.GetStride()
    if side == "right" then
        region:SetPoint(
            "BOTTOMRIGHT", anchor, "TOPRIGHT",
            -C.ACCESSORY_EDGE_INSET - column * stride,
            C.ACCESSORY_BOTTOM_GAP + row * stride)
    else
        region:SetPoint(
            "BOTTOMLEFT", anchor, "TOPLEFT",
            C.ACCESSORY_EDGE_INSET + column * stride,
            C.ACCESSORY_BOTTOM_GAP + row * stride)
    end
end
