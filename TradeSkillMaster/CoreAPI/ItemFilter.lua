-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--                http://www.curse.com/addons/wow/tradeskill-master               --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains APIs for advanced item filtering

local TSM = select(2, ...)
local private = {}



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI.ItemFilter:Parse(str)
	local filterInfo = {}
	for i, part in ipairs({("/"):split(str)}) do
		part = part:trim()
		if i == 1 then
			-- first part must be a filter string
			filterInfo.str = part
		elseif part == "" then
			-- ignore an empty part
		elseif tonumber(part) then
			if filterInfo.maxLevel then
				-- already have min / max level
				return
			elseif filterInfo.minLevel then
				filterInfo.maxLevel = tonumber(part)
			else
				filterInfo.minLevel = tonumber(part)
			end
		elseif tonumber(strmatch(part, "^i(%d+)")) then
			if filterInfo.maxILevel then
				-- already have min / max item level
				return
			elseif filterInfo.minILevel then
				filterInfo.maxILevel = tonumber(strmatch(part, "^i(%d+)"))
			else
				filterInfo.minILevel = tonumber(strmatch(part, "^i(%d+)"))
			end
		elseif TSMAPI.Item:GetClassIdFromClassString(part) then
			filterInfo.class = TSMAPI.Item:GetClassIdFromClassString(part)
		elseif TSMAPI.Item:GetSubClassIdFromSubClassString(part, filterInfo.class) then
			filterInfo.subClass = TSMAPI.Item:GetSubClassIdFromSubClassString(part, filterInfo.class)
		elseif TSMAPI.Item:GetInventorySlotIdFromInventorySlotString(part) then
			filterInfo.invType = TSMAPI.Item:GetInventorySlotIdFromInventorySlotString(part)
		elseif private:ItemRarityToIndex(part) then
			filterInfo.rarity = private:ItemRarityToIndex(part)
		elseif TSMAPI:MoneyFromString(part) then
			if filterInfo.minPrice then
				filterInfo.maxPrice = TSMAPI:MoneyFromString(part)
			else
				filterInfo.minPrice = TSMAPI:MoneyFromString(part)
			end
		elseif strlower(str) == "usable" then
			if filterInfo.usableOnly then return end
			filterInfo.usableOnly = true
		elseif strlower(str) == "exact" then
			if filterInfo.exactOnly then return end
			filterInfo.exactOnly = true
		elseif strlower(str) == "even" then
			if filterInfo.evenOnly then return end
			filterInfo.evenOnly = true
		else
			-- invalid part
			return
		end
	end

	-- setup some defaults
	filterInfo.str = filterInfo.str or ""
	filterInfo.escapedStr = TSMAPI.Util:StrEscape(filterInfo.str)
	filterInfo.minLevel = filterInfo.minLevel or 0
	filterInfo.maxLevel = filterInfo.maxLevel or math.huge
	filterInfo.minILevel = filterInfo.minILevel or 0
	filterInfo.maxILevel = filterInfo.maxILevel or math.huge
	filterInfo.minPrice = filterInfo.minPrice or 0
	filterInfo.maxPrice = filterInfo.maxPrice or math.huge
	return filterInfo
end

function TSMAPI.ItemFilter:MatchesFilter(filterInfo, item, price)
	-- check the name
	local name = TSMAPI.Item:GetName(item)
	if not name or not strfind(strlower(name), filterInfo.escapedStr) then
		return
	elseif filterInfo.exactOnly and name ~= filterInfo.str then
		return
	end

	-- check the rarity
	local quality = TSMAPI.Item:GetQuality(item)
	if filterInfo.rarity and quality ~= filterInfo.rarity then
		return
	end

	-- check the item level
	local ilvl = TSMAPI.Item:GetItemLevel(item)
	if ilvl < filterInfo.minILevel or ilvl > filterInfo.maxILevel then
		return
	end

	-- check the required level
	local lvl = TSMAPI.Item:GetMinLevel(item)
	if lvl < filterInfo.minLevel or lvl > filterInfo.maxLevel then
		return
	end

	-- check the item class
	local class = TSMAPI.Item:GetClassId(item) or 0
	if filterInfo.class and class ~= filterInfo.class then
		return
	end

	-- check the item subclass
	local subClass = TSMAPI.Item:GetSubClassId(item) or 0
	if filterInfo.subClass and subClass ~= filterInfo.subClass then
		return
	end

	-- check the equip slot
	local equipSlot = TSMAPI.Item:GetEquipSlot(item)
	local invType = _G[equipSlot] and TSMAPI.Item:GetInventorySlotIdFromInventorySlotString(_G[equipSlot])
	if filterInfo.invType and invType ~= filterInfo.invType then
		return
	end

	-- check the price
	price = price or 0
	if price < filterInfo.minPrice or price > filterInfo.maxPrice then
		return
	end

	-- it passed!
	return true
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:ItemRarityToIndex(str)
	for i = 0, 4 do
		local text =  _G["ITEM_QUALITY"..i.."_DESC"]
		if strlower(str) == strlower(text) then
			return i
		end
	end
end
