-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains general Util APIs

local private = {lastHardwareEvent=0}
local MAGIC_CHARACTERS = {'[', ']', '(', ')', '.', '+', '-', '*', '?', '^', '$'}



-- ============================================================================
-- TSMAPI Functions - Lua Util
-- ============================================================================

function TSMAPI.Util:WipeOrCreateTable(tbl)
	if not tbl then
		return {}
	end
	wipe(tbl)
	return tbl
end

function TSMAPI.Util:Select(positions, ...)
	if type(positions) == "number" then
		return select(positions, ...)
	elseif type(positions) == "table" then
		return private:SelectHelper(positions, ...)
	else
		error(format("Bad argument #1. Expected number or table, got %s", type(positions)))
	end
end

function TSMAPI.Util:SafeStrSplit(str, sep)
	local parts = {}
	local s = 1
	local sepLength = #sep
	while true do
		local e = strfind(str, sep, s)
		if not e then
			tinsert(parts, strsub(str, s))
			break
		end
		tinsert(parts, strsub(str, s, e - 1))
		s = e + sepLength
	end
	return parts
end

function TSMAPI.Util:StrEscape(str)
	str = gsub(str, "%%", "\001")
	for _, char in ipairs(MAGIC_CHARACTERS) do
		str = gsub(str, "%"..char, "%%"..char)
	end
	str = gsub(str, "\001", "%%%%")
	return str
end

function TSMAPI.Util:Round(value, sig)
	sig = sig or 1
	return floor((value / sig) + 0.5) * sig
end



-- ============================================================================
-- TSMAPI Functions - WoW Util
-- ============================================================================

function TSMAPI.Util:ShowStaticPopupDialog(name)
	StaticPopupDialogs[name].preferredIndex = 4
	StaticPopup_Show(name)
	for i=1, 100 do
		if _G["StaticPopup" .. i] and _G["StaticPopup" .. i].which == name then
			_G["StaticPopup" .. i]:SetFrameStrata("TOOLTIP")
			break
		end
	end
end

function TSMAPI.Util:SafeTooltipLink(link)
	if strmatch(link, "p:") then
		link = TSMAPI.Item:GetLink(link)
	end
	if strmatch(link, "battlepet") then
		local _, speciesID, level, breedQuality, maxHealth, power, speed, battlePetID = strsplit(":", link)
		BattlePetToolTip_Show(tonumber(speciesID), tonumber(level) or 0, tonumber(breedQuality) or 0, tonumber(maxHealth) or 0, tonumber(power) or 0, tonumber(speed) or 0, gsub(gsub(link, "^(.*)%[", ""), "%](.*)$", ""))
	elseif strmatch(link, "currency") then
		local currencyID = strmatch(link, "currency:(%d+)")
		GameTooltip:SetCurrencyByID(currencyID)
	else
		link = TSMAPI.Item:GetLink(link)
		GameTooltip:SetHyperlink(link)
	end
end

function TSMAPI.Util:SafeItemRef(link)
	if type(link) ~= "string" then return end
	-- extract the Blizzard itemString for both items and pets
	local blizzItemString = strmatch(link, "^\124c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]\124H(item:[^\124]+)\124.+$")
	blizzItemString = blizzItemString or strmatch(link, "^\124c[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]\124H(battlepet:[^\124]+)\124.+$")
	if blizzItemString then
		SetItemRef(blizzItemString, link)
	end
end

function TSMAPI.Util:UseHardwareEvent()
	if private.lastHardwareEvent == GetTime() then return end
	private.lastHardwareEvent = GetTime()
	return true
end

function TSMAPI.Util:CalculateHash(str)
	if not str then return end
	-- calculate the hash using the djb2 algorithm (http://www.cse.yorku.ca/~oz/hash.html)
	local hash = 5381
	local maxValue = 2 ^ 24
	for i=1, #str do
		hash = (hash * 33 + strbyte(str, i)) % maxValue
	end
	return hash
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:SelectHelper(positions, ...)
	if #positions == 0 then return end
	return select(tremove(positions, 1), ...), private:SelectHelper(positions, ...)
end
