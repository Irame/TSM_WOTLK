-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Warehousing") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local data = TSM:NewModule("data", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI librarie

--get src data
function data:ScanSrc(container)
    local results = {}
    for i,bagid in ipairs(container) do
        for slotid=1, TSM.util.getContainerNumSlotsSrc(bagid) do
            local id,quan = TSM.util.getContainerItemIDSrc(bagid,slotid)
            if id then 
                if not results[id] then results[id] =  {} end
                table.insert(results[id],{bag = bagid, slot = slotid, quantity = quan})
            end
        end
    end
    return results
end

--get src data
--also updates 
--craftstate
function data:ScanSrcForCrafting(container, craftGroup, data)
    local results = {}
    if craftGroup and not TSM.db.factionrealm.CraftingGroups[craftGroup] then 
        TSM.db.factionrealm.CraftingGroups[craftGroup] = {} 
    end
    
    for i,bagid in ipairs(container) do
        for slotid=1, TSM.util.getContainerNumSlotsSrc(bagid) do
            local id,quan = TSM.util.getContainerItemIDSrc(bagid,slotid)
            if id then 
                if not results[id] then results[id] =  {} end
                table.insert(results[id],{bag = bagid, slot = slotid, quantity = quan})
    
                if craftGroup and data[id] then
                    if TSM.db.factionrealm.CraftingGroups[craftGroup][id] then
                        local total = TSM.db.factionrealm.CraftingGroups[craftGroup][id] + quan
                        if total < data[id] then
                            TSM.db.factionrealm.CraftingGroups[craftGroup][id] = total
                        elseif total >= data[id] then
                            TSM.db.factionrealm.CraftingGroups[craftGroup][id] = data[id]
                        end
                    else
                        TSM.db.factionrealm.CraftingGroups[craftGroup][id] = quan
                    end
                end
                                   
            end
     
        end
    end
    
    for i,v in ipairs(TSM.db.factionrealm.CraftingGroups[craftGroup]) do
        print (i,v)
    end
    
    return results
end

----------------------------------
-- Generates the Bagstate table --
----------------------------------
function data:getEmptyRestoreGroup(container,isGuildBank)
    local tmp = {}
    local grp = {}
    
    for i,bagid in ipairs(container) do 
        for slotid=1, TSM.util.getContainerNumSlotsSrc(bagid) do 
            local id,quan = TSM.util.getContainerItemIDSrc(bagid,slotid) 
            if id then 
                if not isGuildBank or not TSM:IsSoulbound(bagid,slotid,id)  then
                    if not tmp[id] then tmp[id] = 0 end
                    tmp[id] = tmp[id] + quan
                end--end if
            end--end if id
        end--end for slots
    end--end for bags
    
    for i,q in pairs(tmp) do 
        table.insert(grp, {item=i,quantity=q} ) 
    end
    TSM.db.factionrealm.BagState = grp
    return grp
end-- function

--------------------------------------------------
-- Now I will unindex my own table, so it is    -- 
-- compatible with my own code....              --
--------------------------------------------------
function data:unIndexTableWarehousing(grp)
    local newgrp = {}
    for i, q in pairs(grp) do
        if tonumber(q) > 0 then
            table.insert(newgrp,{item = i,quantity=tonumber(q) })
        end
    end
    return newgrp
end
-----------------------------------------------
-- Generates a table that is compatible with --
-- warehousing.                              --
-----------------------------------------------
function data:unIndexTableAuctioning(src,t)
    local grp = {}
    local tmp = {}
     
    for i,bag in ipairs(src) do--bags
        for slot = 1, TSM.util.getContainerNumSlotsSrc(bag) do 
             local id,quan = TSM.util.getContainerItemIDSrc(bag,slot)
             if t[id] then
                  if not tmp[id] then tmp[id] = 0 end
                  tmp[id] = tmp[id] + quan  
             end
        end
    end
    
    for i,q in pairs(tmp) do 
        table.insert(grp, {item=i,quantity=q} ) 
    end
    
    return grp
end

function data:unIndexTableAuctioning2(src,t)
    local grp = {}
    local tmp = {}
    local bagState = TSM.db.factionrealm.PlayerBagState
    
    for id in pairs(t) do 
        if not tmp[id] then tmp[id] = 0 end
        
        local needed = TSMAPI:GetData("auctioningPostCount", id)
        local auctions = TSMAPI:GetData("totalplayerauctions", id)
        local q = 0
        
        if auctions and needed then
            if bagState[id] then 
                q = needed - (auctions + bagState[id])
            else 
                q = needed - auctions  
            end
        elseif needed then
            q = needed
        end
        
        if ( q > 0 )then
            table.insert(grp, {item = id, quantity =  q} )
        end
    end

    return grp
end

----------------------------------------------------
-- scan bags and subtract numitem from num needed --
-- the assumption is that a player will only do   --
-- one craft group at a time                      --      
----------------------------------------------------
function data:unIndexTableCrafting(craftGrp,grpName)
    
    TSM:SetCraftGroup(grpName)
    
    local bagState   = TSM.db.factionrealm.PlayerBagState
    local craftState = nil
    local scanTable = {}
    
    if TSM.db.factionrealm.CraftingGroups[grpName] then
        craftState = TSM.db.factionrealm.CraftingGroups[grpName]
        if TSM.db.global.ShowLogData then
            print("In Craft Queue")
            for i,v in pairs(craftState) do
                local _, link = GetItemInfo( i)
                TSM:Print (grpName,": ",link,", have = ",v)
            end
        end
    end

    local zeros = 0
    local grp = {}
    local zeros = {}
     
    for _, item in ipairs(craftGrp) do 
        
        local id   =  item[1]
        local need =  item[2]
        local have =  bagState[id] or 0
        
        if craftState and craftState[id] then have = craftState[id] end

        if have then need = need - have end
        if need > 0 then 
            table.insert (grp, {item = id, quantity = need})
            scanTable[id] = need
        end
        table.insert (zeros, {item = id, quantity = item[2]})            

    end
    
    if TSM.db.global.ShowLogData then
        for i,v in ipairs(grp) do
            local sName, link, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo( v.item )
        end
    end

    if #zeros == #craftGrp then
        TSM.db.factionrealm.CraftingGroups[grpName] = {}
        return zeros, scanTable
    else
        return grp, scanTable
    end
end

