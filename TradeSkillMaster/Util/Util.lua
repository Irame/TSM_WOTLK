-- This file contains all the utility APIs

local TSM = select(2, ...)
local lib = TSMAPI

local delays = {}

local GOLD_TEXT = "|cffffd700g|r"
local SILVER_TEXT = "|cffc7c7cfs|r"
local COPPER_TEXT = "|cffeda55fc|r"
local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:0|t"

--- Attempts to get the itemID from a given itemLink/itemString.
-- @param itemLink The link or itemString for the item.
-- @param ignoreGemID If true, will not attempt to get the equivalent id for the item (ie for old gems where there are multiple ids for a single item).
-- @return Returns the itemID as the first parameter. On error, will return nil as the first parameter and an error message as the second.
function lib:GetItemID(itemLink, ignoreGemID)
	if not itemLink or type(itemLink) ~= "string" then return nil, "invalid args" end
	
	local test = select(2, strsplit(":", itemLink))
	if not test then return nil, "invalid link" end
	
	local s, e = strfind(test, "[0-9]+")
	if not (s and e) then return nil, "not an itemLink" end
	
	local itemID = tonumber(strsub(test, s, e))
	if not itemID then return nil, "invalid number" end
	
	return (not ignoreGemID and lib:GetNewGem(itemID)) or itemID
end

