-- random lookup tables and other functions that don't have a home go in here

local TSM = select(2, ...)
local ItemData = TSM:NewModule("ItemData", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster")

TSMAPI.EquipLocLookup = {
	[INVTYPE_HEAD]=1, [INVTYPE_NECK]=2, [INVTYPE_SHOULDER]=3, [INVTYPE_BODY]=4, [INVTYPE_CHEST]=5,
	[INVTYPE_WAIST]=6, [INVTYPE_LEGS]=7, [INVTYPE_FEET]=8, [INVTYPE_WRIST]=9, [INVTYPE_HAND]=10,
	[INVTYPE_FINGER]=11, [INVTYPE_TRINKET]=12, [INVTYPE_CLOAK]=13, [INVTYPE_HOLDABLE]=14,
	[INVTYPE_WEAPONMAINHAND]=15, [INVTYPE_ROBE]=16, [INVTYPE_TABARD]=17, [INVTYPE_BAG]=18,
	[INVTYPE_2HWEAPON]=19, [INVTYPE_RANGED]=20, [INVTYPE_SHIELD]=21, [INVTYPE_WEAPON]=22
}


local priceSourceFuncs = {}
local priceSourceLabels = {}

function ItemData:OnEnable()
	-- Auctioneer
	if select(4, GetAddOnInfo("Auc-Advanced")) == 1 and AucAdvanced then
		if AucAdvanced.Modules.Util.Appraiser and AucAdvanced.Modules.Util.Appraiser.GetPrice then
			TSMAPI:AddPriceSource("AucAppraiser",L["Auctioneer - Appraiser"], function(itemLink, itemID) return AucAdvanced.Modules.Util.Appraiser.GetPrice(itemLink) end)
		end
		if AucAdvanced.Modules.Util.SimpleAuction and AucAdvanced.Modules.Util.SimpleAuction.Private.GetItems then
			TSMAPI:AddPriceSource("AucMinBuyout",L["Auctioneer - Minimum Buyout"], function(itemLink, itemID) return select(6, AucAdvanced.Modules.Util.SimpleAuction.Private.GetItems(itemLink)) end)
		end
		if AucAdvanced.API.GetMarketValue then
			TSMAPI:AddPriceSource("AucMarket",L["Auctioneer - Market Value"], function(itemLink, itemID) return AucAdvanced.API.GetMarketValue(itemLink) end)
		end
	end
	-- Auctionator
	if select(4, GetAddOnInfo("Auctionator")) == 1 and Atr_GetAuctionBuyout then
		TSMAPI:AddPriceSource("AtrValue",L["Auctionator - Auction Value"], function(itemLink, itemID) return Atr_GetAuctionBuyout(itemLink) end)
	end
	-- ItemAuditor
	if select(4, GetAddOnInfo("ItemAuditor")) == 1 and IAapi then
		TSMAPI:AddPriceSource("IACost",L["ItemAuditor - Cost"], function(itemLink, itemID) return max(select(2, IAapi.GetItemCost(itemLink)), (select(11, GetItemInfo(itemLink)) or 0)) end)
	end
	
	-- TheUndermineJournal
	if select(4, GetAddOnInfo("TheUndermineJournal")) == 1 and TUJMarketInfo then
		TSMAPI:AddPriceSource("TUJMarket","TUJ RE - Market Price", function(itemLink, itemID) return itemID~=0 and (TUJMarketInfo(itemID) or {}).market end)
		TSMAPI:AddPriceSource("TUJMean","TUJ RE - Mean", function(itemLink, itemID) return itemID~=0 and (TUJMarketInfo(itemID) or {}).marketaverage end)
		TSMAPI:AddPriceSource("TUJGEMarket","TUJ GE - Market Average", function(itemLink, itemID) return itemID~=0 and (TUJMarketInfo(itemID) or {}).gemarketaverage end)
		TSMAPI:AddPriceSource("TUJGEMedian","TUJ GE - Market Median", function(itemLink, itemID) return itemID~=0 and (TUJMarketInfo(itemID) or {}).gemarketmedian end)
	end
	
	-- TheUndermineJournalGE
	if select(4, GetAddOnInfo("TheUndermineJournalGE")) == 1 and TUJMarketInfo then
		TSMAPI:AddPriceSource("TUJGEMarket","TUJ GE - Market Average", function(itemLink, itemID) return itemID~=0 and (TUJMarketInfo(itemID) or {}).marketaverage end)
		TSMAPI:AddPriceSource("TUJGEMedian","TUJ GE - Market Median", function(itemLink, itemID) return itemID~=0 and (TUJMarketInfo(itemID) or {}).marketmedian end)
	end
	
	-- Crafting
	if select(4, GetAddOnInfo("TradeSkillMaster_Crafting")) == 1 then
		TSMAPI:AddPriceSource("Crafting",L["Crafting Cost"], function(itemLink, itemID) return TSMAPI:GetData("craftingcost", itemID) end)
	end
	
	-- Vendor
	TSMAPI:AddPriceSource("Vendor",L["Vendor Sell Price"], function(itemLink, itemID) return select(11, GetItemInfo(itemLink)) or 0 end)
end

-- func(itemLink,itemID) returns value
function TSMAPI:AddPriceSource(key, label, func)
	assert(type(key) == "string", "key="..tostring(key))
	assert(type(label) == "string", "label="..tostring(label))
	
	priceSourceFuncs[key] = func
	priceSourceLabels[key] = label
end

function TSMAPI:GetPriceSources()
	return priceSourceLabels
end

function TSMAPI:GetItemValue(link, source)
	if not priceSourceFuncs[source] then return nil, "invalid source" end

	local itemLink = select(2, GetItemInfo(link)) or link
	local itemID = TSMAPI:GetItemID(itemLink)

	if not (itemLink or itemID) then return nil, "missing item" end
	
	return priceSourceFuncs[source](itemLink, itemID)
end