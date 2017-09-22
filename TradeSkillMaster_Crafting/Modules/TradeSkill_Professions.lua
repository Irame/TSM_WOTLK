-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local TradeSkill = TSM:GetModule("TradeSkill")
local Professions = TradeSkill:NewModule("Professions", "AceHook-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local private = { priceTextCache = { lastClear = 0 }, craftTimeInfo = { timeout = 0, endTime = 0 }, selectedTradeSkill = nil, stIndexLookup = {}, collapsedCategories = {} }


-- ============================================================================
-- Methods to Add to the TradeSkill Module
-- ============================================================================

function Professions:OnInitialize()
	-- initialize things specific to the professions tab
	Professions:RawHook("ChatEdit_InsertLink", private.InsertLinkHook, true)
	TSMAPI.Delay:AfterTime("craftTimeText", 0.5, private.UpdateCraftTimeText, 0.5)
	TSMAPI.Delay:AfterTime("craftingUpdateTradeSkill", 1, function() Professions:SetSelectedTradeSkill(private.selectedTradeSkill) end, 0.1)
	Professions:RegisterEvent("TRADE_SKILL_UPDATE", private.UpdateProfessionDropdown)
end

function private.SetSlotFilter(inventorySlotIndex, categoryId, subCategoryId)
	C_TradeSkillUI.ClearInventorySlotFilter()
	C_TradeSkillUI.ClearRecipeCategoryFilter()

	if inventorySlotIndex then
		C_TradeSkillUI.SetInventorySlotFilter(inventorySlotIndex, true, true)
	end

	if categoryId or subCategoryId then
		C_TradeSkillUI.SetRecipeCategoryFilter(categoryId, subCategoryId)
	end
end

function private.InitializeDropdown(self, level)
	local info = Lib_UIDropDownMenu_CreateInfo()
	if level == 1 then
		info.text = CRAFT_IS_MAKEABLE
		info.func = function()
			C_TradeSkillUI.SetOnlyShowMakeableRecipes(not C_TradeSkillUI.GetOnlyShowMakeableRecipes())
		end
		info.keepShownOnClick = true
		info.checked = C_TradeSkillUI.GetOnlyShowMakeableRecipes()
		info.isNotRadio = true
		Lib_UIDropDownMenu_AddButton(info, level)

		if not C_TradeSkillUI.IsTradeSkillGuild() and not C_TradeSkillUI.IsNPCCrafting() then
			info.text = TRADESKILL_FILTER_HAS_SKILL_UP
			info.func = function()
				C_TradeSkillUI.SetOnlyShowSkillUpRecipes(not C_TradeSkillUI.GetOnlyShowSkillUpRecipes())
			end
			info.keepShownOnClick = true
			info.checked = C_TradeSkillUI.GetOnlyShowSkillUpRecipes()
			info.isNotRadio = true
			Lib_UIDropDownMenu_AddButton(info, level)
		end

		info.checked = 	nil
		info.isNotRadio = nil
		info.func =  nil
		info.notCheckable = true
		info.keepShownOnClick = false
		info.hasArrow = true

		info.text = TRADESKILL_FILTER_SLOTS
		info.value = 1
		Lib_UIDropDownMenu_AddButton(info, level)

		info.text = TRADESKILL_FILTER_CATEGORY
		info.value = 2
		Lib_UIDropDownMenu_AddButton(info, level)

		info.text = SOURCES
		info.value = 3
		Lib_UIDropDownMenu_AddButton(info, level)
	elseif level == 2 then
		if LIB_UIDROPDOWNMENU_MENU_VALUE == 1 then
			local inventorySlots = {C_TradeSkillUI.GetAllFilterableInventorySlots()}
			for i, inventorySlot in ipairs(inventorySlots) do
				info.text = inventorySlot
				info.func = function() private.SetSlotFilter(i) end
				info.notCheckable = true
				info.hasArrow = false
				Lib_UIDropDownMenu_AddButton(info, level)
			end
		elseif LIB_UIDROPDOWNMENU_MENU_VALUE == 2 then
			local categories = {C_TradeSkillUI.GetCategories()}
			for i, categoryId in ipairs(categories) do
				local categoryData = C_TradeSkillUI.GetCategoryInfo(categoryId)
				info.text = categoryData.name
				info.func = function() private.SetSlotFilter(nil, categoryId) end
				info.notCheckable = true
				info.hasArrow = select("#", C_TradeSkillUI.GetSubCategories(categoryId)) > 0
				info.value = categoryId
				Lib_UIDropDownMenu_AddButton(info, level)
			end
		elseif LIB_UIDROPDOWNMENU_MENU_VALUE == 3 then
			info.hasArrow = false
			info.isNotRadio = true
			info.notCheckable = true
			info.keepShownOnClick = true
			info.text = CHECK_ALL
			info.func = function()
				TradeSkillFrame_SetAllSourcesFiltered(false)
				Lib_UIDropDownMenu_Refresh(TSMTradeSkillFilterDropDown, 3, 2)
			end
			Lib_UIDropDownMenu_AddButton(info, level)

			info.text = UNCHECK_ALL
			info.func = function()
				TradeSkillFrame_SetAllSourcesFiltered(true)
				Lib_UIDropDownMenu_Refresh(TSMTradeSkillFilterDropDown, 3, 2)
			end
			Lib_UIDropDownMenu_AddButton(info, level)

			info.notCheckable = false
			for i = 1, C_PetJournal.GetNumPetSources() do
				if C_TradeSkillUI.IsAnyRecipeFromSource(i) then
					info.text = _G["BATTLE_PET_SOURCE_" .. i]
					info.func = function(_, _, _, value) C_TradeSkillUI.SetRecipeSourceTypeFilter(i, not value) end
					info.checked = function() return not C_TradeSkillUI.IsRecipeSourceTypeFiltered(i) end
					Lib_UIDropDownMenu_AddButton(info, level)
				end
			end
		end
	elseif level == 3 then
		for _, subCategoryId in ipairs({C_TradeSkillUI.GetSubCategories(LIB_UIDROPDOWNMENU_MENU_VALUE)}) do
			info.text = C_TradeSkillUI.GetCategoryInfo(subCategoryId).name
			info.func = function() private.SetSlotFilter(nil, LIB_UIDROPDOWNMENU_MENU_VALUE, subCategoryId) end
			info.notCheckable = true
			info.value = subCategoryId
			Lib_UIDropDownMenu_AddButton(info, level)
		end
	end
end

function Professions:GetFrameInfo()
	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	local queueBtnTooltipColor = TSMAPI.Design:GetInlineColor("link")
	if not TSMTradeSkillFilterDropDown then
		TSMTradeSkillFilterDropDown = CreateFrame("Frame", "TSMTradeSkillFilterDropDown", TSMCraftingTradeSkillFrame, "Lib_UIDropDownMenuTemplate")
		Lib_UIDropDownMenu_Initialize(TSMTradeSkillFilterDropDown, private.InitializeDropdown, "MENU")
		TSMTradeSkillFilterDropDownText:SetJustifyH("CENTER")
		TSMTradeSkillFilterDropDownButton:Show()
	end
	return {
		type = "Frame",
		key = "professionsTab",
		hidden = true,
		points = { { "TOPLEFT", 0, -59 }, { "BOTTOMRIGHT" } },
		scripts = { "OnShow" },
		children = {
			{
				type = "Dropdown",
				key = "dropdown",
				points = { { "TOPLEFT", 3, -4 }, { "TOPRIGHT", -47, -4 } },
				scripts = { "OnValueChanged" },
				tooltip = L["Select one of your characters' professions to browse."],
			},
			{
				type = "Button",
				key = "linkBtn",
				text = L["Link"],
				textHeight = 14,
				size = { 44, 26 },
				points = { { "TOPRIGHT", -5, -4 } },
				scripts = { "OnClick" },
			},
			{
				type = "InputBox",
				key = "searchBar",
				name = "TSMCraftingSearchBar",
				text = SEARCH,
				textColor = { 1, 1, 1, 0.5 },
				size = { 240, 24 },
				points = { { "TOPLEFT", 5, -35 } },
				scripts = { "OnEditFocusGained", "OnEditFocusLost", "OnTextChanged", "OnEnterPressed" },
			},
			{
				type = "Button",
				key = "clearFilterBtn",
				text = L["Clear Filters"],
				textHeight = 14,
				size = { 80, 24 },
				points = { { "TOPLEFT", "searchBar", "TOPRIGHT", 5, 0 } },
				scripts = { "OnClick" },
			},
			{
				type = "Button",
				key = "filterBtn",
				name = "TSMCraftingFilterButton",
				text = L["Filters >>"],
				textHeight = 14,
				size = { nil, 24 },
				points = { { "TOPLEFT", "clearFilterBtn", "TOPRIGHT", 5, 0 }, { "TOPRIGHT", -5, -35 } },
				scripts = { "OnClick" },
			},
			{
				type = "HLine",
				offset = -64,
			},
			{
				type = "ScrollingTableFrame",
				key = "st",
				stCols = { { name = L["Name"], width = 0.8 }, { name = private:GetProfessionsTabPriceColumnText(), width = 0.2 } },
				points = { { "TOPLEFT", 5, -70 }, { "BOTTOMRIGHT", -5, 177 } },
				scripts = { "OnClick", "OnColumnClick", "OnEnter", "OnLeave" },
			},
			{
				type = "Frame",
				key = "craftInfoFrame",
				points = { { "TOPLEFT", "stContainer", "BOTTOMLEFT", 0, -4 }, { "BOTTOMRIGHT", -3, 3 } },
				children = {
					{
						type = "Frame",
						key = "infoFrame",
						points = { { "TOPLEFT", 3, -3 }, { "BOTTOMLEFT", 3, 53 }, { "TOPRIGHT", -220, -3 } },
						children = {
							{
								type = "IconButton",
								key = "icon",
								size = { 40, 40 },
								points = { { "TOPLEFT" } },
								scripts = { "OnEnter", "OnLeave", "OnClick" },
							},
							{
								type = "Text",
								key = "nameText",
								textHeight = 12,
								justify = { "LEFT" },
								points = { { "TOPLEFT", "icon", "TOPRIGHT", 4, 0 }, { "TOPRIGHT" } },
							},
							{
								type = "Text",
								key = "toolsText",
								textHeight = 12,
								justify = { "LEFT" },
								points = { { "TOPLEFT", "nameText", "BOTTOMLEFT", 0, -2 }, { "TOPRIGHT", "nameText", "BOTTOMRIGHT", 0, -2 } },
							},
							{
								type = "Text",
								key = "cooldownText",
								textHeight = 11,
								justify = { "LEFT" },
								points = { { "TOPLEFT", "toolsText", "BOTTOMLEFT", 0, -2 }, { "TOPRIGHT", "toolsText", "BOTTOMRIGHT", 0, -2 } },
							},
							{
								type = "Text",
								key = "descText",
								textHeight = 11,
								justify = { "LEFT", "TOP" },
								points = { { "TOPLEFT", "icon", "BOTTOMLEFT", 0, -2 }, { "BOTTOMRIGHT" } },
							},
						},
					},
					{
						type = "HLine",
						offset = 0,
						points = { { "TOPLEFT", "infoFrame", "BOTTOMLEFT", -1, 0 }, { "TOPRIGHT", "infoFrame", "BOTTOMRIGHT", 1, 0 } },
					},
					{
						type = "VLine",
						offset = 0,
						points = { { "TOPLEFT", "infoFrame", "TOPRIGHT", 1, 3 }, { "BOTTOMLEFT", "infoFrame", "BOTTOMRIGHT", 1, -53 } },
					},
					{
						type = "Frame",
						key = "matsFrame",
						points = { { "TOPLEFT", "infoFrame", "TOPRIGHT", 5, 0 }, { "TOPRIGHT" }, { "BOTTOMRIGHT" } },
						children = {
							{
								type = "IconButton",
								key = "sizer",
								icon = "Interface\\Addons\\TradeSkillMaster\\Media\\Sizer",
								size = { 16, 16 },
								points = { { "BOTTOMRIGHT", -2, 2 } },
								scripts = { "OnMouseDown", "OnMouseUp" },
							},
							{
								type = "Text",
								key = "castText",
								textSize = "small",
								justify = { "RIGHT", "BOTTOM" },
								size = { 0, 18 },
								points = { { "BOTTOMRIGHT", -22, 3 } },
							},
							{
								type = "Text",
								key = "matsText",
								text = TSMAPI.Design:GetInlineColor("link") .. L["Materials:"] .. "|r",
								textSize = "small",
								justify = { "LEFT", "TOP" },
								points = { { "TOPLEFT" }, { "TOPRIGHT" } },
							},
							{
								type = "WidgetVList",
								key = "reagentButtons",
								repeatCount = MAX_TRADE_SKILL_REAGENTS or 8,
								startPoints = { { "TOPLEFT", 0, -15 }, { "TOPRIGHT", 0, -15 } },
								repeatOffset = -3,
								widget = {
									type = "ItemLinkLabel",
									key = "linkLabel",
									text = "",
									textHeight = 13,
									justify = { "LEFT", "MIDDLE" },
									size = { 0, 13 },
								},
							},
						},
					},
					{
						type = "Frame",
						key = "buttonsFrame",
						points = { { "TOPRIGHT", "infoFrame", "BOTTOMRIGHT", -2, -5 }, { "BOTTOMLEFT", 2, 2 } },
						children = {
							{
								type = "TextureButton",
								key = "lessBtn",
								normalTexture = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up",
								pushedTexture = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down",
								disabledTexture = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-DisabledTexture",
								highlightTexture = "Interface\\Buttons\\UI-Common-MouseHilight",
								size = { 28, 28 },
								points = { { "TOPLEFT", -4, 4 } },
								scripts = { "OnClick" },
							},
							{
								type = "InputBox",
								key = "inputBox",
								numeric = true,
								name = "TSMCraftingCreateInputBox",
								size = { 40, 0 },
								points = { { "TOPLEFT", "lessBtn", "TOPRIGHT", -2, -4 }, { "BOTTOMLEFT", "lessBtn", "BOTTOMRIGHT", -2, 4 } },
								scripts = { "OnEditFocusGained" },
							},
							{
								type = "TextureButton",
								key = "moreBtn",
								normalTexture = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up",
								pushedTexture = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down",
								disabledTexture = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-DisabledTexture",
								highlightTexture = "Interface\\Buttons\\UI-Common-MouseHilight",
								size = { 28, 28 },
								points = { { "TOPLEFT", "inputBox", "TOPRIGHT", -2, 4 }, { "BOTTOMLEFT", "inputBox", "BOTTOMRIGHT", -2, -4 } },
								scripts = { "OnClick" },
							},
							{
								type = "Button",
								key = "queueBtn",
								text = L["Queue"],
								textHeight = 15,
								clicks = "AnyUp",
								tooltip = strjoin("\n", queueBtnTooltipColor .. L["Left-Click|r to add this craft to the queue."], queueBtnTooltipColor .. L["Shift-Left-Click|r to queue all you can craft."], queueBtnTooltipColor .. L["Right-Click|r to subtract this craft from the queue."], queueBtnTooltipColor .. L["Shift-Right-Click|r to remove all from queue."]),
								points = { { "TOPLEFT", "moreBtn", "TOPRIGHT", 0, -4 }, { "BOTTOMLEFT", "moreBtn", "BOTTOMRIGHT", 0, 4 }, { "TOPRIGHT" } },
								scripts = { "OnClick" },
							},
							{
								type = "Button",
								key = "createBtn",
								text = CREATE_PROFESSION,
								textHeight = 15,
								size = { 0, 20 },
								points = { { "BOTTOMLEFT" }, { "BOTTOMRIGHT", BFC.PARENT, "BOTTOM", -2, 0 } },
								scripts = { "OnClick" },
							},
							{
								type = "Button",
								key = "createAllBtn",
								text = CREATE_ALL,
								textHeight = 15,
								size = { 0, 20 },
								points = { { "BOTTOMLEFT", BFC.PARENT, "BOTTOM", 2, 0 }, { "BOTTOMRIGHT" } },
								scripts = { "OnClick" },
							},
						},
					},
				},
			},
		},
		handlers = {
			OnShow = function(self)
				private.frame = self:GetParent()
				if not TradeSkill:GetVisibilityInfo().frame then return end
				if not self.helpBtn then
					local helpPlateInfo = {
						FramePos = { x = 0, y = 0 },
						FrameSize = { width = private.frame:GetWidth(), height = private.frame:GetHeight() },
						{
							ButtonPos = { x = 80, y = 15 },
							HighLightBox = { x = 20, y = 0, width = 80, height = 25 },
							ToolTipDir = "UP",
							ToolTipText = L["This button will switch to the default profession UI. You can switch back by clicking the 'TSM' button at the top of the default profession UI."]
						},
						{
							ButtonPos = { x = 170, y = -18 },
							HighLightBox = { x = 0, y = -25, width = private.frame:GetWidth(), height = 30 },
							ToolTipDir = "UP",
							ToolTipText = L["You can change the current tab of the profession frame, start gathering materials for your queue, and show the queue using these buttons."]
						},
						{
							ButtonPos = { x = 50, y = -48 },
							HighLightBox = { x = 0, y = -55, width = private.frame:GetWidth(), height = 35 },
							ToolTipDir = "UP",
							ToolTipText = L["You can use this dropdown to switch between the current character's professions."]
						},
						{
							ButtonPos = { x = 300, y = -250 },
							HighLightBox = { x = 0, y = -90, width = private.frame:GetWidth(), height = 410 },
							ToolTipDir = "RIGHT",
							ToolTipText = L["This area of the profession tab works similarly to the default profession UI, but with some added features. These include the ability to easily add crafts to your queue, listing profit next to crafts, and displaying inventory information."]
						},
					}

					self.helpBtn = CreateFrame("Button", nil, private.frame.professionsTab, "MainHelpPlateButton")
					self.helpBtn:SetPoint("CENTER", private.frame, "TOPLEFT", 0, 0)
					self.helpBtn:SetScript("OnClick", function() TradeSkill:ToggleHelpPlate(private.frame, helpPlateInfo, self.helpBtn, true) end)
					self.helpBtn:SetScript("OnHide", function() if HelpPlate_IsShowing(helpPlateInfo) then TradeSkill:ToggleHelpPlate(private.frame, helpPlateInfo, self.helpBtn, false) end end)
					if not TSM.db.global.helpPlatesShown.profession then
						TSM.db.global.helpPlatesShown.profession = true
						TradeSkill:ToggleHelpPlate(private.frame, helpPlateInfo, self.helpBtn, false)
					end
				end
				private.frame.groupsBtn:UnlockHighlight()
				private.frame.professionsBtn:LockHighlight()
				private.frame.groupsTab:Hide()
				Professions:UpdateST()
				private:UpdateProfessionDropdown()
			end,
			dropdown = {
				OnValueChanged = function(self, info)
					local playerName, profession = ("~"):split(info)
					if playerName == UnitName("player") then
						if profession == GetSpellInfo(TSM.MINING_SPELLID) then
							-- mining needs to be opened as smelting
							CastSpellByName(GetSpellInfo(TSM.SMELTING_SPELLID))
						else
							CastSpellByName(profession)
						end
					else
						local link = TSM.db.factionrealm.playerProfessions[playerName][profession].link
						TSMAPI:Assert(link, format("Profession data not found for %s on %s.", profession, playerName))
						local tradeString = strsub(select(3, ("|"):split(link)), 2)
						SetItemRef(tradeString, link) -- opens the profession from the link
					end
				end,
			},
			linkBtn = {
				OnClick = function(self)
					local link = C_TradeSkillUI.GetTradeSkillListLink()
					if not link then return TSM:Print(L["Could not get link for profession."]) end

					local activeEditBox = ChatEdit_GetActiveWindow()
					if MacroFrameText and MacroFrameText:IsShown() and MacroFrameText:HasFocus() then
						local text = MacroFrameText:GetText() .. link
						if strlenutf8(text) <= 255 then
							MacroFrameText:Insert(link)
						end
					elseif activeEditBox then
						ChatEdit_InsertLink(link)
					end
				end,
			},
			searchBar = {
				OnEditFocusGained = function(self)
					self:SetTextColor(1, 1, 1, 1)
					if self:GetText() == SEARCH then
						self:SetText("")
					end
				end,
				OnEditFocusLost = function(self)
					if self:GetText() == "" or self:GetText() == SEARCH then
						self:SetTextColor(1, 1, 1, 0.5)
						self:SetText(SEARCH)
					end
				end,
				OnTextChanged = function(self)
					local text = self:GetText():trim()
					if text == SEARCH then
						text = ""
					end
					C_TradeSkillUI.SetRecipeItemNameFilter(strlower(text))
				end,
				OnEnterPressed = function(self)
					self:ClearFocus()
				end,
			},
			clearFilterBtn = {
				OnClick = function(self)
					TradeSkill:ClearFilters()
				end,
			},
			filterBtn = {
				OnClick = function(self)
					Lib_ToggleDropDownMenu(1, nil, TSMTradeSkillFilterDropDown, "TSMCraftingFilterButton", self:GetWidth(), 0)
				end,
			},
			st = {
				OnClick = function(_, data, _, button)
					if data.category then
						private.collapsedCategories[data.category] = not private.collapsedCategories[data.category]
						Professions:UpdateST()
					elseif button == "LeftButton" then
						if IsModifiedClick() then
							HandleModifiedItemClick(C_TradeSkillUI.GetRecipeItemLink(data.spellId))
						else
							Professions:SetSelectedTradeSkill(data.spellId, true)
						end
					end
				end,
				OnColumnClick = function(self)
					if self.colNum == 2 then
						TSM.db.global.priceColumn = TSM.db.global.priceColumn + 1
						TSM.db.global.priceColumn = TSM.db.global.priceColumn > 3 and 1 or TSM.db.global.priceColumn
						self:SetText(private:GetProfessionsTabPriceColumnText())
						wipe(private.priceTextCache)
						private.priceTextCache.lastClear = time()
						Professions:UpdateST()
					end
				end,
				OnEnter = function(self, data, col)
					if not data.spellId then return end
					local info = C_TradeSkillUI.GetRecipeInfo(data.spellId)
					TradeSkillFrame_GenerateRankLinks(info)
					local totalRanks, currentRank = TradeSkillFrame_CalculateRankInfoFromRankLinks(info);
					if totalRanks == 1 or not currentRank then return end
					GameTooltip:SetOwner(col, "ANCHOR_RIGHT")
					GameTooltip:SetRecipeRankInfo(data.spellId, currentRank);
				end,
				OnLeave = function(self)
					GameTooltip:Hide()
				end,
			},
			-- craft info frame handlers
			craftInfoFrame = {
				infoFrame = {
					icon = {
						OnClick = function(self)
							local spellId = self:GetParent():GetParent().spellId
							if not spellId then return end
							HandleModifiedItemClick(C_TradeSkillUI.GetRecipeItemLink(spellId))
						end,
						OnEnter = function(self)
							local spellId = self:GetParent():GetParent().spellId
							if not spellId then return end
							local itemString = spellId and TSM.db.factionrealm.crafts[spellId] and TSM.db.factionrealm.crafts[spellId].itemString
							if itemString then
								GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
								TSMAPI.Util:SafeTooltipLink(itemString)
							else
								GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
								GameTooltip:SetRecipeResultItem(spellId)
							end
						end,
						OnLeave = function(self)
							GameTooltip:Hide()
						end,
					},
				},
				matsFrame = {
					sizer = {
						OnMouseDown = function()
							private.frame:StartSizing("BOTTOMRIGHT")
						end,
						OnMouseUp = function()
							private.frame:StopMovingOrSizing()
						end,
					},
				},
				buttonsFrame = {
					lessBtn = {
						OnClick = function(self)
							local num = self:GetParent().inputBox:GetNumber() - 1
							self:GetParent().inputBox:SetNumber(max(num, 1))
						end,
					},
					inputBox = {
						OnEditFocusGained = function(self)
							self:HighlightText()
						end,
					},
					moreBtn = {
						OnClick = function(self)
							local num = self:GetParent().inputBox:GetNumber() + 1
							self:GetParent().inputBox:SetNumber(max(num, 1))
						end,
					},
					queueBtn = {
						OnClick = function(self, button)
							local spellId = self:GetParent():GetParent().spellId
							if not spellId or not TSM.db.factionrealm.crafts[spellId] then return end
							local inputBoxNum = max(floor(self:GetParent().inputBox:GetNumber()), 1)

							if button == "LeftButton" and IsModifiedClick() then
								-- queue all that can be crafted
								local numCanCraft = C_TradeSkillUI.GetRecipeInfo(spellId).numAvailable
								TSM.Queue:SetNumQueued(spellId, numCanCraft)
							elseif button == "LeftButton" then
								TSM.Queue:Add(spellId, inputBoxNum)
							elseif button == "RightButton" and IsModifiedClick() then
								TSM.Queue:SetNumQueued(spellId, 0)
							elseif button == "RightButton" then
								TSM.Queue:Remove(spellId, inputBoxNum)
							end
							TradeSkill.Queue:Update()
						end
					},
					createBtn = {
						OnClick = function(self)
							local spellId = self:GetParent():GetParent().spellId
							TradeSkill:CastTradeSkill(spellId, self:GetParent().inputBox:GetNumber())
						end
					},
					createAllBtn = {
						OnClick = function(self)
							local spellId = self:GetParent():GetParent().spellId
							local quantity = C_TradeSkillUI.GetRecipeInfo(spellId).numAvailable
							TradeSkill:CastTradeSkill(spellId, quantity, self.vellum)
							self:GetParent().inputBox:SetNumber(C_TradeSkillUI.GetRecipeRepeatCount())
						end
					},
				},
			},
		}
	}
end

function Professions:OnButtonClicked(frame)
	private.frame = private.frame or frame
	private.frame.professionsTab:Show()
end


-- ============================================================================
-- Professions Tab Update Functions
-- ============================================================================

function private.InsertLinkHook(link)
	local putIntoChat = Professions.hooks.ChatEdit_InsertLink(link)
	if not putIntoChat and TradeSkill:GetVisibilityInfo().professionsTab and not strfind(GetMouseFocus() and GetMouseFocus():GetName() or "", "MerchantItem([0-9]+)ItemButton") then
		local name = TSMAPI.Item:GetName(link)
		if name then
			private.frame.professionsTab.searchBar:SetText(name)
			private.frame.professionsTab.searchBar:SetTextColor(1, 1, 1, 1)
			return true
		end
	end
	return putIntoChat
end

function private:FormatTime(seconds)
	if seconds == 0 then return end
	local hours = floor(seconds / 3600)
	local mins = floor((seconds % 3600) / 60)
	local secs = seconds % 60

	local str = ""
	if hours > 0 then
		str = str .. format("%dh", hours)
	end
	if mins > 0 then
		str = str .. format("%dm", mins)
	end
	if secs > 0 then
		str = str .. format("%ds", secs)
	end
	return str
end

function private:UpdateCraftTimeText()
	if not TradeSkill:GetVisibilityInfo().professionsTab then return end
	local startTime, endTime, isTradeSkill = select(5, UnitCastingInfo("player"))
	if isTradeSkill then
		local timePerCraft = endTime - startTime
		endTime = endTime + (timePerCraft * (C_TradeSkillUI.GetRecipeRepeatCount() - 1))
		private.craftTimeInfo.endTime = ceil(endTime / 1000)
	elseif not startTime then
		-- not casting a tradeskill
		if private.craftTimeInfo.endTime > GetTime() then
			private.craftTimeInfo.timeout = private.craftTimeInfo.timeout + 1
			if private.craftTimeInfo.timeout > 3 then
				private.craftTimeInfo.endTime = 0
				private.craftTimeInfo.timeout = 0
			end
		else
			private.craftTimeInfo.timeout = 0
		end
	end

	if private.craftTimeInfo.endTime > GetTime() then
		private.frame.professionsTab.craftInfoFrame.matsFrame.castText:SetText(private:FormatTime(private.craftTimeInfo.endTime - GetTime()))
	else
		private.frame.professionsTab.craftInfoFrame.matsFrame.castText:SetText()
	end
end

function private:GetProfessionsTabPriceColumnText()
	if TSM.db.global.priceColumn == 1 then
		return L["Crafting Cost"]
	elseif TSM.db.global.priceColumn == 2 then
		return L["Item Value"]
	elseif TSM.db.global.priceColumn == 3 then
		return L["Profit"]
	end
end

function private:UpdateProfessionDropdown()
	if not private.frame then return end
	local list = TSM.TradeSkillScanner:GetProfessionList()
	local playerName = select(2, C_TradeSkillUI.IsTradeSkillLinked()) or UnitName("player")
	local professionName = TSM:GetCurrentProfessionName()
	local level, maxLevel = select(3, C_TradeSkillUI.GetTradeSkillLine())
	local currentSelection = playerName .. "~" .. professionName
	private.frame.professionsTab.dropdown:SetList(list)
	private.frame.professionsTab.dropdown:SetValue(currentSelection)
	if not list[currentSelection] then
		if C_TradeSkillUI.IsNPCCrafting() then
			private.frame.professionsTab.dropdown:SetText(format("%s - %s", professionName, playerName))
		else
			private.frame.professionsTab.dropdown:SetText(format("%s %d/%d - %s", professionName, level, maxLevel, playerName))
		end
	end
end

function private:RGBPercToHex(tbl)
	local r = tbl.r <= 1 and tbl.r >= 0 and tbl.r or 0
	local g = tbl.g <= 1 and tbl.g >= 0 and tbl.g or 0
	local b = tbl.b <= 1 and tbl.b >= 0 and tbl.b or 0
	return string.format("%02x%02x%02x", r * 255, g * 255, b * 255)
end

function private.IsCategoryCollapsed(categoryId)
	return private.collapsedCategories[categoryId]
end

function private.GetRecipeList()
	local dataList = {}
	local currentCategoryID, currentParentCategoryID
	local isCurrentCategoryEnabled, isCurrentParentCategoryEnabled = true, true
	local starRankLinks = {}

	for i, recipeID in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
		if not starRankLinks[recipeID] then
			local recipeInfo = C_TradeSkillUI.GetRecipeInfo(recipeID)
			TradeSkillFrame_GenerateRankLinks(recipeInfo, starRankLinks)

			-- find the best recipe
			while recipeInfo.previousRecipeInfo do
				recipeInfo = recipeInfo.previousRecipeInfo
			end
			while recipeInfo.nextRecipeInfo and recipeInfo.nextRecipeInfo.learned do
				recipeInfo = recipeInfo.nextRecipeInfo
			end

			if recipeInfo.categoryID ~= currentCategoryID then
				local categoryData = C_TradeSkillUI.GetCategoryInfo(recipeInfo.categoryID)
				isCurrentCategoryEnabled = categoryData.enabled

				if categoryData.parentCategoryID ~= currentParentCategoryID then
					currentParentCategoryID = categoryData.parentCategoryID
					if currentParentCategoryID then
						local parentCategoryData = C_TradeSkillUI.GetCategoryInfo(currentParentCategoryID)
						isCurrentParentCategoryEnabled = parentCategoryData.enabled
						if isCurrentParentCategoryEnabled then
							tinsert(dataList, parentCategoryData)
						end
					else
						isCurrentParentCategoryEnabled = true
					end
				end

				if isCurrentCategoryEnabled and isCurrentParentCategoryEnabled and (not currentParentCategoryID or not private.IsCategoryCollapsed(currentParentCategoryID)) then
					tinsert(dataList, categoryData)
					currentCategoryID = recipeInfo.categoryID
				end
			end

			if isCurrentCategoryEnabled and isCurrentParentCategoryEnabled and (not currentParentCategoryID or not private.IsCategoryCollapsed(currentParentCategoryID)) and not private.IsCategoryCollapsed(currentCategoryID) then
				tinsert(dataList, recipeInfo)
			end
		end
	end

	return dataList
end

function Professions:UpdateST()
	if not TradeSkill:GetVisibilityInfo().professionsTab then return end
	TSM:UpdateCraftReverseLookup()
	local stData = {}
	wipe(private.stIndexLookup)

	if private.priceTextCache.lastClear + 60 < time() then
		wipe(private.priceTextCache)
		private.priceTextCache.lastClear = time()
	end

	-- go through tradeskills and populate data
	local numAvailableAllCache = {}
	local inventoryTotals = select(4, TSM:GetInventoryTotals())
	local playerName = UnitName("player")
	for _, info in ipairs(private.GetRecipeList()) do
		local spellId = info.recipeID
		local name = info.name
		if info.type == "header" then
			name = "|cff" .. private:RGBPercToHex(TradeSkillTypeColor.header) .. name .. " [" .. (private.IsCategoryCollapsed(info.categoryID) and "+" or "-") .. "]|r"
			tinsert(stData, { cols = { { value = name }, { value = "" } }, category = info.categoryID })
		elseif info.type == "subheader" then
			name = "|cff" .. private:RGBPercToHex(TradeSkillTypeColor.subheader) .. name .. " [" .. (private.IsCategoryCollapsed(info.categoryID) and "+" or "-") .. "]|r"
			name = strrep("  ", info.numIndents) .. name
			tinsert(stData, { cols = { { value = name }, { value = "" } }, category = info.categoryID })
		elseif info.type == "recipe" then
			local craft = TSM.db.factionrealm.crafts[spellId]

			-- calculate the total we are able to craft including other inventory
			local numAvailableAll = nil
			if craft then
				local vendorMatCount = nil
				for itemString, quantity in pairs(craft.mats) do
					if TSMAPI.Item:GetVendorCost(itemString) then
						vendorMatCount = min((vendorMatCount or math.huge), floor((inventoryTotals[itemString] or 0) / quantity))
					else
						numAvailableAll = min((numAvailableAll or math.huge), floor((inventoryTotals[itemString] or 0) / quantity))
					end
				end
				if vendorMatCount and not numAvailableAll then
					-- this craft has ONLY vendor-bought mats, so don't treat them specially (otherwise we could craft infinite numbers)
					numAvailableAll = vendorMatCount
				end
			end

			-- update cooldown end time
			local cooldown = C_TradeSkillUI.GetRecipeCooldown(spellId)
			if not info.disabled and craft and craft.hasCD then
				if not craft.cooldownTimes then
					craft.cooldownTimes = {}
				end
				if not craft.cooldownTimes[playerName] then
					craft.cooldownTimes[playerName] = { endTime = nil, prompt = nil }
				end
				if cooldown then
					craft.cooldownTimes[playerName].endTime = time() + floor(cooldown)
				else
					craft.cooldownTimes[playerName].endTime = 0
				end
			end

--[[
			-- set the leader for this row
			if skillType == "header" then
				leader = ""
			elseif skillType == "subheader" then
				-- first index should always be a header - this is a Blizzard bug introduced in 6.0.2
				leader = (i == 1) and "" or "  "
			end

			-- add text for header
			if skillType == "header" or skillType == "subheader" then
				if showProgressBar then
					skillName = skillName .. " (" .. currentRank .. "/" .. maxRank .. ") " .. (isExpanded and " [-]" or " [+]")
				else
					skillName = skillName .. (isExpanded and " [-]" or " [+]")
				end
			end
]]

			-- add text for multiple skill-ups
			if info.numSkillUps > 1 and info.difficulty == "optimal" then
				name = name .. " <" .. info.numSkillUps .. ">"
			end

			-- set the text for the number available if necessary, add color, and all the leader
			local leader = strrep("  ", info.numIndents + 1)
			if info.numAvailable > 0 or (numAvailableAll and numAvailableAll > 0) then
				local availableText = info.numAvailable .. " (" .. (numAvailableAll or 0) .. ")"
				name = leader .. "|cff" .. private:RGBPercToHex(TradeSkillTypeColor[info.difficulty]) .. name .. " [" .. availableText .. "]|r"
			else
				name = leader .. "|cff" .. private:RGBPercToHex(TradeSkillTypeColor[info.difficulty]) .. name .. "|r"
			end

			-- get the price text
			local priceText = private.priceTextCache[spellId]
			if not priceText then
				local cost, buyout, profit = TSM.Cost:GetSpellCraftPrices(spellId)
				if TSM.db.global.priceColumn == 1 and cost and cost > 0 then
					cost = cost * craft.numResult
					priceText = TSMAPI:MoneyToString(cost, TSMAPI.Design:GetInlineColor("link"))
				elseif TSM.db.global.priceColumn == 2 and buyout and buyout > 0 then
					buyout = buyout * craft.numResult
					priceText = TSMAPI:MoneyToString(buyout, TSMAPI.Design:GetInlineColor("link"))
				elseif TSM.db.global.priceColumn == 3 and profit then
					profit = profit * craft.numResult
					priceText = (profit < 0) and ("|cffff0000-|r" .. TSMAPI:MoneyToString(-profit, "|cffff0000")) or TSMAPI:MoneyToString(profit, "|cff00ff00")
				end
				if priceText then
					private.priceTextCache[spellId] = priceText
				else
					priceText = "---"
				end
			end


			tinsert(stData, { cols = { { value = name }, { value = priceText } }, spellId = spellId })
			private.stIndexLookup[spellId] = #stData
		else
			TSMAPI:Assert(false, "Invalid type: "..info.type)
		end
	end

	private.frame.professionsTab.st:SetData(stData)
	Professions:SetSelectedTradeSkill(private.selectedTradeSkill, true)
	private.frame.professionsTab.craftInfoFrame.buttonsFrame.inputBox:SetNumber(C_TradeSkillUI.GetRecipeRepeatCount())
end

function private.ValidateTradeSkill(spellId)
	local firstVisibleSpellId = nil
	for _, recipeId in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
		if recipeId == spellId then
			return spellId
		end
		firstVisibleSpellId = firstVisibleSpellId or recipeId
	end
	return firstVisibleSpellId
end

function Professions:SetSelectedTradeSkill(spellId, forceUpdate)
	if not TradeSkill:GetVisibilityInfo().professionsTab then return end

	-- verify that the spellId is valid
	spellId = private.ValidateTradeSkill(spellId)
	forceUpdate = forceUpdate or spellId ~= private.selectedTradeSkill
	private.selectedTradeSkill = spellId

	local frame = private.frame.professionsTab
	if not spellId then
		frame.craftInfoFrame:Hide()
		return
	end
	frame.craftInfoFrame:Show()

	if forceUpdate then
		frame.st:SetSelection(private.stIndexLookup[spellId])
		local info = C_TradeSkillUI.GetRecipeInfo(spellId)
		local name = info.name
		-- Enable display of items created
		local lNum, hNum = C_TradeSkillUI.GetRecipeNumItemsProduced(spellId)
		-- workaround for incorrect values returned for Temporal Crystal
		if TSM:IsCurrentProfessionEnchanting() and spellId == 169092 then
			local itemString = TSM.db.factionrealm.crafts[spellId] and TSM.db.factionrealm.crafts[spellId].itemString
			if itemString == "i:113588" then
				lNum, hNum = 1, 1
			end
		end
		local numMade = floor(((lNum or 1) + (hNum or 1)) / 2)
		if info.alternateVerb == ENSCRIBE then
			numMade = 1
		end
		if numMade > 1 then
			name = numMade .. " x " .. name
		end
		frame.craftInfoFrame.spellId = spellId
		frame.craftInfoFrame.infoFrame.icon:SetTexture(info.icon)
		frame.craftInfoFrame.infoFrame.nameText:SetText(TSMAPI.Design:GetInlineColor("link") .. (name or "") .. "|r")
		frame.craftInfoFrame.infoFrame.descText:SetText(C_TradeSkillUI.GetRecipeDescription(spellId))

		local toolsInfo = BuildColoredListString(C_TradeSkillUI.GetRecipeTools(spellId))
		frame.craftInfoFrame.infoFrame.toolsText:SetText(toolsInfo and REQUIRES_LABEL .. " " .. toolsInfo or "")
		local cooldown, isDaily = C_TradeSkillUI.GetRecipeCooldown(spellId)
		if info.disabled then
			frame.craftInfoFrame.infoFrame.cooldownText:SetText("|cffff0000" .. info.disabledReason .. "|r")
		elseif not cooldown then
			frame.craftInfoFrame.infoFrame.cooldownText:SetText("")
		elseif cooldown > 60 * 60 * 24 then -- cooldown is greater than 1 day
			frame.craftInfoFrame.infoFrame.cooldownText:SetText("|cffff0000" .. COOLDOWN_REMAINING .. " " .. SecondsToTime(cooldown, true, false, 1, true) .. "|r")
		elseif isDaily then
			frame.craftInfoFrame.infoFrame.cooldownText:SetText("|cffff0000" .. COOLDOWN_EXPIRES_AT_MIDNIGHT .. "|r")
		else
			frame.craftInfoFrame.infoFrame.cooldownText:SetText("|cffff0000" .. COOLDOWN_REMAINING .. " " .. SecondsToTime(cooldown) .. "|r")
		end

		for i, btn in ipairs(frame.craftInfoFrame.matsFrame.reagentButtons) do
			local name, texture, needed, player = C_TradeSkillUI.GetRecipeReagentInfo(spellId, i)
			if player ~= nil then
				btn:Show()
				btn.link = C_TradeSkillUI.GetRecipeReagentItemLink(spellId, i)
				local linkText = (texture and "|T" .. texture .. ":0|t" or "") .. " " .. (btn.link or name)
				local color = (needed > player) and "|cffff0000" or "|cff00ff00"
				btn:SetText(format("%s(%d/%d) %s|r", color, player, needed, linkText))
			else
				btn:Hide()
				btn:SetText("")
			end
		end

		if altVerb == ENSCRIBE then
			frame.craftInfoFrame.buttonsFrame.createAllBtn:SetText(L["Enchant Vellum"])
			frame.craftInfoFrame.buttonsFrame.createAllBtn.vellum = TSMAPI.Item:GetName(TSM.VELLUM_ITEM_STRING)
		else
			frame.craftInfoFrame.buttonsFrame.createAllBtn:SetText(CREATE_ALL)
			frame.craftInfoFrame.buttonsFrame.createAllBtn.vellum = nil
		end

		local isUnavailable = info.disabled
		if info.numAvailable > 0 and not C_TradeSkillUI.IsTradeSkillLinked() then
			local num = frame.craftInfoFrame.buttonsFrame.inputBox:GetNumber()
			frame.craftInfoFrame.buttonsFrame.inputBox:SetNumber(max(min(num, info.numAvailable), 1))
		else
			frame.craftInfoFrame.buttonsFrame.inputBox:SetNumber(1)
			isUnavailable = true
		end

		if isUnavailable then
			frame.craftInfoFrame.buttonsFrame.createBtn:Disable()
			frame.craftInfoFrame.buttonsFrame.createAllBtn:Disable()
		else
			frame.craftInfoFrame.buttonsFrame.createBtn:Enable()
			frame.craftInfoFrame.buttonsFrame.createAllBtn:Enable()
		end
	end
end
