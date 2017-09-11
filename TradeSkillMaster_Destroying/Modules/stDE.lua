-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Destroying") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local stDE = TSM:NewModule("stDE", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local itemST = nil

local deGUIObj = {
    container  = nil, 
    action     = nil, 
    filter     = nil
}
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

local function sortPairs(t)
    local u = {}
    local function compare (a,b) return a.key>b.key end
    for k, v in pairs(t) do table.insert(u, { key = k }) end
    table.sort(u, compare)
    return u
end

local function DrawGearScrollFrame ()

	local ROW_HEIGHT = 20
	local stCols = {
		    {name="Destroy Item", width=0.75},   
	}
	
	local function GetSTColInfo(width)
        local colInfo = CopyTable(stCols)
        for i=1, #colInfo do
            colInfo[i].width = floor(colInfo[i].width*width)
        end
        return colInfo
    end
        
	if not gearST then
        gearST = TSMAPI:CreateScrollingTable(GetSTColInfo( deGUIObj.container.frame:GetWidth()), true )	
    end 
    
	gearST.frame:SetParent(deGUIObj.container.frame)
	gearST.frame:SetPoint("TOPLEFT", deGUIObj.container.frame, 20, -130) 
	gearST.frame:SetPoint("BOTTOMRIGHT", deGUIObj.container.frame, -deGUIObj.container.frame:GetWidth()*.5, deGUIObj.container.frame:GetHeight()*.5 ) 
	gearST.frame:SetScript("OnSizeChanged", function(_,width, height)
			gearST:SetDisplayCols(GetSTColInfo(width))
			gearST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
			gearST.frame:SetPoint("TOPLEFT", deGUIObj.container.frame, 20, -130) 
			gearST.frame:SetPoint("BOTTOMRIGHT", deGUIObj.container.frame, -deGUIObj.container.frame:GetWidth()*.5, deGUIObj.container.frame:GetHeight()*.5 ) 
		end)
	
	gearST:SetData(TSM.de:getDestroyTable())
	gearST:Show()
	
	gearST:RegisterEvents({
		["OnClick"] = function(_, _, data, _, _, rowNum, _, self,button)
			if button == "RightButton" then--move to safe
			
				if not rowNum then return end
				TSM.db.factionrealm.SafeTable[data[rowNum].itemString] = true 
				stDE:updateGearTables()
			elseif button == "LeftButton" then --destroy??
				
			end
		end,
		["OnEnter"] = function(_, self, data, _, _, rowNum)
			if not rowNum then return end

			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
			GameTooltip:SetHyperlink(data[rowNum].itemString) 
			GameTooltip:Show()
		end,
		["OnLeave"] = function()
			GameTooltip:ClearLines()
			GameTooltip:Hide()
		end
	})
end

local function DrawSafeGearScrollFrame ()
	local ROW_HEIGHT = 20
	local stCols = {
		    {name="Safe Item", width=0.75},
	}
	
	local function GetSTColInfo(width)
        local colInfo = CopyTable(stCols)
        for i=1, #colInfo do
                colInfo[i].width = floor(colInfo[i].width*width)
        end
        return colInfo
    end
        
	if not safegearST then
		safegearST = TSMAPI:CreateScrollingTable(GetSTColInfo( deGUIObj.container.frame:GetWidth()), true )
	end 

	safegearST:SetData(TSM.de:getSafeTable())

	safegearST.frame:SetParent(deGUIObj.container.frame)
	safegearST.frame:SetPoint("TOPLEFT", deGUIObj.container.frame, 20, -(deGUIObj.container.frame:GetHeight()*.5)-20)--TOPRIGHT = right-x, top-y
	safegearST.frame:SetPoint("BOTTOMRIGHT", deGUIObj.container.frame, -(deGUIObj.container.frame:GetWidth()*.5)  , 20) 
	safegearST.frame:SetScript("OnSizeChanged", function(_,width, height)
			safegearST:SetDisplayCols(GetSTColInfo(width))
			safegearST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
			safegearST.frame:SetPoint("TOPLEFT", deGUIObj.container.frame, 20, -(deGUIObj.container.frame:GetHeight()*.5)-20)--TOPRIGHT = right-x, top-y
			safegearST.frame:SetPoint("BOTTOMRIGHT", deGUIObj.container.frame, -deGUIObj.container.frame:GetWidth()*.5, 20) 
		end)
	safegearST:RegisterEvents({
	["OnClick"] = function(_, _, data, _, _, rowNum, _, self,button)
	
		if button == "RightButton" then--move to destroy
			if not rowNum then return end
            TSM.db.factionrealm.SafeTable[data[rowNum].itemString] = nil
            stDE:updateGearTables()
		elseif button == "LeftButton" then 
	
		end
	end,
	["OnEnter"] = function(_, self, data, _, _, rowNum)
		if not rowNum then return end

		GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
		GameTooltip:SetHyperlink(data[rowNum].itemString) 
		GameTooltip:Show()
	end,
	["OnLeave"] = function()
		GameTooltip:ClearLines()
		GameTooltip:Hide()
	end
	})
	safegearST:Show()
	
	
