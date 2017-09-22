-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local TradeSkillScanner = TSM:NewModule("TradeSkillScanner", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local private = { priceTextCache = { lastClear = 0 }, scanThreadId = nil, scanThreadCallback = nil, updateThreadId = nil }
local MAX_SCAN_YIELDS = 20

-- lookup table for garrion profession building info
-- index = buildingID
-- value = profession spell id (for looking up localized name)
private.GARRISON_PROFESSION_BUILDINGS = {
	-- Alchemy
	[76] = 2259,
	[119] = 2259,
	[120] = 2259,
	-- Enchanting
	[93] = 7411,
	[125] = 7411,
	[126] = 7411,
	-- Engineering
	[91] = 4036,
	[123] = 4036,
	[124] = 4036,
	-- Jewelcrafting
	[96] = 25229,
	[131] = 25229,
	[132] = 25229,
	-- Inscription
	[95] = 45357,
	[129] = 45357,
	[130] = 45357,
	-- Tailoring
	[94] = 3908,
	[127] = 3908,
	[128] = 3908,
	-- Blacksmithing
	[60] = 2018,
	[117] = 2018,
	[118] = 2018,
	-- Leatherworking
	[90] = 2108,
	[121] = 2108,
	[122] = 2108,
}


function TradeSkillScanner:OnEnable()
	private.updateThreadId = TSMAPI.Threading:Start(private.UpdatePlayerTradeSkillsThread, 0.4, function() private.updateThreadId = nil end)
	TSM:RegisterEvent("LEARNED_SPELL_IN_TAB", function()
		if not private.updateThreadId then
			private.updateThreadId = TSMAPI.Threading:Start(private.UpdatePlayerTradeSkillsThread, 0.4, function() private.updateThreadId = nil end)
		end
	end)
end

function TradeSkillScanner:ScanProfession(profession, player, isLinked, callback)
	private:OnScanThreadDone()
	private.scanThreadCallback = callback
	private.scanThreadId = TSMAPI.Threading:Start(private.ScanCurrentProfessionThread, 0.8, private.OnScanThreadDone, { profession, player, isLinked })
	return private.scanThreadId
end

function private:OnScanThreadDone()
	TSMAPI.Threading:Kill(private.scanThreadId)
	private.scanThreadId = nil
	private.scanThreadCallback = nil
end

function private.ScanCurrentProfessionThread(self, args)
	self:SetThreadName("CRAFTING_PROFESSION_SCAN")
	local professionName, playerName, isLinked = unpack(args)
	local numTradeSkills = #C_TradeSkillUI.GetFilteredRecipeIDs()

	-- Calculate a hash of learned spells to see if we need to rescan the profession
	local hashData = {}
	for _, spellId in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
		if C_TradeSkillUI.GetRecipeInfo(spellId).learned then
			tinsert(hashData, spellId)
		end
	end
	sort(hashData)
	local hash = TSMAPI.Util:CalculateHash(table.concat(hashData, ";"))

	-- whenever we yield there's a chance that the profession may change
	-- set a yield invariant so that the thread will be killed if it does
	self:SetYieldInvariant(function()
		return C_TradeSkillUI.IsTradeSkillLinked() == isLinked and TSM:GetCurrentProfessionName() == professionName and #C_TradeSkillUI.GetFilteredRecipeIDs() == numTradeSkills
	end)
	self:Yield(true) -- do an initial check

	if not isLinked then
		 -- check if this player (probably) doesn't have any professions in which case don't scan any others to avoid errors
		if not TSM.db.factionrealm.playerProfessions[playerName] then return end
		-- if it's a garrison profession, then add the profession against this player
		if C_TradeSkillUI.IsNPCCrafting() then
			-- make sure it's not Ahm, which we don't want to scan
			for _, spellId in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
				local itemLink = C_TradeSkillUI.GetRecipeItemLink(spellId)
				if itemLink and strmatch(itemLink, "enchant:177355") then
					if private.scanThreadCallback then
						private.scanThreadCallback()
					end
					return
				end
			end
			local info = TSM.db.factionrealm.playerProfessions[playerName][professionName] or {}
			info.isGarrison = true
			info.isSecondary = false
			info.level = 0
			info.maxLevel = 0
			info.prompted = true
			info.garrisonBuildingID = private:GetGarrisonBuildingID()
			if not info.garrisonBuildingID then
				TSM:LOG_ERR("Could not lookup garrison building ID")
				if private.scanThreadCallback then
					private.scanThreadCallback()
				end
				return
			end
			TSM.db.factionrealm.playerProfessions[playerName][professionName] = info
			TSMAPI.Sync:KeyUpdated(TSM.db.factionrealm.playerProfessions, playerName)
		elseif TSM.db.factionrealm.playerProfessions[playerName][professionName] then
			TSM.db.factionrealm.playerProfessions[playerName][professionName].link = C_TradeSkillUI.GetTradeSkillListLink()
			TSMAPI.Sync:KeyUpdated(TSM.db.factionrealm.playerProfessions, playerName)
		end
	end

	-- check if we've scanned this profession successfully within the past 2 hours and it hasn't changed
	local cacheInfo = TSM.db.factionrealm.professionScanCache[playerName .. professionName]
	if (not C_TradeSkillUI.IsNPCCrafting()) and cacheInfo and cacheInfo.hash == hash and cacheInfo.scanTime > time() - 2 * 60 * 60 then
		if private.scanThreadCallback then
			private.scanThreadCallback()
		end
		return
	end

	-- get profession craft info
	local professionCrafts = {}
	local toRemove = {}
	local numYields = 0
	while true do
		local numMissing = 0
		for _, spellId in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
			local recipeInfo = C_TradeSkillUI.GetRecipeInfo(spellId)
			if recipeInfo.learned then
				-- check if we have skilled up and have lower ranked recipes to remove
				if recipeInfo.previousRecipeID then
					toRemove[recipeInfo.previousRecipeID] = true
					professionCrafts[recipeInfo.previousRecipeID] = nil
				end
				if not toRemove[spellId] then
					professionCrafts[spellId] = professionCrafts[spellId] or private:GetCraftInfo(spellId)
					if not professionCrafts[spellId] then
						numMissing = numMissing + 1
					end
				end
			end
			self:Yield()
		end
		if numMissing == 0 then
			break
		elseif numYields >= MAX_SCAN_YIELDS then
			return
		end
		numYields = numYields + 1
		self:Yield(true)
	end

	-- scan the profession
	local scanResult = { crafts = {}, mats = {} }
	local isEnchanting = TSM:IsCurrentProfessionEnchanting()
	if isEnchanting then
		self:WaitForFunction(function() return TSMAPI.Item:GetName(TSM.VELLUM_ITEM_STRING) end)
	end
	for spellId, data in pairs(professionCrafts) do
		TSMAPI:Assert(data, "Invalid profession spell")
		if type(data) == "table" then
			-- it should be a valid craft
			local itemLink, spellLink, itemString, spellId, craftName, mats = unpack(data)
			scanResult.crafts[spellId] = { name = craftName, itemString = itemString, mats = {}, profession = professionName }
			local lNum, hNum = C_TradeSkillUI.GetRecipeNumItemsProduced(spellId)
			-- workaround for incorrect values returned for Temporal Crystal
			if spellId == 169092 and itemString == "i:113588" then
				lNum, hNum = 1, 1
			end
			-- workaround for incorrect values returned for new mass milling recipes
			if TSM.MASS_MILLING_RECIPES[spellId] then
				lNum, hNum = 8, 8.8
			end
			scanResult.crafts[spellId].numResult = floor(((lNum or 1) + (hNum or 1)) / 2)
			scanResult.crafts[spellId].hasCD = select(2, C_TradeSkillUI.GetRecipeCooldown(spellId)) and true or nil

			-- add the mat info to this craft
			for matItemString, matData in pairs(mats) do
				scanResult.crafts[spellId].mats[matItemString] = matData.quantity
				scanResult.mats[matItemString] = { name = matData.name }
			end

			-- if this is an enchant, add a vellum to the list of mats
			if isEnchanting and strfind(itemLink, "enchant:") then
				scanResult.crafts[spellId].mats[TSM.VELLUM_ITEM_STRING] = 1
				local name = TSMAPI.Item:GetName(TSM.VELLUM_ITEM_STRING)
				scanResult.mats[TSM.VELLUM_ITEM_STRING] = scanResult.mats[TSM.VELLUM_ITEM_STRING] or {}
				scanResult.mats[TSM.VELLUM_ITEM_STRING].name = scanResult.mats[TSM.VELLUM_ITEM_STRING].name or name
				scanResult.crafts[spellId].numResult = 1
			end
		end
		self:Yield()
	end

	-- clear out old data for this profession
	for spellId, data in pairs(TSM.db.factionrealm.crafts) do
		if data.profession == professionName and not scanResult.crafts[spellId] then
			data.players[playerName] = nil
			if not next(data.players) then
				TSM.db.factionrealm.crafts[spellId] = nil
			end
		end
		self:Yield()
	end

	-- merge profession scan data into database
	for spellId, data in pairs(scanResult.crafts) do
		if TSM.db.factionrealm.crafts[spellId] then
			TSM.db.factionrealm.crafts[spellId].profession = data.profession
			TSM.db.factionrealm.crafts[spellId].name = data.name
			TSM.db.factionrealm.crafts[spellId].itemString = data.itemString
			TSM.db.factionrealm.crafts[spellId].mats = data.mats
			TSM.db.factionrealm.crafts[spellId].numResult = data.numResult
		else
			data.players = {}
			data.queued = 0
			TSM.db.factionrealm.crafts[spellId] = data
		end
		TSM.db.factionrealm.crafts[spellId].players[playerName] = true
		self:Yield()
	end
	local matsWithLoop = {}
	for itemString, data in pairs(scanResult.mats) do
		if TSM.db.factionrealm.mats[itemString] then
			TSM.db.factionrealm.mats[itemString].name = data.name
		else
			TSM.db.factionrealm.mats[itemString] = data
		end
		-- check for loops in mat prices
		if TSM.Cost:MatCostHasLoop(itemString) then
			matsWithLoop[itemString] = true
		end
		self:Yield()
	end
	local fixedMatCosts = {}
	for itemString in pairs(matsWithLoop) do
		local didFix = false
		if not TSM.db.factionrealm.mats[itemString].customValue then
			local customPrice = TSM.db.global.defaultMatCostMethod
			-- make a best-effort attempt to fix problem custom prices
			local fixedCustomPrice = nil
			if strfind(customPrice, " crafting,") then
				fixedCustomPrice = gsub(customPrice, " crafting,", "")
			elseif strfind(customPrice, " crafting%)") then
				fixedCustomPrice = gsub(customPrice, " crafting%)", ")")
			end
			TSM.db.factionrealm.mats[itemString].customValue = fixedCustomPrice
			if TSM.Cost:MatCostHasLoop(itemString) then
				-- try removing convert()
				customPrice = fixedCustomPrice or customPrice
				if strfind(customPrice, " convert%([^%)]+%),") then
					fixedCustomPrice = gsub(customPrice, " convert%([^%)]+%),", "")
				elseif strfind(customPrice, ", convert%([^%)]+%)%)") then
					fixedCustomPrice = gsub(customPrice, ", convert%([^%)]+%)%)", ")")
				end
				TSM.db.factionrealm.mats[itemString].customValue = fixedCustomPrice
				if not TSM.Cost:MatCostHasLoop(itemString) then
					fixedMatCosts[itemString] = fixedCustomPrice
				end
			else
				fixedMatCosts[itemString] = fixedCustomPrice
			end
			TSM.db.factionrealm.mats[itemString].customValue = nil
		end
		if not fixedMatCosts[itemString] then
			-- the user will need to manually fix it
			TSM:Printf(L["A loop was detected in the mat cost of %s. Please correct this in your settings. This is typically caused by having 'crafting' in the custom price of two mats which can be crafted into each other."], TSMAPI.Item:GetLink(itemString))
		end
	end
	for itemString, fixedCustomPrice in pairs(fixedMatCosts) do
		TSM.db.factionrealm.mats[itemString].customValue = fixedCustomPrice
	end
	TSM.db.factionrealm.professionScanCache[playerName .. professionName] = { hash = hash, scanTime = time() }
	if private.scanThreadCallback then
		private.scanThreadCallback()
	end
end

function private:GetCraftInfo(spellId)
	local itemLink = C_TradeSkillUI.GetRecipeItemLink(spellId)
	local spellLink = C_TradeSkillUI.GetRecipeLink(spellId)
	TSMAPI:Assert(itemLink and spellLink)

	local itemString, craftName
	TSMAPI:Assert(spellLink and strfind(spellLink, "enchant:"), "Invalid profession spell.")
	if strfind(itemLink, "enchant:") then
		-- result of craft is enchant
		itemString = TSM.enchantingItemIDs[spellId] or TSM.MASS_MILLING_RECIPES[spellId]
		craftName = GetSpellInfo(spellId)
		if not itemString then
			-- this craft does not result in an item but we need to return something that evalulates to true
			return "skip"
		end
	elseif strfind(itemLink, "item:") then
		-- result of craft is item
		itemString = TSMAPI.Item:ToItemString(itemLink)
		craftName = TSMAPI.Item:GetName(itemLink)
	else
		TSMAPI:Assert(false, "Invalid profession spell.")
	end
	if not itemString then return end

	local mats = {}
	local haveInvalidMats = false
	for i = 1, C_TradeSkillUI.GetRecipeNumReagents(spellId) do
		local name, _, quantity = C_TradeSkillUI.GetRecipeReagentInfo(spellId, i)
		local matItemString = TSMAPI.Item:ToItemString(C_TradeSkillUI.GetRecipeReagentItemLink(spellId, i))
		TSMAPI.Item:FetchInfo(matItemString)
		if name and matItemString and quantity then
			mats[matItemString] = { quantity = quantity, name = name }
		else
			-- keep going to query all the info before returning due to the invalid mat
			haveInvalidMats = true
		end
	end
	if haveInvalidMats then return end

	return { itemLink, spellLink, itemString, spellId, craftName, mats }
end


function TradeSkillScanner:GetProfessionList()
	local list = {}
	local playerName = UnitName("player")
	if not TSM.db.factionrealm.playerProfessions[playerName] then return list end
	for name, data in pairs(TSM.db.factionrealm.playerProfessions[playerName]) do
		if data.isGarrison then
			list[playerName .. "~" .. name] = format("%s - %s", name, playerName)
		else
			list[playerName .. "~" .. name] = format("%s %d/%d - %s", name, data.level or "?", data.maxLevel or "?", playerName)
		end
	end
	return list
end

function private:GetGarrisonBuildingID()
	local playerGarrisonBuildings = {}
	for _, buildingInfo in pairs(C_Garrison.GetBuildings(LE_GARRISON_TYPE_6_0)) do
		playerGarrisonBuildings[buildingInfo.buildingID] = true
	end
	local professionName = select(2, C_TradeSkillUI.GetTradeSkillLine()) -- just want the raw name
	for buildingId, spellId in pairs(private.GARRISON_PROFESSION_BUILDINGS) do
		if GetSpellInfo(spellId) == professionName and playerGarrisonBuildings[buildingId] then
			return buildingId
		end
	end
end

function private.GetProfessions()
	local primary1, primary2, _, _, secondary1, secondary2 = GetProfessions()
	if not (primary1 or primary2 or secondary1 or secondary2) then return end
	return { primary1, primary2, secondary1, secondary2 }
end


function private.UpdatePlayerTradeSkillsThread(self)
	self:SetThreadName("CRAFTING_PLAYER_TRADESKILLS")
	-- get the player name
	local playerName = self:WaitForFunction(UnitName, "player")

	-- get the player's tradeskills
	local oldTradeSkills = TSM.db.factionrealm.playerProfessions[playerName] or {}
	local newTradeSkills = {}
	SpellBook_UpdateProfTab()
	local tradeSkills = self:WaitForFunction(private.GetProfessions)
	local btns = { PrimaryProfession1SpellButtonBottom, PrimaryProfession2SpellButtonBottom, SecondaryProfession3SpellButtonRight, SecondaryProfession4SpellButtonRight }
	for i, id in pairs(tradeSkills) do -- needs to be pairs since there might be holes
		if not btns[i]:GetParent().missingHeader:IsVisible() then
			local skillName, _, level, maxLevel = self:WaitForFunction(GetProfessionInfo, id)
			newTradeSkills[skillName] = {}
			newTradeSkills[skillName].level = level
			newTradeSkills[skillName].maxLevel = maxLevel
			newTradeSkills[skillName].isSecondary = (i > 2)
			newTradeSkills[skillName].prompted = oldTradeSkills[skillName] and oldTradeSkills[skillName].prompted or nil
			newTradeSkills[skillName].link = oldTradeSkills[skillName] and oldTradeSkills[skillName].link or nil
		end
	end
	local garrisonTradeSkills = {}
	for skillName, skillInfo in pairs(oldTradeSkills) do
		if skillInfo.isGarrison then
			garrisonTradeSkills[skillName] = skillInfo
		end
	end
	if next(garrisonTradeSkills) then
		-- wait to make sure the garrison buildings API is giving good data
		local garrisonBuildings = nil
		for i=1, 1000 do
			garrisonBuildings = self:WaitForFunction(function() return C_Garrison.GetBuildings(LE_GARRISON_TYPE_6_0) end)
			if #garrisonBuildings > 0 then
				break
			elseif #garrisonBuildings == 0 then
				garrisonBuildings = nil
			end
			self:Sleep(0.1)
		end
		-- add all the garrison professions
		for _, info in ipairs(garrisonBuildings or {}) do
			for skillName, skillInfo in pairs(garrisonTradeSkills) do
				if skillInfo.isGarrison and skillInfo.garrisonBuildingID == info.buildingID then
					newTradeSkills[skillName] = skillInfo
				end
			end
		end
	end
	TSMAPI.Sync:SetKeyValue(TSM.db.factionrealm.playerProfessions, playerName, newTradeSkills)

	-- tidy up crafts which are no longer known
	local craftsToRemove = {}
	for spellId, data in pairs(TSM.db.factionrealm.crafts) do
		local playersToRemove = {}
		for player in pairs(data.players) do
			-- check if the player still exists and still has this profession
			if not TSM.db.factionrealm.playerProfessions[player] or not TSM.db.factionrealm.playerProfessions[player][data.profession] then
				tinsert(playersToRemove, player)
			end
		end
		for _, player in ipairs(playersToRemove) do
			data.players[player] = nil
		end
		if not next(data.players) then
			tinsert(craftsToRemove, spellId)
		end
		self:Yield()
	end
	for _, spellId in ipairs(craftsToRemove) do
		TSM.db.factionrealm.crafts[spellId] = nil
	end
end

function TradeSkillScanner:CreatePresetGroups()
	local playerName = UnitName("player")
	local professionName = TSM:GetCurrentProfessionName()
	if not TSM.db.factionrealm.playerProfessions[playerName][professionName] then return end
	local groupInfo = {}
	local craftsGroupPath = TSMAPI.Groups:JoinPath("Professions", professionName, "Crafts")
	local matsGroupPath = TSMAPI.Groups:JoinPath("Professions", professionName, "Materials")
	for _, data in pairs(TSM.db.factionrealm.crafts) do
		if data.profession == professionName and data.players[playerName] then
			-- prefer items being materials over crafts
			groupInfo[data.itemString] = groupInfo[data.itemString] or craftsGroupPath
			for itemString in pairs(data.mats) do
				-- set or overwrite as a mat
				groupInfo[itemString] = matsGroupPath
			end
		end
	end
	TSM:Printf(L["Created profession group for %s."], professionName)
	TSMAPI.Groups:CreatePreset(groupInfo)
end
