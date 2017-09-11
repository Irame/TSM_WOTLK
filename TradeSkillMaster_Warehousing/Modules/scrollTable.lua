local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Warehousing") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local scrollTable = TSM:NewModule("scrollTable", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local currentTable = nil
local currentGroup = nil

function scrollTable:HideTables (container) 
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

function scrollTable:DrawLeftScrollFrame (container)
   local ROW_HEIGHT = 20
   local stCols
    stCols ={ 
        {name=L["Groups"], width=1}     
    }
    
	local function GetSTColInfo(width)
        local colInfo =CopyTable(stCols)
        for i=1, #colInfo do
                colInfo[i].width = floor(colInfo[i].width*width)
        end
        return colInfo
    end

    groupST = TSMAPI:CreateScrollingTable(GetSTColInfo(container.frame:GetWidth()), true)
    groupST:EnableSelection(true)
    
    local stTable= {}
    local data = TSM.db.factionrealm.WarehousingGroups
    for i, t in pairs(data) do table.insert (stTable, scrollTable:createRow(t.name,t.name)) end
    
    groupST:SetData(stTable)
	groupST.frame:SetParent(container.frame)
	groupST.frame:SetPoint("TOPLEFT", container.frame, 10, -100)--TOPRIGHT = right-x, top-y
	groupST.frame:SetPoint("BOTTOMRIGHT", container.frame, -(container.frame:GetWidth()*.75)  , 40) 
    groupST.frame:SetScript("OnSizeChanged", function(_,width, height)
        groupST:SetDisplayCols(GetSTColInfo(width))
        groupST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
        groupST.frame:SetPoint("TOPLEFT", container.frame, 10, -100)--TOPRIGHT = right-x, top-y
        groupST.frame:SetPoint("BOTTOMRIGHT", container.frame, -(container.frame:GetWidth()*.75)  , 40)  
    end)
    
     groupST:RegisterEvents({
        ["OnClick"] = function(self, _, data, _, _, rowNum, column, st, button)
            if button == "LeftButton" then
                if not rowNum then return end
                if not currentGroup or currentGroup ~= data[rowNum].name then
                    currentGroup = data[rowNum].name
                    currentTable = TSM.db.factionrealm.WarehousingGroups[rowNum]
                    scrollTable:refreshMiddleTable(container)
                else
                    currentGroup = false
                    currentTable = nil
                    scrollTable:refreshMiddleTable(container)
                end
                
            end
            
        end,
        ["OnEnter"] = function(_, self, data, _, _, rowNum)
            if not rowNum then return end
        end,
        ["OnLeave"] = function()
            
        end
    })
    
	groupST:Show()

end

function scrollTable:createRow(data,link,num)
	return 
	{
		cols = {

			{
				value = function(data) if data then return data end end,
				args = {link},
			},	
            {
				value = function(data) if data then  return data else return 0 end end,
				args = {num},
			},	
		},
        name = data
	}
end

function scrollTable:DrawMiddleScrollFrame (container)
   local ROW_HEIGHT = 20
   local stCols

    stCols ={ 
        {name=L["Item"], width=.7},
        {name=L["Quantity"], width=.30}    
    }
     
	local function GetSTColInfo(width)
        local colInfo =CopyTable(stCols)
        for i=1, #colInfo do
                colInfo[i].width = floor(colInfo[i].width*width)
        end
        return colInfo
    end

    itemST = TSMAPI:CreateScrollingTable(GetSTColInfo(container.frame:GetWidth()), true)
    
    local stTable= {}
    local data = TSM.searchInventory:searchBags(currentTable)
    --local data = TSM.searchInventory:searchBank()
    for i, t in pairs(data) do
        if currentTable then
            table.insert (stTable, scrollTable:createRow(t.item,t.itemlink,currentTable.data[t.item]))
        end
    end
    itemST:SetData(stTable)
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
            
            local increment = tonumber(TSM.db.global.defaultIncrement)
            
            if button == "LeftButton" then
                if not rowNum or not currentTable then return end
                item = data[rowNum].name
                if not currentTable.data[item] then
                    currentTable.data[item] = increment
                else
                    currentTable.data[item] = currentTable.data[item] + increment
                end
                scrollTable:refreshMiddleTable(container) 
            end
            if button == "RightButton" then
                if not rowNum or not currentTable then return end
                item = data[rowNum].name
                if currentTable.data[item] and currentTable.data[item] - increment >= 0 then
                    currentTable.data[item] = currentTable.data[item] - increment
                elseif currentTable.data[item] and currentTable.data[item] - increment < 0 then
                    currentTable.data[item] = 0
                end
                scrollTable:refreshMiddleTable(container) 
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

function scrollTable:cleanup()
    currentTable = nil
    currentGroup = nil
end

function scrollTable:refreshMiddleTable(container)
    if itemST then
        itemST:Hide()
    end
    TSM.scrollTable:DrawMiddleScrollFrame(container)
end


function scrollTable:refresh(container)
    if groupST then
        groupST:Hide()
    end
    if itemST then
        itemST:Hide()
    end
    TSM.scrollTable:DrawLeftScrollFrame(container)
    TSM.scrollTable:DrawMiddleScrollFrame(container)
end
