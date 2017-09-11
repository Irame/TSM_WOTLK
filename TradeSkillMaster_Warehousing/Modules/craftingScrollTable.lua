local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Warehousing") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local craftingScrollTable = TSM:NewModule("craftingScrollTable", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local currentProf = nil
local itemST, itemRightST,groupST

function craftingScrollTable:HideTables (container) 
	if groupST then
		groupST:Hide()
	end
	if itemST then
		itemST:Hide()
	end
	if itemRightST then
		itemRightST:Hide()
	end
end


function craftingScrollTable:createRow(link,need,have)
	return 
	{
		cols = {

			{
				value = function(data) if data then return data end end,
				args = {link},
			},	
			{
				value = function(data) if data then return data end end,
				args = {need},
			},	
            {
				value = function(data) if data then  return data else return 0 end end,
				args = {have},
			},	
		},
	}
end
--I may have broken this....
function craftingScrollTable:updateST(prof)
    local stTable= {}
    local bagState = TSM.db.factionrealm.CraftingGroups[prof]
    local craftGrp = TSMAPI:GetData("shopping", prof)
    for _, item in ipairs(craftGrp) do 
        local _, link = GetItemInfo(item[1]);
        local need = item[2]
        local have = 0
        if bagState then have =  bagState[item[1]] or 0 end
        if craftState and craftState[item[1]] then 
            have = craftState[item[1]] 
        end
        table.insert (stTable, craftingScrollTable:createRow(link,need, have))
    end
    itemST:SetData(stTable)
end

function craftingScrollTable:DrawScrollFrame (container,prof)
   local ROW_HEIGHT = 20
   local stCols

    stCols ={ 
        {name=L["Item"], width=.50},
        {name=L["Need"], width=.25},
        {name=L["Have"], width=.25}         
    }
     
	local function GetSTColInfo(width)
        local colInfo =CopyTable(stCols)
        for i=1, #colInfo do
                colInfo[i].width = floor(colInfo[i].width*width)
        end
        return colInfo
    end

    itemST = TSMAPI:CreateScrollingTable(GetSTColInfo(container.frame:GetWidth()), true)
    
    if prof then craftingScrollTable:updateST(prof) end
    
    
    --itemST:EnableSelection(true)
	itemST.frame:SetParent(container.frame)
	itemST.frame:SetPoint("TOPLEFT", container.frame,(container.frame:GetWidth()*.25)+20, -100)--TOPRIGHT = right-x, top-y
	itemST.frame:SetPoint("BOTTOMRIGHT", container.frame, -(container.frame:GetWidth()*.1)  , 40) 
    itemST.frame:SetScript("OnSizeChanged", function(_,width, height)
        itemST:SetDisplayCols(GetSTColInfo(width))
        itemST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
        itemST.frame:SetPoint("TOPLEFT", container.frame, (container.frame:GetWidth()*.25)+20, -100)--TOPRIGHT = right-x, top-y
        itemST.frame:SetPoint("BOTTOMRIGHT", container.frame, -(container.frame:GetWidth()*.1)  , 40)  
    end)
    
    itemST:RegisterEvents({
        ["OnClick"] = function(self, _, data, _, _, rowNum, column, st, button)
            
            local increment = TSM.db.global.defaultIncrement
            
            if button == "LeftButton" then
                if not rowNum or not currentTable then return end
                local item = data[rowNum].name
                if not currentTable.data[item] then
                    currentTable.data[item] = increment
                else
                    currentTable.data[item] = currentTable.data[item] + increment
                end
                craftingScrollTable:refreshMiddleTable(container) 
            end
            if button == "RightButton" then
                if not rowNum or not currentTable then return end
                local item = data[rowNum].name
                if currentTable.data[item] and currentTable.data[item] - increment >= 0 then
                    currentTable.data[item] = currentTable.data[item] - increment
                elseif currentTable.data[item] and currentTable.data[item] - increment < 0 then
                    currentTable.data[item] = 0
                end
                craftingScrollTable:refreshMiddleTable(container) 
            end
        end,
        ["OnEnter"] = function(_, self, data, _, _, rowNum)
            if not rowNum then return end
        end,
        ["OnLeave"] = function()
        end
    }) 
	itemST:Show()
end

function craftingScrollTable:refresh(container,prof)
    if itemST then
        itemST:Hide()
    end
    currentProf = prof
    TSM.craftingScrollTable:DrawScrollFrame(container,prof)
end
