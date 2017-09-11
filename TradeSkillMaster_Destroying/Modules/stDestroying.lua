-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Destroying") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local stDestroying = TSM:NewModule("stDestroying", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local itemST = nil

local qualityColors = { --I stole this from Sapu....
	[0]="9d9d9d",
	[1]="ffffff",
	[2]="1eff00",
	[3]="0070dd",
	[4]="a335ee",
	[5]="ff8000",
	[6]="e6cc80",
}

local function noLoot()
    return{ { cols = { { 
        value = function() return "You have chosen to turn off sum loot"  end,
        args = {},
    },},}}
end

local function createDateRow(d)
	local obj = TSM.GUI:getInfo()
    if obj.filter == "mats" then _, d = GetItemInfo( d) end
    return 
	{
		cols = {
			{
				value = function(data) if data then return data end end,
				args = {d},
			},	
			{},
			{},
		},
	}
end

local function createRow(name,d)
    return  
	{
		
		cols = {
			{},
			{
                value = function(data, qual) if data and qual then return "|cff"..qualityColors[qual]..data.."|r" end end,
                args = {name, d.quality},
            },
			{
            	value = function(data) if data then return data end end,
				args = {d.num},
            },
		},

	}
end

function stDestroying:hideTable()
	if itemST then
		itemST:Hide()
	end
end

function stDestroying:updateTable(frame, action, filter)
	stDestroying:hideTable()
    stDestroying:DrawScrollFrame(frame, action, filter)
end

local function sortPairs(t)
    local u = {}
    local function compare (a,b) return a.key>b.key end
    for k, v in pairs(t) do table.insert(u, { key = k }) end
    table.sort(u, compare)
    return u
end

function stDestroying:DrawScrollFrame (container, action, filter)
    assert(action == "prospecting" or action == "milling", "Invalid action: "..action..". Expected \"prospecting\" or \"milling\"")
    assert(filter == "mats" or filter == "date", "Invalid filter: "..filter..". Expected \"mats\" or \"date\"")

    local ROW_HEIGHT = 20
    local stCols

    stCols ={
        {name="", width=0.25},
        {name="Item", width=0.48},
        {name="Quantiy", width=0.25},             
    }

    local function GetSTColInfo(width)
        local colInfo = CopyTable(stCols)
        for i=1, #colInfo do
            colInfo[i].width = floor(colInfo[i].width*width)
        end
        return colInfo
    end
        
    itemST = TSMAPI:CreateScrollingTable(GetSTColInfo(container.frame:GetWidth()))

    local stTable = {}
    local gTable = nil
    
    if action == "prospecting" and TSM.db.factionrealm.Prospecting then
        gTable = TSM.db.factionrealm.Prospecting
    elseif action == "milling" and TSM.db.factionrealm.Milling then
        gTable = TSM.db.factionrealm.Milling
    end
    
    if gTable then
        if filter == "mats" then
           for item,itemTable in pairs(gTable.Mat) do
                table.insert(stTable,createDateRow(item))
                for i,v in pairs(itemTable)do  
                    table.insert(stTable,createRow(i,v))
                end
            end
        elseif filter == "date" then
            local day = sortPairs(gTable.Day)
            for _,d in ipairs(day) do
                table.insert(stTable,createDateRow(d.key))
                for i,v in pairs(gTable.Day[d.key])do  
                    table.insert(stTable,createRow(i,v))
                end
            end
            
        end
        itemST:SetData(stTable)
    else
       itemST:SetData( noLoot() )
    end
 

    itemST.frame:SetParent(container.frame)
    itemST.frame:SetPoint("BOTTOMLEFT", container.frame, 10, 10)
    itemST.frame:SetPoint("TOPRIGHT", container.frame, -10, -130)
    itemST.frame:SetScript("OnSizeChanged", function(_,width, height)
            itemST:SetDisplayCols(GetSTColInfo(width))
            itemST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
        end)
    itemST:Show()

	
end