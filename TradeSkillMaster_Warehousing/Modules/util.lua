-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Warehousing") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local util = TSM:NewModule("util", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

-- this is a set of wrapper functions so that I can switch 
-- between guildbank and bank function easily


util.pickupContainerItemSrc = nil
util.getContainerItemIDSrc = nil
util.getContainerNumSlotsSrc = nil
util.getContainerItemLinkSrc = nil
util.getContainerNumFreeSlotsSrc = nil
util.splitContainerItemSrc = nil

util.pickupContainerItemDest = nil
util.getContainerItemIDDest = nil
util.getContainerNumSlotsDest = nil
util.getContainerItemLinkDest = nil
util.getContainerNumFreeSlotsDest = nil

util.getItemString = nil
util.autoStoreItem = nil


function util:setSrcBagFunctions(bagType)
    if bagType == "guildbank" then
        util.autoStoreItem = function (bag,slot) AutoStoreGuildBankItem(bag,slot) end
        util.splitContainerItemSrc = function (bag,slot, need) SplitGuildBankItem(bag, slot, need);end
        util.pickupContainerItemSrc = function(bag,slot) PickupGuildBankItem(bag,slot) end
        util.getContainerNumSlotsSrc = function (bag) return 98 end
        util.getContainerItemLinkSrc = function (bag, slot) return GetGuildBankItemLink(bag,slot) end
        util.getContainerNumFreeSlotsSrc = function (bag) return 98 end --need to change this eventually
        util.getContainerItemIDSrc = function (bag,slot)   
            local link=GetGuildBankItemLink(bag,slot)
            local quantity = select(2,GetGuildBankItemInfo(bag,slot))
            if link then
                local n, itemId, enchantId, jewelId1, jewelId2, jewelId3, 
                jewelId4, suffixId, uniqueId, linkLevel, reforgeId 
                = strsplit(":", string.match(link, "item[%-?%d:]+"))
                return  tonumber(itemId),quantity
            else 
                return nil
            end
        end
    else
        util.autoStoreItem = function (bag,slot) UseContainerItem(bag, slot) end
        util.splitContainerItemSrc = function (bag,slot,need) SplitContainerItem(bag, slot, need) end
        util.pickupContainerItemSrc = function(bag,slot) PickupContainerItem(bag,slot) end
        util.getContainerItemIDSrc = function(bag,slot) 
            local quantity = select(2, GetContainerItemInfo(bag, slot))
            return GetContainerItemID(bag,slot) , quantity
        end
        util.getContainerNumSlotsSrc = function(bag) return GetContainerNumSlots(bag) end
        util.getContainerItemLinkSrc = function(bag,slot) return GetContainerItemLink(bag,slot) end
        util.getContainerNumFreeSlotsSrc = function(bag) return GetContainerNumFreeSlots (bag) end
    end
end

function util:setDestBagFunctions(bagType)
    if bagType == "guildbank" then
        util.pickupContainerItemDest = function(bag,slot) PickupGuildBankItem(bag,slot)end
        util.getContainerNumSlotsDest = function (bag) return 98 end
        util.getContainerNumFreeSlotsDest = function (bag) return 98 end --need to change this eventually 
        util.getContainerItemLinkDest = function (bag, slot) return GetGuildBankItemLink(bag,slot) end
        util.getContainerItemIDDest = function (bag,slot) 
            local link=GetGuildBankItemLink(bag,slot)
            local quantity = select(2,GetGuildBankItemInfo(bag,slot))
            if link then
                local n, itemId, enchantId, jewelId1, jewelId2, jewelId3, 
                jewelId4, suffixId, uniqueId, linkLevel, reforgeId 
                = strsplit(":", string.match(link, "item[%-?%d:]+"))
                return tonumber(itemId), quantity
            else 
                return nil
            end
        end
    else
        util.pickupContainerItemDest = function(bag,slot) PickupContainerItem(bag,slot) end
        util.getContainerItemIDDest = function(bag,slot) 
            local quantity = select(2, GetContainerItemInfo(bag, slot))
            return GetContainerItemID(bag,slot) , quantity
        end
        util.getContainerNumSlotsDest = function(bag) return GetContainerNumSlots(bag) end
        util.getContainerItemLinkDest = function(bag,slot) return GetContainerItemLink(bag,slot) end
        util.getContainerNumFreeSlotsDest = function(bag) return GetContainerNumFreeSlots (bag) end
    end
end

--
--This will find a special bag for your special item
--
function util:canGoInBag(item, destTable)
    local itemFamily = GetItemFamily(item)
    local default
    for bag,_ in pairs(destTable) do
        local bagFamily = GetItemFamily(GetBagName(bag)) or 0
        if  itemFamily and bagFamily and bagFamily >0 and bit.band(itemFamily, bagFamily) > 0 then
            return bag
        elseif bagFamily == 0 then
            default = bag
        end
    end
    return default
end
