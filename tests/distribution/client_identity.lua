-- Exercise actual generated client modules with the native Forever project ID.
-- API boundaries are mocked; this does not establish native gameplay acceptance.
local root, name = arg[1], arg[2]
local version, build, interface = "1.60.1", "70170", 16001
WOW_PROJECT_CAMELOT, WOW_PROJECT_ID = 18, 18
GetBuildInfo=function() return version,build,"",interface end
for _, key in ipairs({"CreateFrame","InCombatLockdown","SetOverrideBindingClick",
    "ClearOverrideBindings","RegisterStateDriver","UnregisterStateDriver","GetCursorInfo",
    "GetMacroInfo","GetNumMacros","SecureCmdOptionParse","ClearCursor","GetCVarBool",
    "GetNumShapeshiftForms","GetShapeshiftFormInfo","RegisterAttributeDriver",
    "UnregisterAttributeDriver","issecretvalue","canaccessvalue","canaccesstable",
    "UnitHealth","UnitHealthMax","UnitPower","UnitPowerMax","UnitPowerType","UnitExists",
    "UnitName","UnitIsConnected","UnitIsDeadOrGhost","GetMouseFoci"}) do
    _G[key]=function() return false end
end
Settings={RegisterCanvasLayoutCategory=function() end,RegisterAddOnCategory=function() end}
ChatFrameUtil={SendTellWithMessage=function() end,AddMessageEventFilter=function() end,
    RemoveMessageEventFilter=function() end}
C_ChatInfo={InChatMessagingLockdown=function() return false end}
C_Timer={After=function() end}; UIErrorsFrame={}
C_AddOns={IsAddOnLoaded=function() return false end}
C_SpellBook={GetNumSpellBookSkillLines=function() end,GetSpellBookSkillLineInfo=function() end,
    GetSpellBookItemInfo=function() end}
Enum={SpellBookSpellBank={},SpellBookItemType={}}
C_Spell={}; C_Item={}
for _,key in ipairs({"GetSpellInfo","GetSpellCooldown","GetSpellCharges","IsSpellUsable","IsSpellInRange"}) do
    C_Spell[key]=function() end
end
for _,key in ipairs({"GetItemInfo","GetItemCount","IsUsableItem"}) do C_Item[key]=function() end end
C_Container={GetItemCooldown=function() end}
TooltipDataProcessor=false
local function loadClient(admitted)
    local A={Message=function() end,__ApogeeFamilyAdmission=function(caller)
        assert(caller==name); return admitted
    end}
    local auction=name=="ApogeeAuctionDev"
    assert(loadfile(root.."/"..(auction and name..".lua" or "Core/Client.lua")))(name,A)
    if auction then return A.ready end
    if name=="ApogeeKeybindsDev" then return A.API and A.API.Check() end
    if name=="ApogeeHealsDev" then return A.CheckClient and A.CheckClient() end
    if name=="ApogeeTankDev" then return A.Client=="foreverBeta" end
    return A.Client and A.Client.Check()
end
assert(not loadClient(false),"Client checks must not bypass family admission")
for _,case in ipairs({{"1.60.1","70170",16001},{"1.60.0","69894",16000},
    {"1.60.2","99999",16002},{"1.61.0","100001",16100}}) do
    version,build,interface=unpack(case)
    assert(loadClient(true),"Generated native Forever revision was rejected: "..name)
end
WOW_PROJECT_ID=1; version="1.60.2"; interface=16002
assert(loadClient(true),"Legacy Forever interface revision was rejected")
WOW_PROJECT_ID=2; version="1.15.9"; interface=11509
assert(not loadClient(true),"Another client family was admitted")
WOW_PROJECT_ID=18; version="1.60.1"; interface=16001
if name=="ApogeeKeybindsDev" then RegisterAttributeDriver=nil
elseif name=="ApogeeHealsDev" then UnitHealth=nil
elseif name=="ApogeeGroupAlertDev" or name=="ApogeeEssentialsDev" then Settings=nil
elseif name=="ApogeeTankDev" then canaccessvalue=nil
else GetBuildInfo=nil end
assert(not loadClient(true),"Required capability guard was lost")
print("PASS generated "..name..": native identity, revisions, admission and missing API")
