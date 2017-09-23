-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Crafting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_crafting.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local Scan = TSM:NewModule("Scan", "AceEvent-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table

local scanCoroutine
local modeLookup = {}

function Scan:OnInitialize()
	Scan:RegisterEvent("CHAT_MSG_SYSTEM")
	for _, data in ipairs(TSM.tradeSkills) do
		modeLookup[data.name] = GetSpellInfo(data.spellID)
	end
end

function Scan:ScanProfession(mode)
	local openProfession = TSM.Crafting:GetCurrentTradeskill()
	if openProfession then
		Scan.wasOpen = openProfession
	else
		Scan.wasOpen = nil
	end
	CloseTradeSkill()
	for _, data in pairs(TSM.tradeSkills) do
		if data.name == TSM.mode then
			local spellName = GetSpellInfo(data.spellID)
			local delay = CreateFrame("Frame")
			delay:RegisterEvent("TRADE_SKILL_UPDATE")
			delay:RegisterEvent("TRADE_SKILL_SHOW")
			delay:SetScript("OnEvent", function(self, event)
					self:UnregisterEvent(event)
					if event == "TRADE_SKILL_UPDATE" then
						if self.ready then
							self:Hide()
							TSMAPI:CreateTimeDelay("professionscan", 0.2, Scan.StartProfessionScan)
						else
							self.ready = true
						end
					elseif event == "TRADE_SKILL_SHOW" then
						Scan:ShowScanningFrame()
						SetTradeSkillSubClassFilter(0, 1, 1)
						SetTradeSkillInvSlotFilter(0, 1, 1)
						if TradeSkillFrameEditBox then
							TradeSkillFrameEditBox:SetText("")
						end
						if TradeSkillFrameAvailableFilterCheckButton:GetChecked() then
							TradeSkillFrameAvailableFilterCheckButton:Click()
						end
						for i=GetNumTradeSkills(), 1, -1 do
							local _, lineType, _, isExpanded = GetTradeSkillInfo(i)
							if lineType == "header" and not isExpanded then
								ExpandTradeSkillSubClass(i)
							end
						end
						if self.ready then
							self:Hide()
							TSMAPI:CreateTimeDelay("professionscan", 0.2, Scan.StartProfessionScan)
						else
							self.ready = true
						end
					end
				end)
			CastSpellByName(spellName) -- opens the profession
			break
		end
	end
end

function Scan:ShowScanningFrame()
	if not TradeSkillFrame then return end
	if not Scan.scanningFrame then
		local frame = CreateFrame("Frame", nil, TradeSkillFrame)
		frame:SetAllPoints(TradeSkillFrame)
		frame:SetBackdrop({
			bgFile = "Interface\\Buttons\\WHITE8X8",
			tile = false,
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			edgeSize = 24,
			insets = {left = 4, right = 4, top = 4, bottom = 4},
		})
		frame:SetBackdropColor(0, 0, 0.05, 1)
		frame:SetBackdropBorderColor(0,0,1,1)
		frame:SetFrameLevel(TradeSkillFrame:GetFrameLevel() + 10)
		frame:EnableMouse(true)
		
		local tFile, tSize = GameFontNormalLarge:GetFont()
		local titleText = frame:CreateFontString(nil, "Overlay", "GameFontNormalLarge")
		titleText:SetFont(tFile, tSize-2, "OUTLINE")
		titleText:SetTextColor(1, 1, 1, 1)
		titleText:SetPoint("CENTER", frame, "CENTER", 0, 0)
		titleText:SetText(L["TradeSkillMaster_Crafting - Scanning..."])
		Scan.scanningFrame = frame
	end
	Scan.scanningFrame:Show()
end

local function ScanDone()
	Scan.scanningFrame:Hide()
	scanCoroutine = nil
	TSMAPI:CancelFrame("craftingProfessionScan")
	TSMAPI:CancelFrame("craftingProfessionScanTimeout")
	if Scan.wasOpen ~= TSM.mode then
		CloseTradeSkill()
	end
end

local function ScanDriver()
	if not scanCoroutine then
		return
	elseif modeLookup[TSM.mode] ~= GetTradeSkillLine() then
		return ScanDone()
	end
	
	local status = coroutine.status(scanCoroutine)
	if status == "suspended" then
		local success = coroutine.resume(scanCoroutine)
		if not success then
			error(success)
		end
	elseif status == "dead" then
		ScanDone()
	end
end

function Scan:StartProfessionScan()
	if (select(2, GetTradeSkillInfo(1)) ~= "header") then
		TSM:Print("Tradeskill is not fully loaded, try to scan it later.")
		ScanDone()
		return
	end
	scanCoroutine = coroutine.create(Scan.ScanCrafts)
	TSMAPI:CreateTimeDelay("craftingProfessionScan", 0.1, ScanDriver, 0)
	TSMAPI:CreateTimeDelay("craftingProfessionScanTimeout", 10, ScanDone)
end

function Scan:ScanCrafts()
	local matsTemp = {}
	local enchantsTemp = {}
	local validMatItemIDs, validCraftItemIDs = {}, {}

	for index=2, GetNumTradeSkills() do
		for i=1, GetTradeSkillNumReagents(index) do
			if not TSMAPI:GetItemID(GetTradeSkillReagentItemLink(index, i)) or not GetTradeSkillReagentInfo(index, i) then
				TradeSkillFrame_SetSelection(index)
				break
			end
		end
	end
	TradeSkillFrame_Update()

	for index=2, GetNumTradeSkills() do
		local dataTemp = {mats={}, itemID=nil, spellID=nil, queued=0, group=nil, name=nil}
		local tsLink = GetTradeSkillItemLink(index)
		if TSM:IsEnchant(tsLink) and TSM.mode == "Enchanting" then
			dataTemp.spellID = TSMAPI:GetItemID(GetTradeSkillItemLink(index))
			dataTemp.itemID = TSM.Enchanting.itemID[dataTemp.spellID]
			if dataTemp.spellID and dataTemp.itemID and TSM.Enchanting:GetSlot(dataTemp.itemID) then
				while true do
					dataTemp.name = GetSpellInfo(dataTemp.spellID)
					if dataTemp.name then
						break
					else
						coroutine.yield()
					end
				end
			end
		else
			dataTemp.spellID = TSMAPI:GetItemID(GetTradeSkillRecipeLink(index))
			if tsLink and not TSM:IsEnchant(tsLink) and dataTemp.spellID then 
				dataTemp.itemID = TSMAPI:GetItemID(tsLink)
				if dataTemp.itemID then
					while true do
						dataTemp.name = GetItemInfo(dataTemp.itemID)
						if dataTemp.name then
							break
						else
							coroutine.yield()
						end
					end
				end
			end
		end
		if dataTemp.name then
			-- figure out how many of this item is made per craft (almost always 1)
			local lNum, hNum = GetTradeSkillNumMade(index)
			dataTemp.numMade = floor(((lNum or 1) + (hNum or 1))/2)
			dataTemp.hasCD = select(2, GetTradeSkillCooldown(index)) and true or nil
			
			if TSM.mode == "Enchanting" and TSM:IsEnchant(tsLink) then
				dataTemp.mats[TSM.Enchanting.vellumID] = 1
				local velName = GetItemInfo(TSM.Enchanting.vellumID) or (GetLocale() == "enUS" and "Enchanting Vellum")
				matsTemp[TSM.Enchanting.vellumID] = {name=name, cost=5}
			end
			
			local valid = false
			
			while true do
				valid = true
				-- loop over every material for the selected craft and gather itemIDs and quantities for the mats
				for i=1, GetTradeSkillNumReagents(index) do
					local link = GetTradeSkillReagentItemLink(index, i)
					local matID = TSMAPI:GetItemID(link)
					if not matID then
						valid = false
						break
					end
					local name, _, quantity = GetTradeSkillReagentInfo(index, i)
					if not name then
						valid = false
						break
					end
					dataTemp.mats[matID] = quantity
					matsTemp[matID] = {name = name, cost = 5}
				end
				
				if not valid then
					coroutine.yield()
				else
					break
				end
			end
			if valid then
				local itemID = dataTemp.itemID
				dataTemp.itemID = nil
				dataTemp.group = TSM[TSM.mode]:GetSlot(itemID, dataTemp.mats, index)
				
				validCraftItemIDs[itemID] = true
				for itemID in pairs(dataTemp.mats) do
					validMatItemIDs[itemID] = true
				end
				
				if not TSM.Data[TSM.mode].crafts[itemID] then
					TSM.Data[TSM.mode].crafts[itemID] = CopyTable(dataTemp)
					TSM.Data[TSM.mode].crafts[itemID].enabled = not TSM.db.profile.lastScan[TSM.mode] or (TSM.db.profile.enableNewTradeskills and true or nil)
				else
					-- mats change every so often so make sure they are up to date
					TSM.Data[TSM.mode].crafts[itemID].mats = CopyTable(dataTemp.mats)
					-- make sure the number each cast makes is correct
					TSM.Data[TSM.mode].crafts[itemID].numMade = dataTemp.numMade
					-- make sure the cd info is correct
					TSM.Data[TSM.mode].crafts[itemID].hasCD = dataTemp.hasCD
					-- update the group
					TSM.Data[TSM.mode].crafts[itemID].group = dataTemp.group
				end
			end
		end
		if index%100 == 0 then coroutine.yield() end
	end
	local matList = TSM:GetMats(TSM.mode)
	for ID, matData in pairs(matsTemp) do
		TSM.Data[TSM.mode].mats[ID] = TSM.Data[TSM.mode].mats[ID] or matData
	end
	TSM.db.profile.lastScan[TSM.mode] = time()
	
	local matsToRemove, craftsToRemove = {}, {}
	for itemID, craft in pairs(TSM.Data[TSM.mode].crafts) do
		if not validCraftItemIDs[itemID] then
			tinsert(craftsToRemove, itemID)
		else
			for matID in pairs(craft.mats) do
				if not validMatItemIDs[matID] then
					tinsert(matsToRemove, matID)
				end
			end
		end
	end
	
	local isValidTradeSkill = false
	local currentTradeSkillName = GetTradeSkillLine()
	for _, data in ipairs(TSM.tradeSkills) do
		if data.name == TSM.mode then
			if currentTradeSkillName == GetSpellInfo(data.spellID) then
				isValidTradeSkill = true
			end
			break
		end
	end
	
	local playerName = UnitName("player")
	TSM.db.profile.playerProfessionInfo[TSM.mode] = TSM.db.profile.playerProfessionInfo[TSM.mode] or {}
	
	if isValidTradeSkill then
		TSM.db.profile.playerProfessionInfo[TSM.mode][playerName] = GetNumTradeSkills()
	end
	
	local isHighest = true
	for player, num in pairs(TSM.db.profile.playerProfessionInfo[TSM.mode]) do
		if player ~= playerName and num > GetNumTradeSkills() then
			isHighest = false
		end
	end
	
	if isHighest then
		for i=1, #craftsToRemove do
			TSM.Data[TSM.mode].crafts[craftsToRemove[i]] = nil
		end
		
		for i=1, #matsToRemove do
			TSM.Data[TSM.mode].mats[matsToRemove[i]] = nil
		end
	end
end

local newCraftMsg = gsub(ERR_LEARN_RECIPE_S, "%%s", "")
function Scan:CHAT_MSG_SYSTEM(_, msg)
	if msg:match(newCraftMsg) then
		for name, data in pairs(TSM.db.profile.lastScan) do
			TSM.db.profile.lastScan[name] = -math.huge
		end
	end
end