dofile("ApogeePartyHealthBars_Data.lua")
dofile("ApogeePartyHealthBars_AccessoryLayout.lua")

local layout = ApogeePartyHealthBars_AccessoryLayout
local function region()
    local value = {
        SetSize = function(self, width, height) self.width, self.height = width, height end,
        SetWidth = function(self, width) self.width = width end,
        SetHeight = function(self, height) self.height = height end,
        ClearAllPoints = function(self) self.points = {} end,
        SetPoint = function(self, ...) self.points = self.points or {}; self.points[#self.points + 1] = { ... } end,
    }
    function value:CreateTexture() return region() end
    return value
end

assert(layout.GetHeight(0, 6) == 0
        and layout.GetHeight(1, 6) == ApogeePartyHealthBars_C.ACCESSORY_ICON_SIZE
            + ApogeePartyHealthBars_C.ACCESSORY_BOTTOM_GAP
        and layout.GetHeight(7, 6) == ApogeePartyHealthBars_C.ACCESSORY_ICON_SIZE * 2
            + ApogeePartyHealthBars_C.ACCESSORY_ICON_GAP
            + ApogeePartyHealthBars_C.ACCESSORY_BOTTOM_GAP,
    "compact accessory height did not match its row geometry")

local anchor = region()
local left = region()
layout.SetCompactSize(left)
layout.Place(left, anchor, "left", 7, 6)
assert(left.width == ApogeePartyHealthBars_C.ACCESSORY_ICON_SIZE
        and left.points[1][1] == "BOTTOMLEFT"
        and left.points[1][2] == anchor
        and left.points[1][4] == ApogeePartyHealthBars_C.ACCESSORY_EDGE_INSET
        and left.points[1][5] == ApogeePartyHealthBars_C.ACCESSORY_BOTTOM_GAP
            + layout.GetStride(),
    "left accessory grid did not grow rightward and upward")

local right = region()
layout.Place(right, anchor, "right", 2, 3)
assert(right.points[1][1] == "BOTTOMRIGHT"
        and right.points[1][4] == -ApogeePartyHealthBars_C.ACCESSORY_EDGE_INSET
            - layout.GetStride()
        and right.points[1][5] == ApogeePartyHealthBars_C.ACCESSORY_BOTTOM_GAP,
    "right accessory grid did not grow leftward")

local texture = region()
layout.InsetTexture(texture, 1)
assert(texture.points[1][1] == "TOPLEFT" and texture.points[1][2] == 1
        and texture.points[2][1] == "BOTTOMRIGHT" and texture.points[2][2] == -1,
    "compact texture inset was inconsistent")

local border = layout.CreateBorder(anchor, 0, 1)
assert(#border == 4 and border[1].width == 1 and border[3].height == 1,
    "shared compact border did not create four one-pixel edges")

print("PASS shared accessory layout")
