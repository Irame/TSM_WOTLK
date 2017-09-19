-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains code for the AuctionItemDatabase, AuctionItemDatabaseView, and AuctionRecord objects
local TSM = select(2, ...)
local private = {}



-- ============================================================================
-- API Functions
-- ============================================================================

function TSMAPI.Auction:NewRecord(...)
	return private.AuctionRecord(...)
end

function TSMAPI.Auction:NewDatabase()
	return private.AuctionRecordDatabase()
end



-- ============================================================================
-- Class Definitions
-- ============================================================================

private.AuctionRecord = setmetatable({}, {
	__call = function(self, ...)
		local new = setmetatable({}, getmetatable(self))
		local arg1 = ...
		if type(arg1) == "table" and arg1.objType == new.objType then
			local copyObj, newKeys = ...
			newKeys = newKeys or {}
			local temp = {}
			for i, key in ipairs(copyObj.dataKeys) do
				temp[i] = newKeys[key] or copyObj[key]
			end
			new:SetData(unpack(temp))
		else
			new:SetData(...)
		end
		return new
	end,

	__index = {
		objType = "AuctionRecord",
		dataKeys = {"itemLink", "texture", "stackSize", "minBid", "minIncrement", "buyout", "bid", "seller", "timeLeft", "isHighBidder", "rawItemLink"},

		SetData = function(self, ...)
			TSMAPI:Assert(select('#', ...) == #self.dataKeys)
			-- set dataKeys from the passed parameters
			for i, key in ipairs(self.dataKeys) do
				self[key] = select(i, ...)
			end
			if self.isHighBidder then
				-- this is to get around a bug in Blizzard's code where the minIncrement value will be inconsistent for auctions where the player is the highest bidder
				self.minIncrement = 0
			end
			-- generate keys from otherKeys which we can
			self.displayedBid = self.bid == 0 and self.minBid or self.bid
			self.itemDisplayedBid = floor(self.displayedBid / self.stackSize)
			self.requiredBid = self.bid == 0 and self.minBid or (self.bid + self.minIncrement)
			self.itemBuyout = (self.buyout > 0 and floor(self.buyout / self.stackSize)) or 0
			self.itemString = TSMAPI.Item:ToItemString(self.itemLink)
			self.baseItemString = TSMAPI.Item:ToBaseItemString(self.itemString)
			self.name = TSMAPI.Item:GetName(self.itemLink)
			self.itemLevel = TSMAPI.Item:GetItemLevel(self.itemLink) or 1
			self.minLevel = TSMAPI.Item:GetMinLevel(self.itemLink)
			self.quality = TSMAPI.Item:GetQuality(self.itemLink)
			self.hash = strjoin("~", self.itemLink, self.bid, self.displayedBid, self.buyout, self.timeLeft, self.stackSize)
			self.hash2 = strjoin("~", self.itemLink, self.bid, self.displayedBid, self.buyout, self.timeLeft, self.stackSize, self.seller)
			self.hash3 = strjoin("~", self.itemLink, self.minBid, self.minIncrement, self.buyout, self.bid, self.seller, self.timeLeft, self.stackSize, tostring(self.isHighBidder))
			self.isPlayer = TSMAPI.Player:IsPlayer(self.seller, true, true, true)
			-- caching of filters
			self._filterHash = nil
			self._filterResult = nil
		end,

		Filter = function(self, filterFunc, filterHash)
			if not filterFunc then
				self._filterHash = nil
				self._filterResult = true
			elseif filterHash ~= self._filterHash then
				self._filterHash = filterHash
				self._filterResult = filterFunc(self)
			end
			return self._filterResult
		end,

		ValidateIndex = function(self, auctionType, index)
			-- validate the index
			if not auctionType or not index then
				TSM:LOG_INFO("ValidateIndex failed: %s %s", tostring(auctionType), tostring(index))
				return
			end
			local texture, stackSize, minBid, minIncrement, buyout, bid, isHighBidder, seller, seller_full = TSMAPI.Util:Select({2, 3, 8, 9, 10, 11, 12, 14, 15}, GetAuctionItemInfo(auctionType, index))
			local timeLeft = GetAuctionItemTimeLeft(auctionType, index)
			local itemLink = TSMAPI.Item:GeneralizeLink(GetAuctionItemLink(auctionType, index))
			seller = TSM:GetAuctionPlayer(seller, seller_full) or "?"
			isHighBidder = isHighBidder and true or false
			local testAuction = {itemLink=itemLink, texture=texture, stackSize=stackSize, minBid=minBid, minIncrement=minIncrement, buyout=buyout, bid=bid, seller=seller, timeLeft=timeLeft, isHighBidder=isHighBidder, rawItemLink=self.rawItemLink}
			for _, key in ipairs(self.dataKeys) do
				if self[key] ~= testAuction[key] then
					TSM:LOG_INFO("ValidateIndex failed: key=%s, self[key]=%s, testAuction[key]=%s", tostring(key), tostring(self[key]), tostring(testAuction[key]))
					return
				end
			end
			return true
		end,

		DoBuyout = function(self, index)
			if self:ValidateIndex("list", index) then
				-- buy the auction
				PlaceAuctionBid("list", index, self.buyout)
				return true
			end
		end,

		DoBid = function(self, index, bid)
			if self:ValidateIndex("list", index) then
				TSMAPI:Assert((self.buyout == 0 or bid < self.buyout) and bid >= self.requiredBid)
				-- bid on the auction
				PlaceAuctionBid("list", index, bid)
				return true
			end
		end,

		DoCancel = function(self, index)
			if self:ValidateIndex("owner", index) then
				CancelAuction(index)
				return true
			end
		end,
	},
})

private.AuctionRecordDatabaseView = setmetatable({}, {
	__call = function(self, database)
		local new = setmetatable({}, getmetatable(self))
		new.database = database
		new._records = {}
		new._sorts = {}
		new._result = {}
		new._lastUpdate = 0
		new._hasResult = nil
		return new
	end,

	__index = {
		objType = "AuctionRecordDatabase",

		OrderBy = function(self, key, descending)
			tinsert(self._sorts, {key=key, descending=descending})
			self._hasResult = nil
			return self
		end,

		SetFilter = function(self, filterFunc, filterHash)
			if filterHash then
				-- this filter is already set
				if self._filterHash == filterHash then return end
				self._filterHash = filterHash
			end
			self._filterFunc = filterFunc
			self._lastUpdate = 0
			return self
		end,

		CompareRecords = function(self, a, b)
			for _, info in ipairs(self._sorts) do
				local aVal = a[info.key]
				local bVal = b[info.key]
				if info.key == "isHighBidder" then
					aVal = aVal and 1 or 0
					bVal = bVal and 1 or 0
				end
				if aVal > bVal then
					return info.descending and -1 or 1
				elseif aVal < bVal then
					return info.descending and 1 or -1
				end
			end
			return 0
		end,

		Execute = function(self)
			-- update the local copy of the results if necessary
			if self.database.updateCounter > self._lastUpdate then
				wipe(self._result)
				for _, record in ipairs(self.database.records) do
					if record:Filter(self._filterFunc, self._filterHash or self._filterFunc) then
						tinsert(self._result, record)
					end
				end
				self._lastUpdate = self.database.updateCounter
				self._hasResult = nil
			end

			if self._hasResult then return self._result end

			-- sort the result
			local function SortHelper(a, b)
				local cmp = self:CompareRecords(a, b)
				if cmp == 0 then
					return tostring(a) < tostring(b)
				end
				return cmp < 0
			end
			sort(self._result, SortHelper)
			self._hasResult = true
			return self._result
		end,

		Remove = function(self, record)
			TSMAPI:Assert(self._hasResult)
			local found = nil
			for i=1, #self._result do
				if self._result[i].hash2 == record.hash2 then
					tremove(self._result, i)
					found = true
					break
				end
			end
			if not found then return end
			-- TSMAPI:Assert(found)
			self.database:RemoveAuctionRecord(record)
		end,
	},
})

private.AuctionRecordDatabase = setmetatable({}, {
	__call = function(self)
		local new = setmetatable({}, getmetatable(self))
		new.records = {}
		new.updateCounter = 0
		new.marketValueFunc = nil
		return new
	end,

	__index = {
		objType = "AuctionRecordDatabase",

		InsertAuctionRecord = function(self, ...)
			self.updateCounter = self.updateCounter + 1
			local arg1 = ...
			if type(arg1) == "table" and arg1.objType == "AuctionRecord" then
				tinsert(self.records, arg1)
			else
				tinsert(self.records, private.AuctionRecord(...))
			end
		end,

		RemoveAuctionRecord = function(self, toRemove)
			TSMAPI:Assert(toRemove)
			self.updateCounter = self.updateCounter + 1
			for i, record in ipairs(self.records) do
				if record.hash3 == toRemove.hash3 then
					tremove(self.records, i)
					return
				end
			end
			TSMAPI:Assert(false) -- shouldn't get here
		end,

		CreateView = function(self)
			return private.AuctionRecordDatabaseView(self)
		end,

		SetMarketValueCustomPrice = function(self, marketValueFunc)
			self.marketValueFunc = marketValueFunc
		end,

		WipeRecords = function(self)
			wipe(self.records)
			self.updateCounter = self.updateCounter + 1
		end,

		RemoveRecords = function(self, toRemove)
			for i=#self.records, 1, -1 do
				if toRemove[self.records[i]] then
					tremove(self.records, i)
				end
			end
			self.updateCounter = self.updateCounter + 1
		end,
	},
})
