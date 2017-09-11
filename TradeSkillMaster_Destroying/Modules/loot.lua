-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Destroying") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local loot = TSM:NewModule("loot", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local mat = nil
local results = nil
local today = tostring(date("%m/%d/%y"))

loot.LootFrameIsVisible = false

local function printResults()
    TSM.Print("By date")
    for i,v in pairs(results.Day)do 
        for j,z in pairs (v) do print (i, j, z.num) end
    end
    TSM.Print("By Mat")
    for i,v in pairs(results.Mat)do 
        for j,z in pairs (v) do print (i, j, z.num) end 
    end
end

local lootEvent = CreateFrame("frame")
lootEvent:Hide()
local function OnHide()  lootEvent:UnregisterEvent("LOOT_OPENED")  end
local function OnShow()  lootEvent:RegisterEvent("LOOT_OPENED")   end

local function OnEvent() 
    
    local autoLoot = GetCVar("autoLootDefault")	
    --turn off autoloot--
    if autoLoot == 1 then SetCVar( "autoLootDefault", 0 ) end
    local tmpresults = {}
    for i=1, GetNumLootItems(), 1 do
        local _,name,quan,quality,_ = GetLootSlotInfo(i)
        LootSlot(i) 
        table.insert(tmpresults, {name = name, quality = quality, quan = quan})
    end	
    for i,v in ipairs(tmpresults) do
        if today then
            if not results.Day[today] then results.Day[today] = {} end
            if not results.Day[today][v.name] then results.Day[today][v.name] = {quality = v.quality, num = 0} end
            results.Day[today][v.name].num = results.Day[today][v.name].num + v.quan
        end 
        if mat then
            if not results.Mat[mat] then results.Mat[mat] = {} end
            if not results.Mat[mat][v.name] then results.Mat[mat][v.name] = {quality = v.quality, num = 0} end
            results.Mat[mat][v.name].num = results.Mat[mat][v.name].num + v.quan
        end
    end
    --turn on autoloot--
    if autoLoot == 1 then SetCVar( "autoLootDefault", 1 ) end
    local obj = TSM.GUI:getInfo()
    if obj.frame and obj.frame:IsVisible() then 
        if obj.action == "disenchanting" then
            TSM.stDE:updateTable(obj.frame, obj.action, obj.filter) 
        else
            TSM.stDestroying:updateTable(obj.frame, obj.action, obj.filter) 
        end
    end
        
    lootEvent:Hide()

end

lootEvent:SetScript("OnShow", OnShow)
lootEvent:SetScript("OnEvent", OnEvent)
lootEvent:SetScript("OnHide", OnHide)

function loot:setAction(action)
    if action == "Disenchanting" then results = TSM.db.factionrealm.DE return end
    if action == "Prospecting"   then results = TSM.db.factionrealm.Prospecting return end
    if action == "Milling"       then results = TSM.db.factionrealm.Milling return end
end
function loot:setMat(m) mat = m end
function loot:show() lootEvent:Show() end

