-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local TradeSkill = TSM:GetModule("TradeSkill")
local Groups = TradeSkill:NewModule("Groups")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local private = {}


-- ============================================================================
-- Module Functions
-- ============================================================================

function Groups:GetFrameInfo()
	return {
		type = "Frame",
		key = "groupsTab",
		hidden = true,
		points = {{"TOPLEFT", 0, -59}, {"BOTTOMRIGHT"}},
		scripts = {"OnShow"},
		children = {
			{
				type = "GroupTreeFrame",
				key = "groupTree",
				groupTreeInfo = {"Crafting", "Crafting_Profession"},
				points = {{"TOPLEFT", 5, -5}, {"BOTTOMRIGHT", -5, 35}},
			},
			{
				type = "Button",
				key = "createBtn",
				text = L["Create Profession Groups"],
				textHeight = 13,
				size = {160, 24},
				points = {{"BOTTOMLEFT", 5, 5}},
				scripts = {"OnClick"},
			},
			{
				type = "Button",
				key = "restockBtn",
				text = L["Restock Selected Groups"],
				textHeight = 20,
				size = {0, 24},
				points = {{"BOTTOMLEFT", "createBtn", "BOTTOMRIGHT", 5, 0}, {"BOTTOMRIGHT", -5, 5}},
				scripts = {"OnClick"},
			},
		},
		handlers = {
			OnShow = function(self)
				private.frame = self:GetParent()
				if not TradeSkill:GetVisibilityInfo().frame then return end
				if not self.helpBtn then
					local TOTAL_WIDTH = private.frame:GetWidth()
					local helpPlateInfo = {
						FramePos = {x  = 0, y = 0},
						FrameSize = {width = TOTAL_WIDTH, height = private.frame:GetHeight()},
						{
							ButtonPos = {x = 80, y = 15},
							HighLightBox = {x = 20, y = 0, width = 80, height = 25},
							ToolTipDir = "UP",
							ToolTipText = L["This button will switch to the default profession UI. You can switch back by clicking a 'TSM' button at the top of the default profession UI."]
						},
						{
							ButtonPos = {x = 170, y = -18},
							HighLightBox = {x = 0, y = -25, width = TOTAL_WIDTH, height = 30},
							ToolTipDir = "UP",
							ToolTipText = L["You can change the current tab of the profession frame, start gathering materials for your queue, and show the queue using these buttons."]
						},
						{
							ButtonPos = {x = 300, y = -200},
							HighLightBox = {x = 0, y = -55, width = TOTAL_WIDTH, height = 410},
							ToolTipDir = "RIGHT",
							ToolTipText = L["Here, you can select which of your TSM groups you would like to restock based on their Crafting operations."]
						},
						{
							ButtonPos = {x = 50, y = -480},
							HighLightBox = {x = 5, y = -465, width = 160, height = 35},
							ToolTipDir = "UP",
							ToolTipText = L["This button will automatically create some simple TSM groups based on the current profession."]
						},
						{
							ButtonPos = {x = 250, y = -480},
							HighLightBox = {x = 170, y = -465, width = TOTAL_WIDTH-170, height = 35},
							ToolTipDir = "UP",
							ToolTipText = L["Click here to restock the selected groups based on their Crafting operations."]
						},
					}

					self.helpBtn = CreateFrame("Button", nil, private.frame.groupsTab, "MainHelpPlateButton")
					self.helpBtn:SetPoint("CENTER", private.frame, "TOPLEFT", 0, 0)
					self.helpBtn:SetScript("OnClick", function() TradeSkill:ToggleHelpPlate(private.frame, helpPlateInfo, self.helpBtn, true) end)
					self.helpBtn:SetScript("OnHide", function() if HelpPlate_IsShowing(helpPlateInfo) then TradeSkill:ToggleHelpPlate(private.frame, helpPlateInfo, self.helpBtn, false) end end)
					if not TSM.db.global.helpPlatesShown.groups then
						TSM.db.global.helpPlatesShown.groups = true
						TradeSkill:ToggleHelpPlate(private.frame, helpPlateInfo, self.helpBtn, false)
					end
				end
				self.createBtn:SetDisabled(C_TradeSkillUI.IsTradeSkillLinked())
				private.frame.groupsBtn:LockHighlight()
				private.frame.professionsBtn:UnlockHighlight()
				private.frame.professionsTab:Hide()
			end,
			createBtn = {
				OnClick = function(self)
					local profession = TSM:GetCurrentProfessionName()
					if profession == "UNKNOWN" then return end
					TSM.TradeSkillScanner:CreatePresetGroups()
					local playerName = UnitName("player")
					TSMAPI:Assert(playerName)
					TSMAPI:Assert(profession)
					TSMAPI:Assert(TSM.db.factionrealm.playerProfessions[playerName][profession])
					TSM.db.factionrealm.playerProfessions[playerName][profession].prompted = true
					TSMAPI.Sync:KeyUpdated(TSM.db.factionrealm.playerProfessions, playerName)
				end,
			},
			restockBtn = {
				OnClick = function(self)
					TSM.Queue:DoRestock(self:GetParent().groupTree:GetSelectedGroupInfo())
					TradeSkill.Queue:Update()
				end,
			},
		},
	}
end

function Groups:OnButtonClicked(frame)
	private.frame = private.frame or frame
	private.frame.groupsTab:Show()
end
