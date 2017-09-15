-- ------------------------------------------------------------------------------ --
--                           TradeSkillMaster_Additions                           --
--           http://www.curse.com/addons/wow/tradeskillmaster_additions           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local AuctionSales = TSM:NewModule("AuctionSales", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Additions") -- loads the localization table

function AuctionSales:OnEnable()
	ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", AuctionSales.FilterSystemMsg)
	AuctionSales:RegisterEvent("AUCTION_OWNED_LIST_UPDATE")
end

function AuctionSales:OnDisable()
	-- do disable stuff
	ChatFrame_RemoveMessageEventFilter("CHAT_MSG_SYSTEM", AuctionSales.FilterSystemMsg)
	AuctionSales:UnregisterEvent("AUCTION_OWNED_LIST_UPDATE")
end

function AuctionSales:AUCTION_OWNED_LIST_UPDATE()
	wipe(TSM.db.char.auctionPrices)
	wipe(TSM.db.char.auctionMessages)
	
	local auctionPrices = {}
	for i=1, GetNumAuctionItems("owner") do
		local link = GetAuctionItemLink("owner", i)
		local itemString = TSMAPI:GetItemString(link)
		local name, _, quantity, _, _, _, _, _, buyout, _, _, _, wasSold, _, wasSold_54 = GetAuctionItemInfo("owner", i)
	if select(4, GetBuildInfo()) == 50400 then wasSold = wasSold_54 end
		if wasSold == 0 and itemString then
			if buyout and buyout > 0 then
				auctionPrices[link] = auctionPrices[link] or {name=name}
				tinsert(auctionPrices[link], {buyout=buyout, quantity=quantity})
			end
		end
	end
	for link, auctions in pairs(auctionPrices) do
		-- make sure all auctions are the quantity
		local quantity = auctions[1].quantity
		for i=2, #auctions do
			if quantity ~= auctions[i].quantity then
				quantity = nil
				break
			end
		end
		if quantity then
			local prices = {}
			for _, data in ipairs(auctions) do
				tinsert(prices, data.buyout)
			end
			sort(prices)
			TSM.db.char.auctionPrices[link] = prices
			TSM.db.char.auctionMessages[format(ERR_AUCTION_SOLD_S, auctions.name)] = link
		end
	end
end

local prevLineID, prevLineResult
function AuctionSales.FilterSystemMsg(_, _, msg, ...)
	local lineID = select(10, ...)
	if lineID ~= prevLineID then
		prevLineID = lineID
		prevLineResult = nil
		local link = TSM.db.char.auctionMessages and TSM.db.char.auctionMessages[msg]
		if not link then return end
		
		local price = tremove(TSM.db.char.auctionPrices[link], 1)
		local numAuctions = #TSM.db.char.auctionPrices[link]
		if not price then
			-- couldn't determine the price, so just replace the link
			prevLineResult = format(ERR_AUCTION_SOLD_S, link)
			return nil, prevLineResult, ...
		end
		
		if numAuctions == 1 then -- this was the last auction
			TSM.db.char.auctionMessages[msg] = nil
		end
		prevLineResult = format(L["Your auction of %s has sold for %s!"], link, TSMAPI:FormatTextMoney(price, "|cffffffff"))
		return nil, prevLineResult, ...
	end
end