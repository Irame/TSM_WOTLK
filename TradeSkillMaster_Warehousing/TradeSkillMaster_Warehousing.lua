-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Warehousing - AddOn by Geemoney							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_destroying.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the license holder (Sapu) via email at	sapu94@gmail.com with any	  --
--		questions or concerns regarding this license.				 								  --
-- ------------------------------------------------------------------------------------- --
--[[
<Sapu> so idk...I guess you could just keep track of a single session
<Sapu> like if they need 200 dust and 30 essences...and they have none in their bags to start with...
<Sapu> and the first time they pull out all the dust but no essences...and 
       mail off the dust...next time it should show them as just needing essences...
       but if they logged onto a different alt it would show everything...
<Geemoney> why couldnt I store the table in savedDBDefaults, so when the log into another char then they only need the essenses
<Sapu> i guess that'd work...
<Geemoney> then once they have the essense I can reset the table, so whatever char they login to they need everything
<Sapu> if they had some in their bags on that character though it might grab extra...
<Sapu> but I guess that's better than the alternatives
<Geemoney> I can just always subtract needed from what is in the bags
<Sapu> as long as you did it before they got any out of the mailbox heh
<Sapu> like right when they log in
<Geemoney> oh yeah thats true...
<Geemoney> I guess it would have to be right when they log in
<Sapu> so yea if you just subtract what they have in their bags right on login that'd be good i think....or if you wanted to get fancy....
       store what they have in their bags right when they log in in some table....and then subtract it when the warehousing frame actually 
       shows incase they don't actually want to get mats on that toon
]]

--local data = TSMAPI:GetData("auctioningGroups")--
--TSMAPI:GetData("shopping", profession)
--the profession is case sensitive...it's the non-localized name of the profession with the first letter caps
--get secound return value

-- setup
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster_Warehousing", "AceEvent-3.0", "AceConsole-3.0")
local AceGUI = LibStub("AceGUI-3.0")

-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Warehousing") 
TSM.version = GetAddOnMetadata("TradeSkillMaster_Warehousing","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster_Warehousing", "Version") -- current version of the addon

-- default values for the savedDB
-- list of different types of saved variables at the top of http://www.wowace.com/addons/ace3/pages/api/ace-db-3-0/

local savedDBDefaults = {
	-- any global 
	global = {
        defaultIncrement = 1,
        isBankui = true,
        ShowLogData = false,
        DefaultTimeOut = 4,
	},
	
	-- data that is stored per realm/faction combination
	factionrealm = {
        WarehousingGroups = {}, 
        BagState = {},
        CraftingGroups ={},
        PlayerBagState = {},--the state of the players bags on login
	},
	
	-- data that is stored per user profile
	profile = {
        
	},
}

local craftGroup
local bankUI
local bankFrame
-- Called once the player has loaded into the game
-- Anything that needs to be done in order to initialize the addon should go here
function TSM:OnEnable()

    local currentBank = nil
     
    
	for name, module in pairs(TSM.modules) do
          TSM[name] = module
     end
     
	-- load the saved variables table into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMaster_WarehousingDB", savedDBDefaults, true)
	
	-- register the module with TSM
	TSMAPI:RegisterReleasedModule("TradeSkillMaster_Warehousing", TSM.version, GetAddOnMetadata("TradeSkillMaster_Warehousing", "Author"),
		GetAddOnMetadata("TradeSkillMaster_Warehousing", "Notes"))
		
	TSMAPI:RegisterIcon(L["Warehousing"], "Interface\\Icons\\INV_Misc_Bag_SatchelofCenarius",
		function(...) TSM.GUI:Load(...) end, "TradeSkillMaster_Warehousing")
    
    TSM:RegisterEvent("GUILDBANKFRAME_OPENED", function(event)   
        TSMAPI:CreateTimeDelay("warehousingShowDelay", 0.1, function() 
            bankFrame = TSM.bankui:getBankFrame("guildbank")
            if TSM.db.global.isBankui then
                if bankUI then 
                    TSM.bankui:resetPoints(bankFrame,bankUI)
                    bankUI:Show()
                    TSM.bankui:updateButtons()                
                    return 
                end
                bankUI = TSM.bankui:getFrame(bankFrame) 
            end
        end)
	end)
    
	TSM:RegisterEvent("BANKFRAME_OPENED", function(event)
        TSMAPI:CreateTimeDelay("warehousingShowDelay", 0.1, function() 
            bankFrame = TSM.bankui:getBankFrame("bank")
            if TSM.db.global.isBankui then
                if bankUI then 
                    TSM.bankui:resetPoints(bankFrame,bankUI)
                    bankUI:Show()
                    TSM.bankui:updateButtons()                
                    return 
                end
                bankUI = TSM.bankui:getFrame(bankFrame) 
            end
        end)  
	end)
    
    TSM:RegisterEvent("GUILDBANKFRAME_CLOSED", function(event, addon)
        if bankUI then bankUI:Hide() end
	end)
    
    TSM:RegisterEvent("BANKFRAME_CLOSED", function(event)
        if bankUI then bankUI:Hide() end
    end)
    
    TSMAPI:RegisterSlashCommand("movedata",  TSM.SetLogFlag, L["Displays realtime move data."], true)
    TSMAPI:RegisterSlashCommand("bankui",  TSM.toogleBankUI, L["Toggles the bankui"], true)
    
    TSM:UpdatePlayerBagState()
   
