-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_Crafting.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)

-- CRAFTING SPECIFIC API FUNCTIONS --

-- Clears the queue for the passed tradeskill (not case sensitive)
-- Will refresh the craft management window if it's open
-- Returns true if successful
-- Returns nil followed by an error message if not successful (two return values)
function TSMAPI:ClearQueue(tradeskill)
	if type(tradeskill) ~= "string" then
		return nil, "Invalid Tradeskill Type"
	end
	
	local valid = false
	
	for _, skill in ipairs(TSM.tradeSkills) do
		if strlower(skill.name) == strlower(tradeskill) or strlower(tradeskill) == "all" then
			for _, data in pairs(TSM.Data[skill.name].crafts) do
				data.queued = 0
			end
			valid = true
		end
	end
	
	if not valid then return nil, "Invalid Tradeskill: "..tradeskill end
	
	if TSM.Crafting.frame:IsVisible() then
		TSM.Crafting:UpdateAllScrollFrames()
	end
	
	return true
end

-- Sets the queued quantity of the specified item to the specified quantity
-- Will refresh the craft management window if it's open unless noUpdate is true - if you are going to call this multiple times in succession, set noUpdate on all but the last call to avoid lagging the user.
-- Accepts either itemIDs or itemLinks
-- Returns true if successful
function TSMAPI:AddItemToQueue(itemID, quantity, noUpdate)
	itemID = TSMAPI:GetItemID(itemID) or itemID
	if type(itemID) ~= "number" then return nil, "invalid itemID/itemLink" end
	if type(quantity) ~= "number" then return nil, "invalid quantity" end
	
	for _, skill in ipairs(TSM.tradeSkills) do
		if TSM.Data[skill.name].crafts[itemID] then
			TSM.Data[skill.name].crafts[itemID].queued = quantity
			break
		end
	end
	
	if TSM.Crafting.frame:IsVisible() and not noUpdate then
		TSM.Crafting:UpdateAllScrollFrames()
	end
	
	return true
end

-- Gets data for the specified tradeskill
-- Returns nil if not successful followed by an error message (two return values)
-- Returns a list of all crafts added to Crafting for the tradeskill. Each craft is a list with the following properties:

--[[
{
	itemID=#####, --itemID of Crafted Item
	spellID=#####, --spellID of spell to craft this item
	mats={matItemID1=matQuantity1, matItemID2=matQuantity2, ...}, -- mats for this craft
	queued=#, -- how many are queued
	enabled=true/false, -- if it is enabled (will show up in the craft management window)
	group=#, -- number of the group this item is in
	name="name" -- name of the crafted item
}
--]]
function TSMAPI:GetTradeSkillData(tradeskill)
	if not tradeskill then return end
	
	if not TSM.data[tradeskill] then
		for _, skill in ipairs(TSM.tradeSkills) do
			if strlower(skill.name) == strlower(tradeskill) then
				tradeskill = skill.name
				break
			end
		end
	end
	
	if not (TSM.data[tradeskill] and TSM.data[tradeskill].crafts) then return end
	
	local results = {}
	for itemID, data in pairs(TSM.Data[tradeskill].crafts) do
		local temp = CopyTable(data)
		temp.itemID = itemID
		tinsert(results, temp)
	end
	
	return results
end