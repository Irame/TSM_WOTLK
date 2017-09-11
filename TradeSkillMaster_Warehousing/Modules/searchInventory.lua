local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Warehousing") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local searchInventory = TSM:NewModule("searchInventory", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

function searchInventory:searchBags(grp)
    local t={}
    TSM.util:setSrcBagFunctions("bags")
    for bag=0,NUM_BAG_SLOTS  do 
        for slot = 1,TSM.util.getContainerNumSlotsSrc(bag) do
            local id   = TSM.util.getContainerItemIDSrc (bag,slot)
            local link = TSM.util.getContainerItemLinkSrc(bag,slot)
            if id and not searchInventory:exists(t,id) then
                table.insert(t,{item = id, itemlink = link, itemfamily = GetItemFamily(id)})
            end
        end
    end
    if grp then
        for id,v in pairs (grp.data) do
            --print(id,v)
            local _, link, _, _, _, _, _, _,_, _, _ = GetItemInfo(id)
            if id and not searchInventory:exists(t,id) then
                table.insert(t,{item = id, itemlink = link, itemfamily = GetItemFamily(id)})
            end
        end
    end
    return t
end

function searchInventory:searchBank()
    local t={}
    TSM.util:setSrcBagFunctions("bank")
    local bank = getBankSlotsTable()
    for _,bag in ipairs(bank)  do 
        for slot = 1,TSM.util.getContainerNumSlotsSrc(bag) do
            local id   = TSM.util.getContainerItemIDSrc (bag,slot)
            local link = TSM.util.getContainerItemLinkSrc(bag,slot)
            if id and not searchInventory:exists(t,id) then
                table.insert(t,{item = id, itemlink = link, itemfamily = GetItemFamily(id)})
            end
        end
    end
    return t
end

function searchInventory:exists(t,id)
    for i,v in ipairs(t) do
        if v.item == id then
            return true
        end
    end
    return
end

function getHashLen (t)
    local len = 0
    for _,v in pairs(t) do
        len = len + 1
    end
    return len
end

function printHash (t)
    for i,v in pairs(t) do
        print (i,"=")
        for i,v in pairs(v) do
            print ("    ",v.bag, v.slot)   
        end
    end
end