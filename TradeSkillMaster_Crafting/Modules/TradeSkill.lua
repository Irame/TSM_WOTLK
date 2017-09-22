-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

-- create a local reference to the TradeSkillMaster_Crafting table and register a new module
local TSM = select(2, ...)
local TradeSkill = TSM:NewModule("TradeSkill", "AceEvent-3.0", "AceHook-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local private = {frame=nil, switchBtn=nil, currentProfession=nil, currentProfessionId=nil, managerThreadId=nil, noHide=nil, noShow=nil, scanSuccess=nil}


-- ============================================================================
-- Initialization Functions
-- ============================================================================

function TradeSkill:OnInitialize()
	for name, module in pairs(TradeSkill.modules) do
		TradeSkill[name] = module
	end
	TradeSkill:RegisterEvent("TRADE_SKILL_SHOW", "EventHandler")
	TradeSkill:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED", "EventHandler")
	TradeSkill:RegisterEvent("TRADE_SKILL_CLOSE", "EventHandler")
	TradeSkill:RegisterEvent("GARRISON_TRADESKILL_NPC_CLOSED", "EventHandler")
	TradeSkill:RegisterEvent("TRADE_SKILL_LIST_UPDATE", "EventHandler")
	TradeSkill:RegisterEvent("TRADE_SKILL_FILTER_UPDATE", "EventHandler")
	TradeSkill:RegisterEvent("UPDATE_TRADESKILL_RECAST", "EventHandler")
	TradeSkill:RegisterEvent("CHAT_MSG_SKILL", "EventHandler")
	TradeSkill:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "EventHandler")
	TradeSkill:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "EventHandler")
	TradeSkill:RegisterEvent("UNIT_SPELLCAST_FAILED", "EventHandler")
	TradeSkill:RegisterEvent("UNIT_SPELLCAST_FAILED_QUIET", "EventHandler")
	TradeSkill:RegisterEvent("BAG_UPDATE", "EventHandler")
	TSMAPI.Inventory:RegisterCallback(private.OnProfessionUpdate)
	private.managerThreadId = TSMAPI.Threading:StartImmortal(private.ProfessionWindowManagerThread, 0.5)
	TSMAPI.Threading:StartImmortal(private.LinkedProfessionScanThread, 0.5)

	-- we'll implement UIParent's event handler directly when necessary for TRADE_SKILL_SHOW
	UIParent:UnregisterEvent("TRADE_SKILL_SHOW")
end



-- ============================================================================
-- General Module Functions
-- ============================================================================

