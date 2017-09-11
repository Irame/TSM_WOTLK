-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Destroying") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local destroybtn = TSM:NewModule("destroybtn", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

--Professions--
local prospecting = 31252
local milling = 51005
local disenchanting = 13262

--Useful Globals--
local mat

local speedTable ={
    ["Slow"]   = "Slow",
    ["Normal"] = "Normal",
    ["Fast"]   = "Fast"
}

local function getSpells()
	local t = {}
    local num = 0
    local mode = nil
    if IsSpellKnown(disenchanting) then
		t["Disenchanting"] = "Disenchanting"
        num = num + 1
        mode = "Disenchanting"
	end
	if IsSpellKnown(milling) then
		t["Milling"] = "Milling"
        num = num + 1
        mode = "Milling"
	end
	if IsSpellKnown(prospecting) then
		t["Prospecting"] = "Prospecting"
        num = num + 1
        mode = "Prospecting"
	end
    
    return t,num,mode
end  

local frame = nil
function destroybtn:Show()
    if frame and frame:IsVisible() then return end
    
    local spellTable, numSpells, spell = getSpells()
    if numSpells > 0 then
        TSM:Print(L["The Destroyer has risen!"])

        frame = AceGUI:Create("TSMWindow")
        local dButton = AceGUI:Create("TSMFastDestroyButton")
        local dropSpell = AceGUI:Create("TSMDropdown")
        local dropSpeed = AceGUI:Create("TSMDropdown")
        
        frame:SetCallback("OnClose", function(widget) AceGUI:Release(widget) end)
        frame:SetTitle(L["The Destroyer"])
        frame:SetLayout("Flow")
        frame:SetHeight(175)
        frame:SetWidth(200)
        frame:SetPoint(TSM.db.global.anchor, TSM.db.global.xPos, TSM.db.global.yPos)
        frame:SetCallback("OnClose", function (self) 
            TSM.db.global.anchor,_, _,TSM.db.global.xPos,TSM.db.global.yPos = self:GetPoint() 
            AceGUI:Release(self)
            dButton:SetSpell(nil)
        end)
        
        dButton:SetText("Destroy")
        dButton:SetHeight(75)
        dButton:SetMode("normal")
        dButton:SetLocationsFunc( function(previous)
            TSM.loot:show() 
            if mat == "Disenchantable" then return end
            return TSM.util:searchAndDestroy(mat,previous)
        end)
        
        dropSpeed:SetList(speedTable)
        dropSpeed:SetCallback("OnValueChanged",function(this, event, item) 
            TSM.db.global.dMode = item
            dButton:SetMode(item) 
        end)
        dropSpeed:SetValue(TSM.db.global.dMode)
        
        dropSpell:SetList(spellTable)
        dropSpell:SetCallback("OnValueChanged",function(this, event, item) 
            dButton:SetSpell(item) 
            TSM.loot:setAction(item)
            if item == "Disenchanting" then
                dButton:SetLocationsFunc( 
                function(previous)
                    TSM.loot:show() 
                    return TSM.de:searchAndDestroy(previous)
                end)
                return
            end
            
            if item =="Prospecting" then
                mat = "Prospectable"
            elseif item == "Milling" then
                mat = "Millable"
            end
            
            dButton:SetLocationsFunc( function(previous)
                TSM.loot:show() 
                return TSM.util:searchAndDestroy(mat,previous)
            end)

        end)
        
        frame:AddChild(dropSpell) 
        frame:AddChild(dropSpeed)
        frame:AddChild(dButton)
        
        return
    end
     TSM:Print(L["You do not know Milling, Prospecting or Disenchanting."])
end

    