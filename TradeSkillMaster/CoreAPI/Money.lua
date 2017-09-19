-- ------------------------------------------------------------------------------ --
--                                TradeSkillMaster                                --
--          http://www.curse.com/addons/wow/tradeskillmaster_warehousing          --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- This file contains various money APIs

local TSM = select(2, ...)
local private =  {textMoneyParts={}}
local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0|t"
TSM.GOLD_TEXT = "|cffffd70ag|r"
TSM.SILVER_TEXT = "|cffc7c7cfs|r"
TSM.COPPER_TEXT = "|cffeda55fc|r"



-- ============================================================================
-- TSMAPI Functions
-- ============================================================================

function TSMAPI:MoneyToString(money, ...)
	money = tonumber(money)
	if not money then return end
	local color, isIcon, pad, trim, disabled = nil, nil, nil, nil, nil
	for i=1, select('#', ...) do
		local opt = select(i, ...)
		if type(opt) == "string" then
			if opt == "OPT_ICON" then -- use texture icons instead of letters for denominations
				isIcon = true
			elseif opt == "OPT_PAD" then -- left-pad all but the highest denomination with zeros (i.e. "1g 00s 02c" instead of "1g 0s 2c")
				pad = true
			elseif opt == "OPT_TRIM" then -- removes any 0 valued denominations (i.e. "1g" instead of "1g 0s 0c") - 0 will still be represented as "0c"
				trim = true
			elseif opt == "OPT_DISABLE" then -- removes color from denomination text - NOTE: this is not allowed if OPT_ICON is set
				disabled = true
			elseif strmatch(strlower(opt), "^|c[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]$") then -- color the numbers
				color = opt
			else
				TSMAPI:Assert(false, "Invalid option: "..opt)
			end
		end
	end
	TSMAPI:Assert(not (isIcon and disabled), "Setting both OPT_ICON and OPT_DISABLE is not allowed")
	
	local isNegative = money < 0
	money = abs(money)
	local gold = floor(money / COPPER_PER_GOLD)
	local silver = floor((money % COPPER_PER_GOLD) / COPPER_PER_SILVER)
	local copper = floor(money % COPPER_PER_SILVER)
	local goldText, silverText, copperText = nil, nil, nil
	if isIcon then
		goldText, silverText, copperText = GOLD_ICON, SILVER_ICON, COPPER_ICON
	elseif disabled then
		goldText, silverText, copperText = "g", "s", "c"
	else
		goldText, silverText, copperText = TSM.GOLD_TEXT, TSM.SILVER_TEXT, TSM.COPPER_TEXT
	end
	
	if money == 0 then
		return private:FormatNumber(0, false, color)..copperText
	end
	
	local text = nil
	local shouldPad = false
	if trim then
		wipe(private.textMoneyParts) -- avoid creating a new table every time
		-- add gold
		if gold > 0 then
			tinsert(private.textMoneyParts, private:FormatNumber(gold, false, color)..goldText)
			shouldPad = pad
		end
		-- add silver
		if silver > 0 then
			tinsert(private.textMoneyParts, private:FormatNumber(silver, shouldPad, color)..silverText)
			shouldPad = pad
		end
		-- add copper
		if copper > 0 then
			tinsert(private.textMoneyParts, private:FormatNumber(copper, shouldPad, color)..copperText)
			shouldPad = pad
		end
		text = table.concat(private.textMoneyParts, " ")
	else
		if gold > 0 then
			text = private:FormatNumber(gold, false, color)..goldText.." "..private:FormatNumber(silver, pad, color)..silverText.." "..private:FormatNumber(copper, pad, color)..copperText
		elseif silver > 0 then
			text = private:FormatNumber(silver, false, color)..silverText.." "..private:FormatNumber(copper, pad, color)..copperText
		else
			text = private:FormatNumber(copper, false, color)..copperText
		end
	end
	
	if isNegative then
		if color then
			return color.."-|r"..text
		else
			return "-"..text
		end
	else
		return text
	end
end

function TSMAPI:MoneyFromString(value)
	-- remove any colors
	value = gsub(gsub(value:trim(), "\124c([0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])", ""), "\124r", "")
	
	-- extract gold/silver/copper values
	local gold = tonumber(strmatch(value, "([0-9]+)g"))
	local silver = tonumber(strmatch(value, "([0-9]+)s"))
	local copper = tonumber(strmatch(value, "([0-9]+)c"))
	if not gold and not silver and not copper then return end
	
	-- test that there are no extra characters (other than spaces)
	value = gsub(value, "[0-9]+g", "", 1)
	value = gsub(value, "[0-9]+s", "", 1)
	value = gsub(value, "[0-9]+c", "", 1)
	if value:trim() ~= "" then return end
	
	return ((gold or 0) * COPPER_PER_GOLD) + ((silver or 0) * COPPER_PER_SILVER) + (copper or 0)
end



-- ============================================================================
-- Helper Functions
-- ============================================================================

function private:FormatNumber(num, pad, color)
	if num < 10 and pad then
		num = "0"..num
	end
	
	if color then
		return color..num.."|r"
	else
		return num
	end
end