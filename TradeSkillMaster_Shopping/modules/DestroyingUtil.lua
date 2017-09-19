local TSM = select(2, ...)
local DestroyingUtil = TSM:NewModule("DestroyingUtil", "AceEvent-3.0")
local destroyingData = TSMAPI.DestroyingData

function DestroyingUtil:GetData(mode, filter1, filter2)
	local data = destroyingData[mode]
	for i=1, #destroyingData[mode] do
		if destroyingData[mode][i].desc == filter1 then
			for itemID, iData in pairs(destroyingData[mode][i]) do
				if iData.name == filter2 then
					return {itemID=itemID, data=iData, vendorTrade=destroyingData.vendorTrades[itemID]}
				end
			end
		end
	end
end

function DestroyingUtil:GetScanData(mode, itemData, queue)
	if mode == "mill" then
		tinsert(queue, {name=itemData.name})
		
		local pigmentName = GetItemInfo(itemData.pigment)
		if pigmentName then
			tinsert(queue, {name=pigmentName})
		end
		
		for i=1, #itemData.herbs do
			local herbName = GetItemInfo(itemData.herbs[i].itemID)
			if herbName then
				tinsert(queue, {name=herbName})
			end
		end
	elseif mode == "prospect" then
		for i=1, #itemData.gems do
			local gemName = GetItemInfo(itemData.gems[i])
			if gemName then
				tinsert(queue, {name=gemName})
			end
		end
		
		for i=1, #itemData.ore do
			local oreName = GetItemInfo(itemData.ore[i].itemID)
			if oreName then
				tinsert(queue, {name=oreName})
			end
		end
	elseif mode == "disenchant" then
		tinsert(queue, {name=itemData.name})
	
		local function GetItemClass(str)
			for i, class in ipairs({GetAuctionItemClasses()}) do
				if str == class then
					return i
				end
			end
		end
	
		for classStr, classData in pairs(itemData.itemTypes) do
			class = GetItemClass(classStr)
			for quality in pairs(classData) do
				local uniqueString = itemData.minLevel.."$"..itemData.maxLevel.."$"..class.."$"..quality
				tinsert(queue, {minLevel=itemData.minLevel, maxLevel=itemData.maxLevel, class=class, quality=quality, uniqueString=uniqueString})
			end
		end
	elseif mode == "transform" then
		tinsert(queue, {name=itemData.name})
		
		local otherItemName = GetItemInfo(itemData.otherItemID)
		if otherItemName then
			tinsert(queue, {name=otherItemName})
		end
	end
end

function DestroyingUtil:IsEvenStack(mode, itemID, stackSize)
	if stackSize % 5 == 0 or mode == "transform" or mode == "disenchant" then return true end
	
	for i=1, #destroyingData[mode] do
		for item, data in pairs(destroyingData[mode][i]) do
			if item ~= "desc" then
				for _, v in ipairs(data.herbs or data.ore) do
					if v.itemID == itemID then
						return false
					end
				end
			end
		end
	end
	
	return true
end

function DestroyingUtil:GetFilters(itemID)
	for i=1, #destroyingData.mill do
		if destroyingData.mill[i][itemID] then
			return "mill", destroyingData.mill[i].desc, destroyingData.mill[i][itemID].name
		end
	end
	
	for i=1, #destroyingData.prospect do
		for item, data in pairs(destroyingData.prospect[i]) do
			if item ~= "desc" then
				for _, gemID in ipairs(data.gems) do
					if gemID == itemID then
						return "prospect", destroyingData.prospect[i].desc, data.name
					end
				end
			end
		end
	end
	
	for i=1, #destroyingData.disenchant do
		if destroyingData.disenchant[i][itemID] then
			return "disenchant", destroyingData.disenchant[i].desc, destroyingData.disenchant[i][itemID].name
		end
	end
	
	for i=1, #destroyingData.transform do
		if destroyingData.transform[i][itemID] then
			return "transform", destroyingData.transform[i].desc, destroyingData.transform[i][itemID].name
		end
	end
end