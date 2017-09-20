-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_AuctionDB - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_auctiondb.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Scan = TSM:NewModule("Scan", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_AuctionDB") -- loads the localization table

local professionFilters = {
	Alchemy = {
		filters = {
			"4$2", -- Consumable, Potion
			"4$3", -- Consumable, Elixir
			"4$4", -- Consumable, Flask
			"4$8", -- Consumable, Other
			"6$1", -- Trade Goods, Elemental
			"6$4", -- Trade Goods, Metal and Stone
			"6$6", -- Trade Goods, Herb
			"6$12", -- Trade Goods, Materials
			"6$13", -- Trade Goods, Other
			"8", -- Gem
		},
		items = {
			23782, -- Parts
			53065, 41814, -- Meat
			11176, -- Enchanting
			6522, 9260, -- Food and Drink
			9061, -- Parts
			19931, -- Quest
			65891, -- Mount
			31080, -- Trinket
		},
	},
	Blacksmithing = {
		filters = {
			"1", -- Weapon
			"2$4", -- Armor, Mail
			"2$5", -- Armor, Plate
			"2$6", -- Armor, Shield
			"4$6", -- Consumable, Item Enhancement
			"4$8", -- Consumable, Other
			"6$1", -- Trade Goods, Elemental
			"6$2", -- Trade Goods, Cloth
			"6$3", -- Trade Goods, Leather
			"6$4", -- Trade Goods, Metal and Stone
			"6$7", -- Trade Goods, Enchanting
			"6$12", -- Trade Goods, Materials
			"6$13", -- Trade Goods, Other
		},
		items = {
			22831, 22824, 3391, -- Elixir
			36925, 52191, 52178, -- Blue Gem
			13512, 13510, -- Flask
			52182, -- Green Gem
			8153, -- Herb
			4255, 5966, -- Leather Armor
			52193, -- Orange Gem
			3823, 2459, -- Potion
			11754, -- Quest
			52190, -- Red Gem
			27503, -- Scroll
			41245, -- Thrown
			9060, 7071, -- Parts
		},
	},
	Cooking = {
		filters = {
			"4$1", -- Consumable, Food & Drink
			"6$5", -- Trade Goods, Meat
		},
		items = {
			62673, -- Consumable, Other
			34412, -- Consumable, Consumable
			12808, 22577, -- Elemental
			3821, 785, 2452, -- Herb
			17194, -- Holiday
			8150, -- Leather
		},
	},
	Enchanting = {
		filters = {
			"1$16", -- Weapon, Wands
			"4$6", -- Consumable, Item Enhancement
			"4$8", -- Consumable, Other
			"6$1", -- Trade Goods, Elemental
			"6$7", -- Trade Goods, Enchanting
			"6$13", -- Trade Goods, Other
			"8$9", -- Gem, Prismatic
			"9$3", -- Miscellaneous, Pet
		},
		items = {
			9224, 58094, 22824, -- Elixir
			22794, 8153, 3819, 4625, 13467, 3356, 22791, 22792, 8831, 8838, -- Herb
			7392, 8170, 12810, -- Leather
			23427, 41163, 37663, 6037, 2772, 12359, 12655, -- Metal and Stone
			13446, 13444, 6048, -- Potion
			36918, -- Red Gem
			7909, 7971, 13926, 5500, -- Simple Gem
		},
	},
	Engineering = {
		filters = {
			"1$3", -- Weapon, Bows
			"1$4", -- Weapon, Guns
			"1$12", -- Weapon, Misc
			"1$15", -- Weapon, Crossbows
			"2$1", -- Armor, Misc
			"2$2", -- Armor, Cloth
			"2$2", -- Armor, Leather
			"3$4", -- Container, Engineering Bag
			"3$9", -- Container, Tackle Box
			"4$8", -- Consumable, Other
			"6$1", -- Trade Goods, Elemental
			"6$2", -- Trade Goods, Cloth
			"6$3", -- Trade Goods, Leather
			"6$4", -- Trade Goods, Metal and Stone
			"6$9", -- Trade Goods, Parts
			"6$10", -- Trade Goods, Devices
			"6$11", -- Trade Goods, Explosives
			"6$12", -- Trade Goods, Material
			"6$13", -- Trade Goods, Other
			"8$8", -- Gem, Simple
			"9$1", -- Miscellaneous, Junk
			"9$3", -- Miscellaneous, Pet
			"9$4", -- Miscellaneous, Holiday
			"9$6", -- Miscellaneous, Mount
		},
		items = {
			10644, -- Recipe, Alchemy
			10713, -- Recipe, Blacksmithing
			33092, 33093, 22829, 22832, -- Potion
			18168, -- Shield
			60858, 159, 62654, -- Food & Drink
			44741, -- Armor, Mail
			44742, -- Armor, Plate
			10592, -- Elixir
			8153, 13467, -- Herb
			20816, -- Jewelcrafting
			52191, 36924, 23438, -- Blue Gem
			34052, 22449, 22448, 22445, -- Enchanting
			52192, 36933, 23437, 23079, 52182, -- Green Gem
			62778, -- Meat
			36930, 23439, 21929, 52181, -- Orange Gem
			23441, 36927, -- Purple Gem
			52190, 23436, 36918, 23077, -- Red Gem
			36922, 36921, 23440, 52179, 23112, 36920, -- Yellow Gem
		},
	},
	Inscription = {
		filters = {
			"2$1", -- Armor, Misc
			"4$7", -- Consumable, Scroll
			"4$8", -- Consumable, Other
			"5", -- Glyph
			"6$1", -- Trade Goods, Elemental
			"6$6", -- Trade Goods, Herb
			"6$9", -- Trade Goods, Parts
			"6$13", -- Trade Goods, Other
			"6$14", -- Trade Goods, Item Enhancement
			"10", -- Quest
		},
		items = {
			64670, -- ???
		},
	},
	Jewelcrafting = {
		filters = {
			"1$11", -- Weapon, Fist Weapons
			"2$1", -- Armor, Misc
			"2$2", -- Armor, Cloth
			"6$1", -- Trade Goods, Elemental
			"6$4", -- Trade Goods, Metal and Stone
			"6$8", -- Trade Goods, Jewelcrafting
			"6$9", -- Trade Goods, Parts
			"6$12", -- Trade Goods, Materials
			"6$13", -- Trade Goods, Other
			"8", -- Gem
		},
		items = {
			3391, -- Elixir
			34052, 11178, 52555, 34054, 11083, 11137, -- Enchanting
			27860, -- Food & Drink
			6149, 3827, -- Potion
			18335, 11754, -- Quest
			3824, 41367, 42420, 42421, -- Consumable, Other
			52304, -- Consumable, Consumable
		},
	},
	Leatherworking = {
		filters = {
			"2$2$9", -- Armor, Cloth, Back
			"2$3", -- Armor, Leather
			"2$4", -- Armor, Mail
			"3$6", -- Container, Mining Bag
			"3$7", -- Container, Leatherworking Bag
			"3$8", -- Container, Inscription Bag
			"4$6", -- Consumable, Item Enhancement
			"4$8", -- Consumable, Other
			"6$1", -- Trade Goods, Elemental
			"6$2", -- Trade Goods, Cloth
			"6$3", -- Trade Goods, Leather
			"6$12", -- Trade Goods, Materials
			"6$13", -- Trade Goods, Other
			"8$8", -- Gem, Simple
			"9$1", -- Miscellaneous, Junk
		},
		items = {
			3390, 2457, 3383, 3389, -- Elixir
			34057, 22450, 22448, 34055, 22445, -- Enchanting
			8153, 3356, -- Herb
			12809, 2840, -- Metal and Stone
			61981, 7071, -- Part
			5633, 2459, -- Potion
			12607, 11754, 18258, -- Quest
			17056, -- Reagant
			5081, 34105, -- Container, Bag
			34086, 25653, -- Armor, Misc
		},
	},
	Tailoring = {
		filters = {
			"2$1$1", -- Armor, Misc, Head
			"2$1$3", -- Armor, Misc, Shirt
			"2$2", -- Armor, Cloth
			"3$1", -- Container, Bag
			"3$2", -- Container, Herb Bag
			"3$3", -- Container, Enchanting Bag
			"3$5", -- Container, Gem Bag
			"4$6", -- Consumable, Item Enhancement
			"6$1", -- Trade Goods, Elemental
			"6$2", -- Trade Goods, Cloth
			"6$3", -- Trade Goods, Leather
			"6$7", -- Trade Goods, Enchanting
			"6$12", -- Trade Goods, Materials
			"6$13", -- Trade Goods, Other
			"8$8", -- Gem, Simple
			"9$6", -- Miscellaneous, Junk
		},
		items = {
			3383, -- Elixir
			36925, -- Blue Gem
			36934, -- Green Gem
			13468, 22794, 36908, 8153, 4625, 8831, -- Herb
			12360, 3577, 12809, 6037, -- Metal and Stone
			36930, -- Orange Gem
			7071, -- Part
			929, 3827, 6048, -- Potion
			36919, -- Red Gem
			3824, 3829, -- Consumable, Other
			36922, 23112, -- Yellow Gem
			18258, -- Quest
		},
	},
}

local scanQueue, numFilters, isTextGoing, currFilterNum, currPageNum, isScanning

local missing = -1
local function PopulateItemInfoCache()
	local num = 0
	for _, data in pairs(professionFilters) do
		for _, itemID in ipairs(data.items) do
			if not GetItemInfo(itemID) then
				num = num + 1
			end
		end
	end
	if num == 0 or num == missing then
		TSMAPI:CancelFrame("adbProfessionCacheDelay")
	else
		missing = num
	end
end

do
	TSMAPI:CreateTimeDelay("adbProfessionCacheDelay", 0.5, PopulateItemInfoCache, 0.5)
end

local function GetProfessionFilters()
	local filters = {}
	local items1, items2 = {}, {}
	local categories1, categories2, categories3 = {}, {}, {}
	
	-- stage 1
	for profession, checked in pairs(TSM.db.profile.scanSelections) do
		if checked and professionFilters[profession] then
			for _, filter in ipairs(professionFilters[profession].filters) do
				categories1[filter:trim()] = true
			end
			for _, itemID in ipairs(professionFilters[profession].items) do
				items1[itemID] = true
			end
		end
	end
	
	-- stage 2
	for filter in pairs(categories1) do
		local class, subClass, invSlot = ("$"):split(filter)
		if invSlot then
			if not (categories1[class.."$"..subClass] or categories1[class]) then
				categories2[filter] = true
			end
		elseif subClass then
			if not categories1[class] then
				categories2[filter] = true
			end
		else
			categories2[filter] = true
		end
	end
	
	-- stage 3
	for i=1, #{GetAuctionItemClasses()} do
		if not categories2[tostring(i)] then
			local hasAllSubClasses = #{GetAuctionItemSubClasses(i)} > 0
			for j=1, #{GetAuctionItemSubClasses(i)} do
				if not categories2[tostring(i).."$"..tostring(j)] then
					hasAllSubClasses = false
				end
			end
			
			if hasAllSubClasses then
				for j=1, #{GetAuctionItemSubClasses(i)} do
					categories2[tostring(i).."$"..tostring(j)] = nil
				end
				categories2[tostring(i)] = true
			end
		end
	end
	
	-- stage 4
	local classIndexLookup, subClassIndexLookup = {}, {}
	for i, class in ipairs({GetAuctionItemClasses()}) do
		classIndexLookup[class] = tostring(i)
		for j, subClass in ipairs({GetAuctionItemSubClasses(i)}) do
			subClassIndexLookup[class.."/"..subClass] = tostring(j)
		end
	end
	for itemID in pairs(items1) do
		local _, link, _, _, _, iType, iSubType = GetItemInfo(itemID)
		if link and iType then
			local class = classIndexLookup[iType]
			local subClass = iSubType and subClassIndexLookup[iType.."/"..iSubType] or "xxx"
			if not ((class and categories2[class]) or (class and subClass and categories2[class.."$"..subClass])) then
				items2[itemID] = link
			end
		end
	end
	
	-- stage 5
	for _, link in pairs(items2) do
		tinsert(filters, link)
	end
	for index in pairs(categories2) do
		local class, subClass, invSlot = ("$"):split(index)
		local filter = {class=class, subClass=subClass, invType=invSlot}
		tinsert(filters, filter)
	end
	
	return filters
end

function Scan:StartScanningText()
	if isTextGoing then return end
	isTextGoing = true
	local function UpdateText()
		local text = L["%s - Scanning page %s/%s of filter %s/%s"]
		local page, totalPages = TSMAPI:GetPageProgress()
	
		TSM.GUI:UpdateStatus(format(text, isScanning, page, totalPages, currFilterNum, numFilters))
	end
	
	TSMAPI:CreateTimeDelay("adbScanStatusText", 0, UpdateText, 0.2)
end

function Scan:StartProfessionScan()
	scanQueue = GetProfessionFilters()
	numFilters = #scanQueue
	currFilterNum = 1
	isScanning = "Profession Scan"
	
	Scan:StartScanningText()
	TSMAPI:StartScan(scanQueue, function(...) Scan:OnScanCallback(...) end, {})
end

function Scan:StartFullScan()
	numFilters = 1
	currFilterNum = 1
	isScanning = "Full Scan"
	
	Scan:StartScanningText()
	TSMAPI:StartScan({{name=""}}, function(...) Scan:OnScanCallback(...) end, {})
end

function Scan:StartGetAllScan()
	TSM.db.profile.lastGetAll = time()
	isScanning = "GetAll Scan"
	TSMAPI:StartGetAllScan(function(...) Scan:OnScanCallback(...) end)
end

function Scan:IsScanning()
	return isScanning
end

function Scan:OnScanCallback(event, arg1, arg2)
	if event == "GETALL_WAITING" then
		local progress = floor((arg1 / 20) * 100 + 0.5)
		TSM.GUI:UpdateStatus(L["Waiting for data..."], nil, progress)
	elseif event == "GETALL_UPDATE" then
		local progress = floor((TSMAPI:SafeDivide(arg1,arg2)) * 100 + 0.5)
		TSM.GUI:UpdateStatus(L["Scanning..."], progress, 0)
	elseif event == "SCAN_STATUS_UPDATE" then
		local progress = floor((TSMAPI:SafeDivide(arg1,arg2)) * 100 + 0.5)
		TSM.GUI:UpdateStatus(nil, nil, progress)
	elseif event == "QUERY_FINISHED" then
		local progress = floor(TSMAPI:SafeDivide((numFilters - arg1.left),numFilters) * 100 + 0.5)
		currFilterNum = numFilters - arg1.left + 1
		TSM.GUI:UpdateStatus(nil, progress)
	elseif event == "SCAN_COMPLETE" then
		Scan:ProcessScanData(arg1)
		Scan:DoneScanning()
	elseif event == "SCAN_INTERRUPTED" then
		TSM:Print(L["Scan interrupted."])
		Scan:DoneScanning()
	elseif event == "GETALL_BUG" then
		TSM:Print(L["|cffff0000WARNING:|r As of 4.0.1 there is a bug with GetAll scans only scanning a maximum of 42554 auctions from the AH which is less than your auction house currently contains. As a result, thousands of items may have been missed. Please use regular scans until blizzard fixes this bug."])
	end
end

function Scan:DoneScanning()
	TSM.GUI:UpdateStatus(L["Done Scanning"], 100)
	TSMAPI:CancelFrame("adbScanStatusText")
	isTextGoing = nil
	numFilters = nil
	scanQueue = nil
	currFilterNum = nil
	isScanning = nil
end

function Scan:ProcessScanData(scanData)
	local data = {}
	local test = 0
	
	for _, obj in pairs(scanData) do
		local itemID = obj:GetItemID()
		local quantity, recordsQuantity, minBuyout = 0, 0, 0
		local records = {}
		for _, record in ipairs(obj.records) do
			local itemBuyout = record:GetItemBuyout()
			if itemBuyout and (itemBuyout < minBuyout or minBuyout == 0) then
				minBuyout = itemBuyout
			end
			if itemBuyout then
				recordsQuantity = recordsQuantity + record.count
				tinsert(records, {buyout = itemBuyout, count = record.count})
			end
			quantity = quantity + record.count
		end
		data[itemID] = {records=records, minBuyout=minBuyout, quantity=quantity, recordsQuantity=recordsQuantity}
		test = test + 1
	end
	
	if isScanning == "GetAll Scan" then
		TSM:Print(L["It is strongly recommended that you reload your ui (type '/reload') after running a GetAll scan. Otherwise, any other scans (Post/Cancel/Search/etc) will be much slower than normal."])
	end
	
	if isScanning == "GetAll Scan" or isScanning == "Full Scan" then
		TSM.db.factionrealm.lastCompleteScan = time()
	end
	
	TSM.Data:ProcessData(data) -- fix queue param?
end

function Scan:ProcessImportedData(auctionData)
	local data = {}
	for itemID, auctions in pairs(auctionData) do
		local quantity, recordsQuantity, minBuyout, records = 0, 0, 0, {}
		for _, auction in ipairs(auctions) do
			local itemBuyout, count = unpack(auction)
			if itemBuyout and (itemBuyout < minBuyout or minBuyout == 0) then
				minBuyout = itemBuyout
			end
			if itemBuyout then
				recordsQuantity = recordsQuantity + count
				tinsert(records, {buyout = itemBuyout, count = count})
			end
			quantity = quantity + record.count
		end
		data[itemID] = {records=records, minBuyout=minBuyout, quantity=quantity, recordsQuantity=recordsQuantity}
	end
	TSM.db.factionrealm.lastCompleteScan = time()
	TSM.Data:ProcessData(data)
end