-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Accounting - AddOn by Sapu94							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_accounting.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- register this file with Ace Libraries
local TSM = select(2, ...)
TSM = LibStub("AceAddon-3.0"):NewAddon(TSM, "TradeSkillMaster_Accounting", "AceEvent-3.0", "AceConsole-3.0")
TSM.soldData = {}
TSM.buyData = {}

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Accounting") -- loads the localization table
TSM.version = GetAddOnMetadata("TradeSkillMaster_Accounting","X-Curse-Packaged-Version") or GetAddOnMetadata("TradeSkillMaster_Accounting", "Version") -- current version of the addon

local savedDBDefaults = {
	global = {
		itemStrings = {},
		infoID = 0,
	},
	factionrealm = {
		itemData = {},
		timeFormat = "ago",
		mvSource = "adbmarket",
		priceFormat = "avg",
		tooltip = {sale=false, purchase=false},
		smartBuyPrice = false,
	},
	profile = {
	},
}

-- Called once the player has loaded WOW.
function TSM:OnInitialize()
	-- load the savedDB into TSM.db
	TSM.db = LibStub:GetLibrary("AceDB-3.0"):New("TradeSkillMaster_AccountingDB", savedDBDefaults, true)
	
	for module in pairs(TSM.modules) do
		TSM[module] = TSM.modules[module]
	end
	
	if not TSM.Util then
		error("Accounting failed to load because you haven't restarted wow since updating.")
	end

	TSMAPI:RegisterReleasedModule("TradeSkillMaster_Accounting", TSM.version, GetAddOnMetadata("TradeSkillMaster_Accounting", "Author"), GetAddOnMetadata("TradeSkillMaster_Accounting", "Notes"))
	TSMAPI:RegisterIcon(L["Accounting"], "Interface\\Icons\\Inv_Misc_Coin_02", function(...) TSM.GUI:Load(...) end, "TradeSkillMaster_Accounting")

	if TSM.db.factionrealm.tooltip.sale or TSM.db.factionrealm.tooltip.purchase then
		TSMAPI:RegisterTooltip("TradeSkillMaster_Accounting", function(...) return TSM:LoadTooltip(...) end)
	end
	
	if TSM.db.global.infoID < 1 then
		local isEnabled, _, isInstalled = select(4, GetAddOnInfo("MySales"))
		if not (isEnabled or isInstalled == "DISABLED") then
			TSM.db.global.infoID = 1
			return
		else
			StaticPopupDialogs["TSMAccountingImport"] = {
				text = L["TradeSkillMaster_Accounting has detected that you have MySales installed. Would you like to transfer your data over to Accounting?"],
				button1 = YES,
				button2 = CANCEL,
				timeout = 0,
				whileDead = true,
				hideOnEscape = false,
				OnAccept = function() TSM:ImportFromMySales() end,
				OnCancel = function() TSM.db.global.infoID = 1 end,
			}
			StaticPopup_Show("TSMAccountingImport")
			for i=1, 10 do
				if _G["StaticPopup" .. i] and _G["StaticPopup" .. i].which == "TSMAccountingImport" then
					_G["StaticPopup" .. i]:SetFrameStrata("TOOLTIP")
					break
				end
			end
		end
	end
	
	if TSM.db.factionrealm.sellDataRope or TSM.db.factionrealm.buyDataRope then
		TSM.Util:OldDeserialize()
	elseif not TSM.db.factionrealm.itemData.sell and not TSM.db.factionrealm.itemData.buy then
		TSM.db.factionrealm.itemData = {sell={}, buy={}}
		TSM.soldData = TSM.db.factionrealm.itemData.sell
		TSM.buyData = TSM.db.factionrealm.itemData.buy
	else
		TSM.soldData = {}
		TSM.buyData = {}
	end
	
	if not TSM.db.factionrealm.itemData.sell and not TSM.db.factionrealm.itemData.buy then
		TSM.db.factionrealm.itemData = {sell={}, buy={}}
		
		for itemString, data in pairs(TSM.soldData) do
			TSM.db.factionrealm.itemData.sell[itemString] = TSM.Util:EncodeItemData("sold", itemString, data)
		end
		TSM.soldData = TSM.db.factionrealm.itemData.sell
		
		for itemString, data in pairs(TSM.buyData) do
			TSM.db.factionrealm.itemData.buy[itemString] = TSM.Util:EncodeItemData("buy", itemString, data)
		end
		TSM.buyData = TSM.db.factionrealm.itemData.buy
		
		TSM.db.factionrealm.sellDataRope = nil
		TSM.db.factionrealm.buyDataRope = nil
	end
	
	TSM.buyData = TSM.db.factionrealm.itemData.buy
	TSM.soldData = TSM.db.factionrealm.itemData.sell
	
	TSM.Data:Initialize()