end

function TSM:toogleBankUI ()
   if TSM.move:areBanksVisible() then
        bankUI = TSM.bankui:getFrame(bankFrame)
        TSM.db.global.isBankui = true       
    else
        TSM:Print("There are no visible banks.")
    end
end



function TSM:SetLogFlag ()
    if TSM.db.global.ShowLogData then
        TSM.db.global.ShowLogData = false
        TSM:Print("Move Data has been turned off")
    else
        TSM.db.global.ShowLogData = true
        TSM:Print("Move Data has been turned on")
    end
end

function TSM:SetCraftGroup(grp)
    craftGroup = grp
end

-------------------------------------------
-- The captures the current bag state at --
-- login, it is used for Crafting        --
-------------------------------------------
 function TSM:UpdatePlayerBagState()
    if TSM.db.global.ShowLogData then TSM:Print ("UPDATE BAG STATE") end
    TSM.db.factionrealm.PlayerBagState = {}
    --if craftGroup then TSM.db.factionrealm.CraftingGroups[craftGroup] = {} end
    for bagid = 0, NUM_BAG_SLOTS do
        for slotid=1, GetContainerNumSlots(bagid) do
            local quantity = select(2, GetContainerItemInfo(bagid, slotid))
            local item = GetContainerItemID(bagid,slotid)
            if item then 
                
                if TSM.db.factionrealm.PlayerBagState[item] then
                    TSM.db.factionrealm.PlayerBagState[item] = quantity + TSM.db.factionrealm.PlayerBagState[item]
                else
                    TSM.db.factionrealm.PlayerBagState[item] = quantity
                end
                
            end
        end
    end
    craftGroup = nil
end
 -- Make sure the item isn't soulbound
 -- Stolen from old Gathering...thanks Sapu!
local scanTooltip
local resultsCache = {}
function TSM:IsSoulbound(bag, slot, itemID)
	local slotID = tostring(bag) .. tostring(slot) .. tostring(itemID)
	if resultsCache[slotID] then return resultsCache[slotID] end
	
	if not scanTooltip then
		scanTooltip = CreateFrame("GameTooltip", "TSMGatheringScanTooltip", UIParent, "GameTooltipTemplate")
		scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
	end
	scanTooltip:ClearLines()
	
	if bag < 0 or bag > NUM_BAG_SLOTS then
		scanTooltip:SetHyperlink("item:"..itemID)
	else
		scanTooltip:SetBagItem(bag, slot)
	end
	
	for id=1, scanTooltip:NumLines() do
		local text = _G["TSMGatheringScanTooltipTextLeft" .. id]
		if text and ((text:GetText() == ITEM_BIND_ON_PICKUP and id < 4) or text:GetText() == ITEM_SOULBOUND or text:GetText() == ITEM_BIND_QUEST) then
			resultsCache[slotID] = true
			return true
		end
	end
	
	resultsCache[slotID] = nil
	return false
end