end

local function DrawScrollFrame ()

    local ROW_HEIGHT = 20
    local stCols

    stCols ={
        {name="", width=0.25},
        {name="Item", width=0.48},
        {name="Quantiy", width=0.25},             
    }

    local function GetSTColInfo(width)
        local colInfo =CopyTable(stCols)
        for i=1, #colInfo do
            colInfo[i].width = floor(colInfo[i].width*width)
        end
        return colInfo
    end
        
    itemST = TSMAPI:CreateScrollingTable(GetSTColInfo(deGUIObj.container.frame:GetWidth()))

    local stTable = {}

    if TSM.db.factionrealm.DE then
       for item,itemTable in pairs(TSM.db.factionrealm.DE) do
            local day = sortPairs(TSM.db.factionrealm.DE.Day)
            for _,d in ipairs(day) do
                table.insert(stTable,createDateRow(d.key))
                for i,v in pairs(TSM.db.factionrealm.DE.Day[d.key])do  
                    table.insert(stTable,createRow(i,v))
                end
            end
        end
        itemST:SetData(stTable)
    else
       itemST:SetData( noLoot() )
    end
 
    itemST.frame:SetParent(deGUIObj.container.frame)
	itemST.frame:SetPoint("TOPLEFT", deGUIObj.container.frame, deGUIObj.container.frame:GetWidth()*.5, -105 )--TOPRIGHT = right-x, top-y
	itemST.frame:SetPoint("BOTTOMRIGHT", deGUIObj.container.frame, -25  , 20) 
	itemST.frame:SetScript("OnSizeChanged", function(_,width, height)
			itemST:SetDisplayCols(GetSTColInfo(width))
			itemST:SetDisplayRows(floor(height/ROW_HEIGHT), ROW_HEIGHT)
			itemST.frame:SetPoint("TOPLEFT", deGUIObj.container.frame, deGUIObj.container.frame:GetWidth()*.5, -105 )--TOPRIGHT = right-x, top-y
			itemST.frame:SetPoint("BOTTOMRIGHT", deGUIObj.container.frame, -25  , 20) 
    end)
      
    itemST:Show()

end

function stDE:hideTable()
	if itemST     then itemST:Hide() end
    if gearST     then gearST:Hide() end
    if safegearST then safegearST:Hide() end
end

function stDE:updateTable()
	if itemST then itemST:Hide() end
    if gearST     then gearST:Hide() end
    DrawScrollFrame(frame, action, filter)
    DrawGearScrollFrame ()
end

function stDE:updateGearTables()
    if gearST     then gearST:Hide() end
    if safegearST then safegearST:Hide() end
    DrawGearScrollFrame ()
    DrawSafeGearScrollFrame ()
end

function stDE:InitScrollFrames (container, action, filter) 
    deGUIObj.container = container
    deGUIObj.action = action
    deGUIObj.filter = filter
    DrawScrollFrame ()
    DrawGearScrollFrame ()
    DrawSafeGearScrollFrame ()   
end