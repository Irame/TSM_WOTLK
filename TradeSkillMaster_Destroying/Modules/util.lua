-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Destroying") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local util = TSM:NewModule("util", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

util.dObj = {
    bag = 0,
    slot = 1,
    MergeTable = {},
    Item = nil,
}

local bagsNum = 4
local merge = CreateFrame("Frame") 

merge:Hide() 
merge:SetScript("OnUpdate", 
	
	function(self, elapsed)
    
        for i,t in pairs(util.dObj.MergeTable) do 
            if #t >= 2 then util.dObj.Item = i; break end 
            self:Hide()
        end
        
        if not util.dObj.MergeTable[util.dObj.Item] then self:Hide() return end
        local len = #util.dObj.MergeTable[util.dObj.Item]

        if util.dObj.MergeTable[util.dObj.Item][len] and util.dObj.MergeTable[util.dObj.Item][len-1] then

            PickupContainerItem(util.dObj.MergeTable[util.dObj.Item][len].bag, util.dObj.MergeTable[util.dObj.Item][len].slot)
            PickupContainerItem(util.dObj.MergeTable[util.dObj.Item][len-1].bag ,util.dObj.MergeTable[util.dObj.Item][len-1].slot) 
            ClearCursor()
        
            table.remove(util.dObj.MergeTable[util.dObj.Item])
            table.remove(util.dObj.MergeTable[util.dObj.Item])
            
        end
        if #util.dObj.MergeTable[util.dObj.Item] < 2 then util.dObj.MergeTable[util.dObj.Item] = nil end
	end --end function

) 

local function merger (id,bag,slot,stacksize) 
    if not util.dObj.MergeTable[id] then util.dObj.MergeTable[id] = {} end
    table.insert(util.dObj.MergeTable[id], {bag = bag, slot = slot, num = stackSize})
end

--action: prospectable, millable or de'able
function util:searchAndDestroy(action, pre)
    
    local found = nil
    
    for bag = util.dObj.bag,bagsNum do --bags		
        for slot = util.dObj.slot,GetContainerNumSlots(bag) do
            if TSM:IsDestroyable(bag, slot, action) then
                local id = GetContainerItemID(bag, slot);
                local _,stackSize,_ = GetContainerItemInfo(bag, slot)
                
                if  pre == nil or (bag ~= pre.bag or slot ~= pre.slot) then 
                    if stackSize >= 5 then
                        TSM.loot:setMat(id)--this is for counting loot
                        stackSize = stackSize - 5 --to account for what got destroyed                       
                        if stackSize == 5 then 
                            util.dObj.bag  = bag
                            util.dObj.slot = slot
                        end
                        return {bag = bag, slot = slot}
                    elseif stackSize < 5 then
                        merger(id,bag,slot,stackSize)
                    end
                    --keeps a count of destroyable mats in the users bags
                    if stackSize then
                        if not found or not found[id] then 
                            found = {}
                            found[id] = {num = stackSize} 
                        end
                        found[id].num = found[id].num + stackSize
                    end
                end
                merge:Show()
                
            end--end IsDestroyable
        end--end slots
    end--end bags

    --We have reached the end, now we need to reset
    util.dObj.bag  = 0
    util.dObj.slot = 1
    
    if found then
        for i,v in ipairs(found) do
            if v.num >= 5 then  util:searchAndDestroy(action, pre) end
        end
    end
    
    --this means there is nothing to destroy
    return nil
end--end function