end

function TSM:LoadTooltip(itemID)
	local itemString = TSM:GetItemString(itemID)
	if itemString then
		local itemCount = 0
		if TSM.db.factionrealm.smartBuyPrice then
			local player, alts = TSMAPI:GetData("playertotal", itemID)
			local guild = TSMAPI:GetData("guildtotal", itemID)
			if player then
				itemCount = player + alts
			end
			itemCount = itemCount + (guild or 0)
		end
	
		local text = {}
		local sellRecords = TSM.Util:GetRecords("sold", itemString)
		if TSM.db.factionrealm.tooltip.sale and sellRecords then
			local totalPrice, totalNum = 0, 0
			for _, record in ipairs(sellRecords) do
				totalNum = totalNum + record.quantity
				totalPrice = totalPrice + record.price*record.quantity
			end
			
			tinsert(text, format(L["Sold (Avg Price): %s (%s)"], "|cffffffff"..totalNum.."|r", (TSM:FormatTextMoney(totalPrice/totalNum) or "?")))
		end
		
		local buyRecords = TSM.Util:GetRecords("buy", itemString)
		if TSM.db.factionrealm.tooltip.purchase and buyRecords then
			local totalPrice, totalNum = 0, 0
			local specialTotalPrice
			for i=#buyRecords, 1, -1 do
				local record = buyRecords[i]
				totalNum = totalNum + record.quantity
				totalPrice = totalPrice + record.price*record.quantity
				
				if itemCount > 0 then
					if totalNum == itemCount then
						if i > 1 and not specialTotalPrice then
							specialTotalPrice = totalPrice
						end
					elseif totalNum > itemCount and not specialTotalPrice then
						specialTotalPrice = totalPrice - record.price*(totalNum - itemCount)
					end
				end
			end
			
			if not specialTotalPrice then
				tinsert(text, format(L["Purchased (Avg Price): %s (%s)"], "|cffffffff"..totalNum.."|r", (TSM:FormatTextMoney(totalPrice/totalNum) or "?")))
			else
				tinsert(text, format(L["Purchased (Smart Avg): %s (%s)"], "|cffffffff"..totalNum.."|r", (TSM:FormatTextMoney(specialTotalPrice/itemCount) or "?")))
			end
		end
		
		return text
	end
end

