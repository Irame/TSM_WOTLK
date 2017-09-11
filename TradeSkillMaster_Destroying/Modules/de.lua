-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Destroying") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local de = TSM:NewModule("de", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

de.dObj = {
    bag = 0,
    slot = 1,
    Item = nil,
}

local qualityColors = {
	[0]="9d9d9d",
	[1]="ffffff",
	[2]="1eff00",
	[3]="0070dd",
	[4]="a335ee",
	[5]="ff8000",
	[6]="e6cc80",
}

local function canDE(id)
    _,_,q = GetItemInfo(id)
   
    if id and IsEquippableItem(id) and ( q>= 2 and q <= 4 ) and not TSM.db.global.safeList[id] then
        return true
    end
    return false
end

local bagsNum = 4
function de:searchAndDestroy(pre) 
    for bag = de.dObj.bag, bagsNum do --bags		
        for slot = de.dObj.slot, GetContainerNumSlots(bag) do
            local id = GetContainerItemID(bag, slot)
            if  pre == nil or (bag ~= pre.bag or slot ~= pre.slot) then 
                if id and canDE(id) then 
                    local itemString = string.match(GetContainerItemLink(bag, slot), "item[%-?%d:]+")
                    if not TSM.db.factionrealm.SafeTable [itemString] then
                        de.dObj.bag  = bag
                        de.dObj.slot = slot
                        return {bag = bag, slot = slot}
                    end
                end
            end
        end--end slots
    end--end bags
    
    de.dObj.bag  = 0
    de.dObj.slot = 1
end 

function de:getDestroyTable ()
     local gearTable = {}
     for bag = 0, bagsNum do --bags		
        for slot = 1, GetContainerNumSlots(bag) do
             local id = GetContainerItemID(bag, slot)
             if id and canDE(id) then
                local itemString = string.match(GetContainerItemLink(bag, slot), "item[%-?%d:]+")
                local name,_,quality = GetItemInfo(id)
                if not TSM.db.factionrealm.SafeTable [itemString] then 
                    table.insert(gearTable, 
                        {
                            cols = {
                                {
                                    value = function(itemString, quality ) if itemString then return "|cff"..qualityColors[quality]..GetItemInfo(itemString).."|r" end end,
                                    args = {itemString, quality},
                                },
                            },
                            itemString = itemString
                        }
                    )
                end
             end
        end
     end
    return gearTable
end

function de:getSafeTable()
    local safeTable = {}
    for itemString,_ in pairs(TSM.db.factionrealm.SafeTable) do
        if itemString then
             table.insert(safeTable, 
                    {
                        cols = {
                                {
                                    value = function(itemString, quality ) 
                                        if itemString then 
                                            local _,_,quality = GetItemInfo(itemString)
                                            return "|cff"..qualityColors[quality]..GetItemInfo(itemString).."|r" 
                                        end 
                                    end,
                                    args = {itemString, quality},
                                },
                            },
                            itemString = itemString
                    }
                )
        end
    end
    return safeTable
end