function TradeSkill:EventHandler(event, ...)
	-- deal with TRADE_SKILL_SHOW / TRADE_SKILL_CLOSE specially
	if event == "TRADE_SKILL_SHOW" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
		TSMAPI.Threading:SendMsg(private.managerThreadId, "SHOW")
		return
	elseif event == "TRADE_SKILL_CLOSE" or event == "GARRISON_TRADESKILL_NPC_CLOSED" then
		TSMAPI.Threading:SendMsg(private.managerThreadId, "HIDE")
		return
	end

	-- if we are changing professions or not currently shown, just ignore this event
	if not private.currentProfession or not TradeSkill:GetVisibilityInfo().frame or TSM:GetCurrentProfessionName() ~= private.currentProfession then return end

	if event == "TRADE_SKILL_LIST_UPDATE" or event == "TRADE_SKILL_FILTER_UPDATE" then
		private:OnProfessionUpdate()
		private:UpdateCooldownsFrame()
	elseif event == "UPDATE_TRADESKILL_RECAST" then
		private.frame.professionsTab.craftInfoFrame.buttonsFrame.inputBox:SetNumber(C_TradeSkillUI.GetRecipeRepeatCount())
	elseif event == "CHAT_MSG_SKILL" then
		-- update the skill level of the player's tradeskill
		if C_TradeSkillUI.IsTradeSkillGuild() or C_TradeSkillUI.IsNPCCrafting() then return end
		local skillName = TSM:GetCurrentProfessionName()
		local level, maxLevel = select(3, C_TradeSkillUI.GetTradeSkillLine())
		local isLinked, linkedPlayer = C_TradeSkillUI.IsTradeSkillLinked()
		local playerName = linkedPlayer or UnitName("player")
		if skillName and skillName ~= "UNKNOWN" and not isLinked and TSM.db.factionrealm.playerProfessions[playerName] and TSM.db.factionrealm.playerProfessions[playerName][skillName] then
			TSM.db.factionrealm.playerProfessions[playerName][skillName].level = level
			TSM.db.factionrealm.playerProfessions[playerName][skillName].maxLevel = maxLevel
			TSMAPI.Sync:KeyUpdated(TSM.db.factionrealm.playerProfessions, playerName)
		end
	elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
		local unit, _, _, _, spellId = ...
		if unit ~= "player" or not TSM.db.factionrealm.crafts[spellId] then return end
		if not TradeSkill.isCrafting or TradeSkill.isCrafting.spellId ~= spellId then return end
		-- remove one from the queue
		if TSM.Queue:Remove(spellId, 1) then
			private:UpdateCooldownsFrame()
			private:OnProfessionUpdate()
		end
		TradeSkill.isCrafting.quantity = TradeSkill.isCrafting.quantity - 1
	elseif event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_FAILED_QUIET" then
		local unit, _, _, _, spellId = ...
		if unit ~= "player" then return end

		if TradeSkill.isCrafting and spellId == TradeSkill.isCrafting.spellId then
			TradeSkill.isCrafting.quantity = 0
		end
	elseif event == "BAG_UPDATE" then
		private:UpdateCooldownsFrame()
		private:OnProfessionUpdate()
	else
		TSMAPI:Assert(false, "Unexpected event: "..tostring(event))
	end
end

function TradeSkill:GetVisibilityInfo()
	local result = {}
	result.frame = private.frame and private.frame:IsVisible()
	if result.frame then
		-- frame is created and visible, so populate visible status children
		for i, v in pairs(TSMCraftingTradeSkillFrame) do
			if type(v) == "table" and v.tsmFrameType == "Frame" then
				result[i] = v:IsVisible()
			end
		end
	end
	return result
end



-- ============================================================================
-- TradeSkill Creation Functions
-- ============================================================================