function TSM:GetItemString(itemLink)
	if not itemLink then return end
	local link = select(2, GetItemInfo(itemLink))
	if not link then
		if tonumber(itemLink) then
			return "item:"..itemLink..":0:0:0:0:0:0"
		else
			return
		end
	end
	local _, _, _, t, itemID, id1, id2, id3, id4, id5, id6 = strfind(link, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%-?%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
	return t..":"..itemID..":"..id1..":"..id2..":"..id3..":"..id4..":"..id5..":"..id6
end

function TSM:ItemStringToID(itemString)
	local sNum = strfind(itemString, ":")
	local eNum = strfind(itemString, ":", sNum+1)
	return tonumber(strsub(itemString, sNum+1, eNum-1))
end

local GOLD_TEXT = "|r|cffffd700g|r"
local SILVER_TEXT = "|r|cffc7c7cfs|r"
local COPPER_TEXT = "|r|cffeda55fc|r"

function TSM:FormatTextMoney(copper, color)
	if not copper or copper == 0 then return end
	color = color or "|cffffffff"
	local isNegative = false
	if copper < 0 then
		isNegative = true
		copper = abs(copper)
	end
	
	local gold = floor(copper / COPPER_PER_GOLD)
	local silver = floor((copper - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = floor(math.fmod(copper, COPPER_PER_SILVER))
	local text = ""
	
	-- Add gold
	if gold > 0 then
		if color then
			text = format("%s%s", color..gold.."|r", GOLD_TEXT)
		else
			text = format("%s%s", gold, GOLD_TEXT)
		end
	end
	
	-- Add silver
	if silver > 0 then
		if color then
			text = format("%s%s%s", text, color..silver.."|r", SILVER_TEXT)
		else
			text = format("%s%s%s", text, silver, SILVER_TEXT)
		end
	end
	
	-- Add copper if we have no silver/gold found, or if we actually have copper
	if text == "" or copper > 0 then
		if color then
			text = format("%s%s%s", text, color..copper.."|r", COPPER_TEXT)
		else
			text = format("%s%s%s", text, copper, COPPER_TEXT)
		end
	end
	
	return ((isNegative and color.."-|r" or "")..text):trim()
end


local SEC_MIN = 60
local SEC_HOUR = 60*SEC_MIN
local SEC_DAY = 24*SEC_HOUR
local SEC_MONTH = 30*SEC_DAY
local SEC_YEAR = 365*SEC_DAY

local function dateToTime(dateTimeString)
	local dateString, timeString = (" "):split(dateTimeString)
	local month, day, year = ("/"):split(dateString)
	local hour, minute, second = (":"):split(timeString)
	day = tonumber(day) or 0
	month = tonumber(month) or 0
	year = tonumber(year) or 0
	hour = tonumber(hour) or 0
	minute = tonumber(minute) or 0
	second = tonumber(second) or 0
	
	local oTime = year*SEC_YEAR + month*SEC_MONTH + day*SEC_DAY + hour*SEC_HOUR + minute*SEC_MIN + second
	
	local cYear, cMonth, cDay, cHour, cMinute, cSecond = date("%y"), date("%m"), date("%d"), date("%H"), date("%M"), date("%S");
	local cTime = cYear*SEC_YEAR + cMonth*SEC_MONTH + cDay*SEC_DAY + cHour*SEC_HOUR + cMinute*SEC_MIN + cSecond
	
	local dTime = cTime - oTime
	return time() - (cTime - oTime)
end

function TSM:ImportFromMySales()
	local isEnabled, _, isInstalled = select(4, GetAddOnInfo("MySales"))
	
	if isEnabled and MS then
		TSM:StartItemIDScan()
		TSM:Print(L["Starting to import MySales data. This requires building a large cache of item names which will take about 20-30 seconds. Please be patient."])
	elseif not isEnabled and isInstalled == "DISABLED" then
		StaticPopupDialogs["TSMAccountingMySalesImport"] = {
			text = L["MySales is currently disabled. Would you like Accounting to enable it and reload your UI so it can transfer settings?"],
			button1 = YES,
			button2 = CANCEL,
			timeout = 0,
			whileDead = true,
			hideOnEscape = false,
			OnAccept = function() EnableAddOn("MySales") ReloadUI() end,
		}
		StaticPopup_Show("TSMAccountingMySalesImport")
		for i=1, 10 do
			if _G["StaticPopup" .. i] and _G["StaticPopup" .. i].which == "TSMAccountingMySalesImport" then
				_G["StaticPopup" .. i]:SetFrameStrata("TOOLTIP")
				break
			end
		end
	end
end

local itemID
local itemIDData = {}

function TSM:StartItemIDScan()
	TSMAPI:CreateTimeDelay("itemIDScan", 0.05, TSM.ScanItemNames, 0.05)
	itemID = 1
end

local prompt = 0
function TSM:ScanItemNames()
	if itemID < 70800 then
		for i=1, 200 do
			local name, link = GetItemInfo(itemID)
			if name and link then
				itemIDData[name] = TSM:GetItemString(link)
			end
			itemID = itemID + 1
		end
		if itemID > 17700 then
			if prompt == 0 then
				prompt = 1
				TSM:Print(L["MySales Import Progress"].." - 25%")
			end
		end
		if itemID > 35400 then
			if prompt == 1 then
				prompt = 2
				TSM:Print(L["MySales Import Progress"].." - 50%")
			end
		end
		if itemID > 53100 then
			if prompt == 2 then
				prompt = 3
				TSM:Print(L["MySales Import Progress"].." - 75%")
			end
		end
	else
		TSMAPI:CancelFrame("itemIDScan")
		TSM:ReadMySalesData()
	end
end

function TSM:ReadMySalesData()
	local successfulNum, failedNum = 0, 0
	for _, data in ipairs(MS.db.char.sales or {}) do
		local _, name, price, buyer, when = MS:Deserialize(data)
		local itemString = itemIDData[name] or TSM.db.global.itemStrings[name]
		if itemString then
			TSM.Data:AddRecord("sold", itemString, price, 1, buyer, dateToTime(when))
			successfulNum = successfulNum + 1
		else
			failedNum = failedNum + 1
		end
	end
	for _, data in ipairs(MS.db.factionrealm.sales or {}) do
		local _, name, price, buyer, when = MS:Deserialize(data)
		local itemString = itemIDData[name] or TSM.db.global.itemStrings[name]
		if itemString then
			TSM.Data:AddRecord("sold", itemString, price, 1, buyer, dateToTime(when))
			successfulNum = successfulNum + 1
		else
			failedNum = failedNum + 1
		end
	end
	
	TSM.db.global.infoID = 1
	TSM:Printf(L["MySales Import Complete! Imported %s sales. Was unable to import %s sales."], successfulNum, failedNum)
end