--- Attempts to get the itemString from a given itemLink.
-- This function will use the second return value from calling GetItemInfo on the passed itemLink if it can to ensure the link is valid.
-- If the passed value is a number and GetItemInfo doesn't work, it'll assume all the suffixes are 0 and assume the number is the itemID.
-- @param itemLink The link for the item.
-- @return Returns the itemString as the first parameter. On error, will return nil as the first parameter and an error message as the second.
function lib:GetItemString(itemLink)
	if type(itemLink) ~= "string" and type(itemLink) ~= "number" then
		return nil, "invalid arg type"
	end
	itemLink = select(2, GetItemInfo(itemLink)) or itemLink
	if tonumber(itemLink) then
		return "item:"..itemLink..":0:0:0:0:0:0"
	end
	
	local itemInfo = {strfind(itemLink, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%-?%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")}
	if not itemInfo[11] then return nil, "invalid link" end
	
	return table.concat(itemInfo, ":", 4, 11)
end

local function PadNumber(num, pad)
	if num < 10 and pad then
		return format("%3d", num)
	end
	
	return tostring(num)
end

--- Creates a formatted money string from a copper value.
-- @param money The money value in copper.
-- @param color The color to make the money text (minus the 'g'/'s'/'c'). If nil, will not add any extra color formatting.
-- @param pad If true, the formatted string will be left padded.
-- @param trim If true, will not remove any 0 valued tokens. For example, "1g" instead of "1g0s0c". If money is zero, will return "0c".
-- @return Returns the formatted money text according to the parameters.
function lib:FormatTextMoney(money, color, pad, trim)
	local money = tonumber(money)
	if not money then return end
	local gold = floor(money / COPPER_PER_GOLD)
	local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = floor(money%COPPER_PER_SILVER)
	local text = ""
	
	-- Trims 0 silver and/or 0 copper from the text
	if trim then
	    if gold > 0 then
			if color then
				text = format("%s%s ", color..PadNumber(gold, pad).."|r", GOLD_TEXT)
			else
				text = format("%s%s ", PadNumber(gold, pad), GOLD_TEXT)
			end
		end
		if silver > 0 then
			if color then
				text = format("%s%s%s ", text, color..PadNumber(silver, pad).."|r", SILVER_TEXT)
			else
				text = format("%s%s%s ", text, PadNumber(silver, pad), SILVER_TEXT)
			end
		end
		if copper > 0 then
			if color then
				text = format("%s%s%s ", text, color..PadNumber(copper, pad).."|r", COPPER_TEXT)
			else
				text = format("%s%s%s ", text, PadNumber(copper, pad), COPPER_TEXT)
			end
		end
		if money == 0 then
			if color then
				text = format("%s%s%s ", text, color..PadNumber(copper, pad).."|r", COPPER_TEXT)
			else
				text = format("%s%s%s ", text, PadNumber(copper, pad), COPPER_TEXT)
			end
		end
		
		return text:trim()
	else
		-- Add gold
		if gold > 0 then
			if color then
				text = format("%s%s ", color..PadNumber(gold, pad).."|r", GOLD_TEXT)
			else
				text = format("%s%s ", PadNumber(gold, pad), GOLD_TEXT)
			end
		end
	
		-- Add silver
		if gold > 0 or silver > 0 then
			if color then
				text = format("%s%s%s ", text, color..PadNumber(silver, pad).."|r", SILVER_TEXT)
			else
				text = format("%s%s%s ", text, PadNumber(silver, pad), SILVER_TEXT)
			end
		end
	
		-- Add copper
		if color then
			text = format("%s%s%s ", text, color..PadNumber(copper, pad).."|r", COPPER_TEXT)
		else
			text = format("%s%s%s ", text, PadNumber(copper, pad), COPPER_TEXT)
		end
	end
	
	return text:trim()
end

--- Creates a formatted money string from a copper value and uses coin icon.
-- @param money The money value in copper.
-- @param color The color to make the money text (minus the coin icons). If nil, will not add any extra color formatting.
-- @param pad If true, the formatted string will be left padded.
-- @param trim If true, will not remove any 0 valued tokens. For example, "1g" instead of "1g0s0c". If money is zero, will return "0c".
-- @return Returns the formatted money text according to the parameters.
function lib:FormatTextMoneyIcon(money, color, pad, trim)
	local money = tonumber(money)
	if not money then return end
	local gold = floor(money / COPPER_PER_GOLD)
	local silver = floor((money - (gold * COPPER_PER_GOLD)) / COPPER_PER_SILVER)
	local copper = floor(money%COPPER_PER_SILVER)
	local text = ""
	
	-- Trims 0 silver and/or 0 copper from the text
	if trim then
	    if gold > 0 then
			if color then
				text = format("%s%s ", color..PadNumber(gold, pad).."|r", GOLD_ICON)
			else
				text = format("%s%s ", PadNumber(gold, pad), GOLD_ICON)
			end
		end
		if silver > 0 then
			if color then
				text = format("%s%s%s ", text, color..PadNumber(silver, pad).."|r", SILVER_ICON)
			else
				text = format("%s%s%s ", text, PadNumber(silver, pad), SILVER_ICON)
			end
		end
		if copper > 0 then
			if color then
				text = format("%s%s%s ", text, color..PadNumber(copper, pad).."|r", COPPER_ICON)
			else
				text = format("%s%s%s ", text, PadNumber(copper, pad), COPPER_ICON)
			end
		end
		if money == 0 then
			if color then
				text = format("%s%s%s ", text, color..PadNumber(copper, pad).."|r", COPPER_ICON)
			else
				text = format("%s%s%s ", text, PadNumber(copper, pad), COPPER_ICON)
			end
		end
		
		return text:trim()
	else
		-- Add gold
		if gold > 0 then
			if color then
				text = format("%s%s ", color..PadNumber(gold, pad).."|r", GOLD_ICON)
			else
				text = format("%s%s ", PadNumber(gold, pad), GOLD_ICON)
			end
		end
	
		-- Add silver
		if gold > 0 or silver > 0 then
			if color then
				text = format("%s%s%s ", text, color..PadNumber(silver, pad).."|r", SILVER_ICON)
			else
				text = format("%s%s%s ", text, PadNumber(silver, pad), SILVER_ICON)
			end
		end
	
		-- Add copper
		if color then
			text = format("%s%s%s ", text, color..PadNumber(copper, pad).."|r", COPPER_ICON)
		else
			text = format("%s%s%s ", text, PadNumber(copper, pad), COPPER_ICON)
		end
	end
	
	return text:trim()
end

--- In patch 4.3, Blizzard decided it'd be fun to make dividing by zero cause an error.
-- This function should be used whenever dividing by zero is a possibility.
-- Blizzard has since reverted this change, but this using this function is wise incase they ever add it back.
-- @param a The numerator.
-- @param b The denominator.
-- @return If b is zero, will return math.huge, -math.huge, or log(-1) as applicable. Otherwise, returns a/b.
function lib:SafeDivide(a, b)
	if b == 0 then
		if a > 0 then
			return math.huge
		elseif a < 0 then
			return -math.huge
		else
			-- It seems that Blizzard changed the singature of math.log so we cannot use log(-1) any longer.
			-- Dont know at how many places this 0/0 is exactly used, but this seems to work.
			return 0
		end
	end
	
	return a / b
end

--- Shows a popup dialog with the given name and ensures it's visible over the TSM frame by setting the frame strata to TOOLTIP.
-- @param name The name of the static popup dialog to be shown.
function lib:ShowStaticPopupDialog(name)
	StaticPopupDialogs[name].preferredIndex = 3
	StaticPopup_Show(name)
	for i=1, 100 do
		if _G["StaticPopup" .. i] and _G["StaticPopup" .. i].which == name then
			_G["StaticPopup" .. i]:SetFrameStrata("TOOLTIP")
			break
		end
	end
end

--- Creates a time-based delay. The callback function will be called after the specified duration.
-- Use TSMAPI:CancelFrame(label) to cancel delays (usually just used for repetitive delays).
-- @param label An arbitrary label for this delay. If a delay with this label has already been started, the request will be ignored.
-- @param duration How long before the callback should be called. This is generally accuate within 50ms (depending on frame rate).
-- @param callback The function to be called after the duration expires.
-- @param repeatDelay If you want this delay to repeat until canceled, after the initial duration expires, will restart the callback with this duration. Passing nil means no repeating.
-- @return Returns an error message as the second return value on error.
function lib:CreateTimeDelay(label, duration, callback, repeatDelay)
	if not (label and type(duration) == "number" and type(callback) == "function") then return nil, "invalid args", label, duration, callback, repeatDelay end

	local frameNum
	for i, frame in ipairs(delays) do
		if frame.label == label then return end
		if not frame.inUse then
			frameNum = i
		end
	end
	
	if not frameNum then
		local delay = CreateFrame("Frame")
		delay:Hide()
		tinsert(delays, delay)
		frameNum = #delays
	end
	
	local frame = delays[frameNum]
	frame.inUse = true
	frame.repeatDelay = repeatDelay
	frame.label = label
	frame.timeLeft = duration
	frame:SetScript("OnUpdate", function(self, elapsed)
		self.timeLeft = self.timeLeft - elapsed
		if self.timeLeft <= 0 then
			if self.repeatDelay then
				self.timeLeft = self.repeatDelay
			else
				lib:CancelFrame(self)
			end
			callback()
		end
	end)
	frame:Show()
end

--- The passed callback function will be called once every OnUpdate until canceled via TSMAPI:CancelFrame(label).
-- @param label An arbitrary label for this delay. If a delay with this label has already been started, the request will be ignored.
-- @param callback The function to be called every OnUpdate.
-- @return Returns an error message as the second return value on error.
function lib:CreateFunctionRepeat(label, callback)
	local callbackIsValid = type(callback) == "function"
	if not (label and callbackIsValid) then return nil, "invalid args", label, callback end

	local frameNum
	for i, frame in ipairs(delays) do
		if frame.label == label then return end
		if not frame.inUse then
			frameNum = i
		end
	end
	
	if not frameNum then
		local delay = CreateFrame("Frame")
		delay:Hide()
		tinsert(delays, delay)
		frameNum = #delays
	end
	
	local frame = delays[frameNum]
	frame.inUse = true
	frame.label = label
	frame:SetScript("OnUpdate", function(self)
		callback()
	end)
	frame:Show()
end

--- Cancels a frame created through TSMAPI:CreateTimeDelay() or TSMAPI:CreateFunctionRepeat().
-- Frames are automatically recycled to avoid memory leaks.
-- @param label The label of the frame you want to cancel.
function lib:CancelFrame(label)
	local delayFrame
	if type(label) == "table" then
		delayFrame = label
	else
		for i, frame in ipairs(delays) do
			if frame.label == label then
				delayFrame = frame
			end
		end
	end
	
	if delayFrame then
		delayFrame:Hide()
		delayFrame.label = nil
		delayFrame.inUse = false
		delayFrame.validate = nil
		delayFrame.timeLeft = nil
		delayFrame:SetScript("OnUpdate", nil)
	end
end