function private:Create()
	if private.frame then return end

	local frameDefaults = {
		x = 100,
		y = 300,
		width = 450,
		height = 500,
		scale = 1,
	}
	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local frameInfo = {
		type = "MovableFrame",
		name = "TSMCraftingTradeSkillFrame",
		movableDefaults = frameDefaults,
		minResize = {400, 400},
		scripts = {"OnHide"},
		children = {
			{
				type = "Text",
				text = format("TSM_Crafting - %s", strfind(TSM._version, "@") and "Dev" or TSM._version),
				textFont = {TSMAPI.Design:GetContentFont(), 18},
				points = {{"TOP", 0, -3}},
			},
			{
				type = "HLine",
				offset = -24,
			},
			{
				type = "VLine",
				offset = 0,
				size = {2, 25},
				points = {{"TOPRIGHT", -25, -1}},
			},
			{
				type = "Button",
				key = "closeBtn",
				text = "X",
				textHeight = 18,
				size = {19, 19},
				points = {{"TOPRIGHT", -3, -3}},
				scripts = {"OnClick"},
			},
			{
				type = "Button",
				key = "professionsBtn",
				text = L["Professions"],
				textHeight = 16,
				size = {105, 20},
				points = {{"TOPLEFT", 5, -30}},
				scripts = {"OnClick"},
			},
			{
				type = "Button",
				key = "groupsBtn",
				text = L["TSM Groups"],
				textHeight = 16,
				size = {105, 0},
				points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}},
				scripts = {"OnClick"},
			},
			{
				type = "VLine",
				offset = 0,
				points = {{"TOPLEFT", 224, -25}, {"BOTTOMLEFT", BFC.PARENT, "TOPLEFT", 224, -55}},
			},
			{
				type = "Button",
				key = "gatherBtn",
				text = L["Gather"],
				textHeight = 16,
				size = {80, 0},
				points = {{"TOPLEFT", "groupsBtn", "TOPRIGHT", 10, 0}, {"BOTTOMLEFT", "groupsBtn", "BOTTOMRIGHT", 10, 0}},
				scripts = {"OnClick"},
			},
			{
				type = "Button",
				key = "queueBtn",
				text = L["Show Queue"],
				textHeight = 16,
				points = {{"TOPLEFT", BFC.PREV, "TOPRIGHT", 5, 0}, {"BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0}, {"TOPRIGHT", -5, -5}},
				scripts = {"OnClick"},
			},
			{
				type = "HLine",
				offset = -54,
			},
			{
				type = "Frame",
				key = "prompt",
				hidden = true,
				points = "ALL",
				children = {
					{
						type = "Text",
						key = "text",
						text = L["Would you like to automatically create some TradeSkillMaster groups for this profession?"],
						textFont = {TSMAPI.Design:GetContentFont("normal")},
						size = {0, 100},
						points = {{"LEFT", 5, 50}, {"RIGHT", -5, 50}},
					},
					{
						type = "Button",
						key = "yesBtn",
						text = YES,
						textHeight = 16,
						size = {100, 20},
						points = {{"CENTER", -110, 0}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "laterBtn",
						text = L["Ask Later"],
						textHeight = 16,
						size = {100, 20},
						points = {{"CENTER"}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "noBtn",
						text = L["No Thanks"],
						textHeight = 16,
						size = {100, 20},
						points = {{"CENTER", 110, 0}},
						scripts = {"OnClick"},
					},
				},
			},
			{
				type = "Frame",
				key = "cooldowns",
				hidden = true,
				points = "ALL",
				scripts = {"OnMouseDown", "OnMouseUp"},
				children = {
					{
						type = "Text",
						text = L["Below is a list of crafts that have been smartly added. You can configure what crafts are listed here in the \"Cooldowns\" tab of the \"Crafting\" page within the main TSM window. Quest items can be removed through the TSM crafting options.\n\nSimply click on the row in the table below to craft it."],
						textFont = {TSMAPI.Design:GetContentFont("normal")},
						size = {0, 100},
						points = {{"TOPLEFT", 5, -20}, {"TOPRIGHT", -5, -20}},
					},
					{
						type = "ScrollingTableFrame",
						key = "craftST",
						headFontSize = 14,
						stCols = {{name = L["Smart Crafts"], width = 1, align="CENTER"}},
						stDisableSelection = true,
						points = {{"TOPLEFT", BFC.PREV, "BOTTOMLEFT", 0, -10}, {"BOTTOMRIGHT", -5, 40}},
						scripts = {"OnClick"},
					},
					{
						type = "Button",
						key = "continueBtn",
						text = L["Skip Smart Crafts and Continue to Profession"],
						textHeight = 18,
						size = {0, 30},
						points = {{"BOTTOMLEFT", 5, 5}, {"BOTTOMRIGHT", -5, 5}},
						scripts = {"OnClick"},
					},
				},
			},
			TradeSkill.Professions:GetFrameInfo(),
			TradeSkill.Groups:GetFrameInfo(),
			TradeSkill.Queue:GetFrameInfo(),
			TradeSkill.Gather:GetFrameInfo(),
		},
		handlers = {
			OnHide = function()
				if private.noHide then return end
				private.CloseProfession()
			end,
			-- navigation button handlers
			closeBtn = {
				OnClick = function(self)
					TSMAPI.Threading:SendMsg(private.managerThreadId, "HIDE")
                    TSM.TradeSkill.Gather:ResetSessionOptions()
				end,
			},
			professionsBtn = {
				OnClick = function(self)
					TradeSkill.Professions:OnButtonClicked(private.frame)
				end,
			},
			groupsBtn = {
				OnClick = function(self)
					TradeSkill.Groups:OnButtonClicked(private.frame)
				end,
			},
			gatherBtn = {
				OnClick = function(self)
					TradeSkill.Gather:OnButtonClicked(private.frame)
				end,
			},
			queueBtn = {
				OnClick = function(self)
					TradeSkill.Queue:OnButtonClicked(private.frame)
				end,
			},
			-- prompt frame handlers
			prompt = {
				yesBtn = {
					OnClick = function(self)
						TSM.TradeSkillScanner:CreatePresetGroups()
						local playerName = UnitName("player")
						TSM.db.factionrealm.playerProfessions[playerName][TSM:GetCurrentProfessionName()].prompted = true
						TSMAPI.Sync:KeyUpdated(TSM.db.factionrealm.playerProfessions, playerName)
						self:GetParent():Hide()
						private.frame.professionsTab:Show()
					end,
				},
				laterBtn = {
					OnClick = function(self)
						self:GetParent():Hide()
						private.frame.professionsTab:Show()
					end,
				},
				noBtn = {
					OnClick = function(self)
						local playerName = UnitName("player")
						TSM.db.factionrealm.playerProfessions[playerName][TSM:GetCurrentProfessionName()].prompted = true
						TSMAPI.Sync:KeyUpdated(TSM.db.factionrealm.playerProfessions, playerName)
						self:GetParent():Hide()
						private.frame.professionsTab:Show()
					end,
				},
			},
			-- cooldown frame handlers
			cooldowns = {
				OnMouseDown = function(self)
					self:GetParent():StartMoving()
				end,
				OnMouseUp = function(self)
					self:GetParent():StopMovingOrSizing()
				end,
				continueBtn = {
					OnClick = function(self)
						self:GetParent():Hide()
						private.frame.professionsTab:Show()
						TradeSkill.Queue:UpdateFrameStatus(private.frame)
					end,
				},
				craftST = {
					OnClick = function(self, data, _, button)
						TradeSkill:CastTradeSkill(data.spellId, data.quantity)
					end,
				},
			},
		},
	}
	local frame = TSMAPI.GUI:BuildFrame(frameInfo)
	TSMAPI.Design:SetFrameBackdropColor(frame)
	tinsert(UISpecialFrames, "TSMCraftingTradeSkillFrame")
	private.frame = frame

	-- prompt frame
	frame.prompt:EnableMouse(true)
	frame.prompt:SetFrameStrata("HIGH")
	TSMAPI.Design:SetFrameBackdropColor(frame.prompt)

	-- cooldowns frame
	frame.cooldowns:EnableMouse(true)
	frame.cooldowns:SetFrameStrata("HIGH")
	TSMAPI.Design:SetFrameBackdropColor(frame.cooldowns)

	-- queue frame
	frame.queue:EnableMouse(true)
	TSMAPI.Design:SetFrameBackdropColor(frame.queue)

	-- gather frame
	frame.gather:SetFrameStrata("HIGH")
	frame.gather:EnableMouse(true)
	TSMAPI.Design:SetFrameBackdropColor(frame.gather)

	-- professions tab
	TSMAPI.Design:SetFrameColor(frame.professionsTab.craftInfoFrame)
end

function TradeSkill:ToggleHelpPlate(frame, info, btn, isUser)
	if not HelpPlate_IsShowing(info) then
		HelpPlate:SetParent(frame)
		HelpPlate:SetFrameStrata("DIALOG")
		HelpPlate_Show(info, frame, btn, isUser)
	else
		HelpPlate:SetParent(UIParent)
		HelpPlate:SetFrameStrata("DIALOG")
		HelpPlate_Hide(isUser)
	end
end

function private:CreateSwitchButton()
	if private.switchBtn then return end
	local frameInfo = {
		type = "Button",
		parent = UIParent,
		text = "",
		textHeight = 16,
		scripts = {"OnClick"},
		handlers = {
			OnClick = function(self)
				TSM.db.global.showingDefaultFrame = not TSM.db.global.showingDefaultFrame or nil
				TSMAPI.Threading:SendMsg(private.managerThreadId, "SWITCH")
			end,
		},
	}

	local btn = TSMAPI.GUI:BuildFrame(frameInfo)
	btn:Hide()
	-- can't specify an OnShow handler on a button built via TSMAPI.GUI:BuildFrame(), so let's hook it
	TradeSkill:HookScript(btn, "OnShow", function() btn:Update() end)
	btn.Update = function(self)
		local parent = TSM.db.global.showingDefaultFrame and TradeSkillFrame or private.frame
		if not parent then return end
		self:ClearAllPoints()
		self:SetParent(parent)
		local color, text = nil, nil
		if TSM.db.global.showingDefaultFrame then
			self:SetPoint("TOPLEFT", 55, -3)
			color = TSMAPI.Design:GetInlineColor("link")
			text = "TSM"
		else
			self:SetPoint("TOPLEFT", 25, -4)
			color = "|cffff0000"
			text = DEFAULT
		end
		self:SetWidth(60)
		self:SetHeight(18)
		self:SetText(color..text.."|r")
		self:Show()
	end
	private.switchBtn = btn
end

function private:UpdateCooldownsFrame()
	if not private.frame.cooldowns:IsVisible() then return end
	local potentialCrafts = {}
	local stData = {}
	local currentPlayer = UnitName("player")

	if TSM.db.global.questSmartCrafting then
		local numEntries, numQuests = GetNumQuestLogEntries()

		for q = 1, numEntries do
			local title, level, suggestedGroup, isHeader = GetQuestLogTitle(q)
			if not isHeader then
				for l = 1, GetNumQuestLeaderBoards(q) do
					local text, type, finished = GetQuestLogLeaderBoard(l, q)

					if not finished and type == "item" then
						local have, need, item
						if GetLocale() == "ruRU" then
							item, have, need = strmatch(text,"(.+): (%d+)/(%d+)")
						else
							have, need, item = strmatch(text,"(%d+)/(%d+) (.+)")
						end

						if have ~= nil and need ~= nil and item ~= nil then
							if need - have > 0 then
								tinsert(potentialCrafts, { need = need - have, item = item })
							end
						end
					end
				end
			end
		end
	end

	for _, spellId in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
		local info = C_TradeSkillUI.GetRecipeInfo(spellId)
		local numAvailable = info.numAvailable
		local craft = TSM.db.factionrealm.crafts[spellId]
		local cooldown, isDaily = C_TradeSkillUI.GetRecipeCooldown(spellId)
		if not cooldown and isDaily and craft and craft.cooldownTimes and craft.cooldownTimes[currentPlayer] and craft.cooldownTimes[currentPlayer].prompt then
			if numAvailable > 0 then
				tinsert(stData, {cols={{value="|cff00ff00"..info.name.."|r"}}, spellId = spellId, quantity = 1})
				numAvailable = numAvailable - 1
			else
				-- we don't have the mats on-hand, so add it to the queue
				TSM.Queue:SetNumQueued(spellId, 1)
			end
		end

		local totalNeeded = 0
		for _, pc in pairs(potentialCrafts) do
			if craft and pc.item == info.name then
				totalNeeded = totalNeeded + pc.need
			end
		end

		if totalNeeded > 0 then
			if numAvailable >= totalNeeded then
				tinsert(stData, {cols={{value=format("|cff00ff00%s|r%s",info.name,totalNeeded == 1 and '' or ' ('..tostring(totalNeeded)..')') }}, spellId = spellId, quantity = totalNeeded})
			else
				TSM.Queue:SetNumQueued(spellId, totalNeeded)
			end
		end
	end

	private.frame.cooldowns.craftST:SetData(stData)
	if #stData == 0 then
		private.frame.cooldowns:Hide()
		private.frame.professionsTab:Show()
		TradeSkill.Queue:UpdateFrameStatus(private.frame)
	else
		private.frame.queue:Hide()
	end
end



-- ============================================================================
-- TradeSkill Show / Hide Functions
-- ============================================================================

function private.BlizzardProfessionFrameOnHide()
	if private.noHide then return end
	private.CloseProfession()
end

function private.SetBlizzardProfessionFrameVisible(visible)
	if visible and not (TradeSkillFrame and TradeSkillFrame:IsVisible()) then
		TradeSkillFrame_LoadUI()
		TradeSkillFrame:SetScript("OnHide", private.BlizzardProfessionFrameOnHide)
		ShowUIPanel(TradeSkillFrame)
		TradeSkillFrame:OnDataSourceChanged()
		private:CreateSwitchButton()
		private.switchBtn:Show()
		private.switchBtn:Update()
	elseif not visible and TradeSkillFrame then
		private.noHide = true
		HideUIPanel(TradeSkillFrame)
		private.noHide = nil
	end
end

function private.SetTSMCraftingProfessionFrameVisible(visible)
	if visible and not (private.frame and private.frame:IsVisible()) then
		private:Create()
		private:CreateSwitchButton()
		private.frame:Show()
		private.switchBtn:Show()
		private.switchBtn:Update()
		private.frame.professionsBtn:Enable()
		TradeSkill.Queue:UpdateFrameStatus(private.frame)
		local isLinked, linkedPlayer = C_TradeSkillUI.IsTradeSkillLinked()
		local playerName = linkedPlayer or UnitName("player")
		local professionName = TSM:GetCurrentProfessionName()
		if not isLinked and TSM.db.factionrealm.playerProfessions[playerName][professionName] and not TSM.db.factionrealm.playerProfessions[playerName][professionName].prompted then
			private.frame.prompt:Show()
		else
			-- show the cooldowns frame first, the profession frame will show automatically if there's no CD crafts to prompt for
			private.frame.cooldowns:Show()
			private:UpdateCooldownsFrame()
		end
	elseif not visible and private.frame then
		private.noHide = true
		private.frame:Hide()
		private.noHide = nil
	end
end

function private.CloseProfession()
	if not C_TradeSkillUI.GetTradeSkillLine() then return end
	C_TradeSkillUI.CloseTradeSkill()
	C_Garrison.CloseGarrisonTradeskillNPC()
end

function private.ProfessionScanCompleteCallback()
	private.scanSuccess = true
end

function private.ScanOpenProfessionThread(self)
	-- clear filters
	TradeSkill:ClearFilters()

	-- scan the profession
	local isLinked, linkedPlayer = C_TradeSkillUI.IsTradeSkillLinked()
	local playerName = linkedPlayer or UnitName("player")
	local professionName = TSM:GetCurrentProfessionName()
	private.scanSuccess = nil
	self:WaitForThread(TSM.TradeSkillScanner:ScanProfession(professionName, playerName, isLinked, private.ProfessionScanCompleteCallback))
	TSM:LOG_INFO("TradeSkill scanned (success=%s)", tostring(private.scanSuccess))
	if not private.scanSuccess and not private.noShow then
		TSM:Print(L["Crafting failed to scan your profession. Please close and re-open it to to allow Crafting to scan and provide pricing info for this profession."])
	end
end

function private.ProfessionWindowManagerHandleShowThread(self)
	if C_TradeSkillUI.GetTradeSkillLine() == private.currentProfessionId then return end

	if not TradeSkillFrame then
		-- need to make sure Blizzard_TradeSkillUI is loaded cause we rely on some of its tables
		TradeSkillFrame_LoadUI()
		TradeSkillFrame:SetScript("OnHide", nil)
		HideUIPanel(TradeSkillFrame)
		TradeSkillFrame.RecipeList.collapsedCategories = {}
	end

	-- hide any currently-visible frames
	private.SetBlizzardProfessionFrameVisible(false)
	private.SetTSMCraftingProfessionFrameVisible(false)

	-- wait for the the profession to actually load
	while TSM:GetCurrentProfessionName() == "UNKNOWN" or InCombatLockdown() do self:Yield(true) end
	private.currentProfessionId = C_TradeSkillUI.GetTradeSkillLine()

	-- check if it's a profession we don't support showing our frame for (runeforging, guild profession, or random linked profession)
	local isLinked, linkedPlayer = C_TradeSkillUI.IsTradeSkillLinked()
	if TSM:GetCurrentProfessionName() == GetSpellInfo(53428) or C_TradeSkillUI.IsTradeSkillGuild() or (isLinked and (not TSMAPI.Player:GetCharacters()[linkedPlayer] or C_TradeSkillUI.IsNPCCrafting())) then
		-- we don't support this profession, so show Blizzard's frame without the switch button
		TSM:LOG_INFO("Aborting for unsupported profession (isRuneforging=%s, isGuild=%s, linkedPlayer=%s)", TSM:GetCurrentProfessionName() == GetSpellInfo(53428), C_TradeSkillUI.IsTradeSkillGuild(), tostring(linkedPlayer))
		private.SetBlizzardProfessionFrameVisible(true)
		TSMAPI:Assert(not private.noShow)
		return
	end

	-- scan the profession
	private.ScanOpenProfessionThread(self)

	if private.noShow then
		private.CloseProfession()
		private.noShow = nil
		return
	end

	if TSM.db.global.showingDefaultFrame then
		-- we should just show Blizzard's frame
		TSM:LOG_INFO("Showing default profession frame")
		private.SetBlizzardProfessionFrameVisible(true)
	else
		-- show our profession window
		TSM:LOG_INFO("Showing our profession frame")
		private.SetTSMCraftingProfessionFrameVisible(true)
	end
	private.currentProfession = TSM:GetCurrentProfessionName()
end

function private.ProfessionWindowManagerThread(self)
	self:SetThreadName("PROFESSION_WINDOW_MANAGER")

	while true do
		local event = self:ReceiveMsg()
		if event == "SHOW" then
			private.ProfessionWindowManagerHandleShowThread(self)
		elseif event == "SWITCH" then
			TradeSkill:ClearFilters()
			private.SetBlizzardProfessionFrameVisible(TSM.db.global.showingDefaultFrame)
			private.SetTSMCraftingProfessionFrameVisible(not TSM.db.global.showingDefaultFrame)
		elseif event == "HIDE" then
			-- hide any currently-visible frames
			private.SetBlizzardProfessionFrameVisible(false)
			private.SetTSMCraftingProfessionFrameVisible(false)
			private.CloseProfession()
			private.currentProfessionId = nil
			private.currentProfession = nil
		else
			TSMAPI:Assert(false, "Unexpected event: "..tostring(event))
		end
	end
end



-- ============================================================================
-- TradeSkill Action Functions
-- ============================================================================

function private:OnProfessionUpdate()
	TSMAPI.Delay:AfterFrame("craftingProfessionUpdateThrottle", 5, TradeSkill.Professions.UpdateST)
	TSMAPI.Delay:AfterFrame("craftingQueueUpdateThrottle", 5, TradeSkill.Queue.Update)
end

function TradeSkill:ClearFilters()
	Lib_CloseDropDownMenus()
	C_TradeSkillUI.ClearInventorySlotFilter()
	C_TradeSkillUI.ClearRecipeCategoryFilter()
	C_TradeSkillUI.SetRecipeItemNameFilter(nil)
	C_TradeSkillUI.ClearRecipeSourceTypeFilter()
	C_TradeSkillUI.SetOnlyShowMakeableRecipes(false)
	C_TradeSkillUI.SetOnlyShowSkillUpRecipes(false)
	C_TradeSkillUI.SetOnlyShowLearnedRecipes(true)
	C_TradeSkillUI.SetOnlyShowUnlearnedRecipes(false)
	PanelTemplates_SetTab(TradeSkillFrame.RecipeList, 1)
	if private.frame then
		-- reset the search bar
		private.frame.professionsTab.searchBar:SetTextColor(1, 1, 1, 0.5)
		private.frame.professionsTab.searchBar:ClearFocus()
		private.frame.professionsTab.searchBar:SetText(SEARCH)
	end
end

function TradeSkill:CastTradeSkill(spellId, quantity, vellum)
	TradeSkill.Professions:SetSelectedTradeSkill(spellId)
	quantity = vellum and 1 or quantity
	C_TradeSkillUI.CraftRecipe(spellId, quantity)
	TradeSkill.isCrafting = {quantity=quantity, spellId=spellId}
	if vellum then
		UseItemByName(vellum)
	end
end

function TradeSkill:OpenFirstProfession()
	local playerName = UnitName("player")
	if not playerName then return end
	local secondaryProfession
	if TSM.db.factionrealm.playerProfessions[playerName] then
		for profession, data in pairs(TSM.db.factionrealm.playerProfessions[playerName]) do
			if data.isSecondary then
				secondaryProfession = profession
			else
				CastSpellByName(profession)
				return
			end
		end
	end
	if secondaryProfession then
		CastSpellByName(secondaryProfession)
		return
	end
	-- they don't have any professions
	-- FIXME: opening the TSM crafting window without a profession was removed for legion
end


function private.LinkedProfessionScanThread(self)
	self:SetThreadName("CRAFTING_LINKED_PROFESSION_SCAN")
	self:Sleep(5)

	local accountPlayers = TSMAPI.Player:GetCharacters(true)
	local scanInfo = {}
	while true do
		for playerName, professions in pairs(TSM.db.factionrealm.playerProfessions) do
			local connectedPlayer, lastUpdate = TSMAPI.Sync:GetStatus(TSM.db.factionrealm.playerProfessions, playerName)
			if not accountPlayers[playerName] and connectedPlayer == playerName then
				for professionName, data in pairs(professions) do
					if data.link then
						if scanInfo[data.link] then
							scanInfo[data.link].hasUpdate = lastUpdate ~= scanInfo[data.link].lastUpdate
							scanInfo[data.link].lastUpdate = lastUpdate
						else
							scanInfo[data.link] = {player=playerName, profession=professionName, hasUpdate=true, lastUpdate=lastUpdate}
						end
					end
				end
			end
		end

		-- wait for a free moment to do the scan
		while (TradeSkillFrame and TradeSkillFrame:IsVisible()) or TradeSkill:GetVisibilityInfo().frame or TSM:GetCurrentProfessionName() ~= "UNKNOWN" or InCombatLockdown() or GetUIPanel("left") or GetUIPanel("doublewide") or GetUIPanel("center") or GetUIPanel("fullscreen") do self:Yield(true) end

		-- show the linked professions
		for link, info in pairs(scanInfo) do
			if info.hasUpdate then
				private.noShow = true
				local tradeString = strsub(select(3, ("|"):split(link)), 2)
				SetItemRef(tradeString, link) -- opens the profession from the link

				while private.noShow do self:Yield(true) end
				TSM:LOG_INFO("Scanned linked profession (%s from %s)!", info.profession, info.player)
				info.hasUpdate = nil
				self:Sleep(1)
			end
		end
		self:Sleep(2)
	end
end
