-- ------------------------------------------------------------------------------ --
--                            TradeSkillMaster_Crafting                           --
--            http://www.curse.com/addons/wow/tradeskillmaster_crafting           --
--                                                                                --
--             A TradeSkillMaster Addon (http://tradeskillmaster.com)             --
--    All Rights Reserved* - Detailed license information included with addon.    --
-- ------------------------------------------------------------------------------ --

local TSM = select(2, ...)
local TradeSkill = TSM:GetModule("TradeSkill")
local Queue = TradeSkill:NewModule("Queue")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Crafting") -- loads the localization table
local private = { craftNextInfo = nil }

-- ============================================================================
-- Methods to Add to the TradeSkill Module
-- ============================================================================

function Queue:GetFrameInfo()
	local BFC = TSMAPI.GUI:GetBuildFrameConstants()
	return {
		type = "Frame",
		key = "queue",
		hidden = true,
		size = { 300, 0 },
		points = { { "TOPLEFT", BFC.PARENT, "TOPRIGHT", 2, 0 }, { "BOTTOMLEFT", BFC.PARENT, "BOTTOMRIGHT", 2, 0 } },
		scripts = { "OnMouseDown", "OnMouseUp", "OnShow" },
		children = {
			{
				type = "ScrollingTableFrame",
				key = "craftST",
				headFontSize = 14,
				stCols = { { name = L["Craft Queue"], width = 1 } },
				stDisableSelection = true,
				points = { { "TOPLEFT", 5, -5 }, { "BOTTOMRIGHT", BFC.PARENT, "RIGHT", -5, 5 } },
				scripts = { "OnEnter", "OnLeave", "OnClick" },
			},
			{
				type = "HLine",
				offset = 0,
				size = { 0, 2 },
				points = { { "LEFT" }, { "RIGHT" } },
			},
			{
				type = "ScrollingTableFrame",
				key = "matST",
				headFontSize = 12,
				stCols = { { name = L["Material Name"], width = 0.49 }, { name = L["Need"], width = 0.115 }, { name = L["Total"], width = 0.115 }, { name = L["Cost"], width = 0.28 } },
				stDisableSelection = true,
				points = { { "TOPLEFT", BFC.PARENT, "LEFT", 5, -5 }, { "BOTTOMRIGHT", -5, 68 } },
				scripts = { "OnEnter", "OnLeave", "OnClick" },
			},
			{
				type = "HLine",
				offset = 0,
				size = { 0, 2 },
				points = { { "BOTTOMLEFT", 0, 63 }, { "BOTTOMRIGHT", 0, 63 } },
			},
			{
				type = "Text",
				key = "profitLabel",
				textSize = "medium",
				justify = { "LEFT", "CENTER" },
				points = { { "TOPLEFT", "matSTContainer", "BOTTOMLEFT", 0, -7 }, { "TOPRIGHT", "matSTContainer", "BOTTOMRIGHT", 0, -7 } },
			},
			{
				type = "HLine",
				offset = 0,
				size = { 0, 2 },
				points = { { "BOTTOMLEFT", 0, 28 }, { "BOTTOMRIGHT", 0, 28 } },
			},
			{
				type = "Button",
				key = "clearBtn",
				text = L["Clear Queue"],
				textHeight = 14,
				size = { 120, 20 },
				points = { { "BOTTOMLEFT", 5, 5 } },
				scripts = { "OnClick" },
			},
			{
				type = "Button",
				key = "craftNextBtn",
				name = "TSMCraftNextButton",
				isSecure = true,
				text = L["Craft Next"],
				textHeight = 18,
				size = { 0, 20 },
				points = { { "BOTTOMLEFT", BFC.PREV, "BOTTOMRIGHT", 5, 0 }, { "BOTTOMRIGHT", -5, 5 } },
				scripts = { "OnClick", "OnUpdate" },
			},
		},
		handlers = {
			OnShow = function(self)
				private.frame = self:GetParent()
				Queue:UpdateFrameStatus()
			end,
			OnMouseDown = function(self)
				self:GetParent():StartMoving()
			end,
			OnMouseUp = function(self)
				self:GetParent():StopMovingOrSizing()
			end,
			craftST = {
				OnEnter = function(self, data)
					if not data.spellId then return end
					local color
					local profit, totalProfit
					local numResult = TSM.db.factionrealm.crafts[data.spellId].numResult or 1
					if data.profit then
						profit = data.profit * numResult
						totalProfit = data.numQueued * data.profit * numResult
						if data.profit < 0 then
							color = "|cffff0000"
						else
							color = "|cff00ff00"
						end
					end
					GameTooltip:SetOwner(self, "ANCHOR_NONE")
					GameTooltip:SetPoint("LEFT", self, "RIGHT")
					GameTooltip:AddLine((TSM.db.factionrealm.crafts[data.spellId].name or "?") .. " (x" .. data.numQueued .. ")")
					GameTooltip:AddLine(L["Profit (Total Profit):"] .. " " .. (TSMAPI:MoneyToString(profit, color) or "---") .. "(" .. (TSMAPI:MoneyToString(totalProfit, color) or "---") .. ")")
					for itemString, matQuantity in pairs(TSM.db.factionrealm.crafts[data.spellId].mats) do
						local name = TSMAPI.Item:GetName(itemString) or (TSM.db.factionrealm.mats[itemString] and TSM.db.factionrealm.mats[itemString].name) or "?"
						local inventory = TSMAPI.Inventory:GetBagQuantity(itemString) + TSMAPI.Inventory:GetReagentBankQuantity(itemString)
						local need = matQuantity * data.numQueued
						local color
						if inventory >= need then color = "|cff00ff00" else color = "|cffff0000" end
						name = color .. inventory .. "/" .. need .. "|r " .. name
						GameTooltip:AddLine(name, 1, 1, 1)
					end
					GameTooltip:Show()
				end,
				OnLeave = function()
					GameTooltip:Hide()
				end,
				OnClick = function(self, data, _, button)
					if button == "RightButton" and data.spellId then
						if data.profession == TSM:GetCurrentProfessionName() then
							TradeSkill.Professions:SetSelectedTradeSkill(data.spellId)
							--private.frame.professionsTab.st:SetScrollOffset(max(0, data.index - 1)) -- FIXME
						end
					else
						if data.isTitle then
							TSM.db.factionrealm.queueStatus.collapsed[data.profession] = not TSM.db.factionrealm.queueStatus.collapsed[data.profession]
							Queue.Update()
						elseif data.spellId then
							TradeSkill:CastTradeSkill(data.spellId, min(data.canCraft, data.numQueued), data.velName)
						end
					end
				end,
			},
			matST = {
				OnEnter = function(self, data, col)
					GameTooltip:SetOwner(col, "ANCHOR_RIGHT")
					TSMAPI.Util:SafeTooltipLink(data.itemString)
					GameTooltip:Show()
				end,
				OnLeave = function()
					GameTooltip:Hide()
				end,
				OnClick = function(self, data)
					if IsModifiedClick() then
						HandleModifiedItemClick(TSMAPI.Item:GetLink(data.itemString) or data.itemString)
					end
				end,
			},
			clearBtn = {
				OnClick = function(self)
					TSM.Queue:Clear()
					Queue.Update()
					TradeSkill.Gather:ResetGathering(true)
				end,
			},
			craftNextBtn = {
				OnClick = function(self)
					if not private.craftNextInfo or not self:IsVisible() or not TSMAPI.Util:UseHardwareEvent() then return end
					if GetShapeshiftForm(true) > 0 then
						CancelShapeshiftForm()
					end
					TradeSkill:CastTradeSkill(private.craftNextInfo.spellId, private.craftNextInfo.quantity, private.craftNextInfo.velName)
				end,
				OnUpdate = function(self)
					if UnitCastingInfo("player") or not private.craftNextInfo then
						self:Disable()
					elseif TradeSkill.isCrafting and TradeSkill.isCrafting.quantity > 0 then
						self:Disable()
					else
						if not self:IsEnabled() then
							Queue.Update()
						end

						if private.craftNextInfo then
							self:Enable()
						end
					end
				end,
			},
		},
	}
end

function Queue:OnButtonClicked(frame)
	private.frame = private.frame or frame
	if TradeSkill:GetVisibilityInfo().queue then
		TSM.db.global.frameQueueOpen = nil
	else
		TSM.db.global.frameQueueOpen = true
	end
	Queue:UpdateFrameStatus()
end

function Queue:UpdateFrameStatus(frame)
	private.frame = private.frame or frame
	if not TradeSkill:GetVisibilityInfo().frame then return end
	if TSM.db.global.frameQueueOpen then
		private.frame.queue:Show()
		private.frame.queueBtn:SetText(L["Hide Queue"])
		private.frame.queueBtn:LockHighlight()
		Queue.Update()
	else
		private.frame.queue:Hide()
		private.frame.queueBtn:SetText(L["Show Queue"])
		private.frame.queueBtn:UnlockHighlight()
	end
end



-- ============================================================================
-- Queue Frame Update Functions
-- ============================================================================

function private.SortQueue(a, b)
	if a.profession == b.profession then
		if a.isTitle and b.isTitle then return false end
		if a.isTitle then return true end
		if b.isTitle then return false end
		if TSM.db.global.queueSort == 1 then
			if a.canCraft > 0 and b.canCraft > 0 then
				if a.profit == b.profit then
					return a.spellId > b.spellId
				end
				return (a.profit or -math.huge) > (b.profit or -math.huge)
			elseif a.canCraft > 0 then
				return true
			elseif b.canCraft > 0 then
				return false
			else
				return a.spellId > b.spellId
			end
		elseif TSM.db.global.queueSort == 2 then
			if a.profit == b.profit then
				if a.canCraft == b.canCraft then
					return a.spellId > b.spellId
				end
				return a.canCraft > b.canCraft
			end
			return (a.profit or -math.huge) > (b.profit or -math.huge)
		elseif TSM.db.global.queueSort == 3 then
			if a.canCraft == b.canCraft then
				if a.profit == b.profit then
					return a.spellId > b.spellId
				end
				return (a.profit or -math.huge) > (b.profit or -math.huge)
			end
			return a.canCraft > b.canCraft
		else
			error("Invalid queue sort!")
		end
	end
	if a.profession == TSM:GetCurrentProfessionName() then return true end
	if b.profession == TSM:GetCurrentProfessionName() then return false end
	return a.profession < b.profession
end

function Queue:Update()
	if not TradeSkill:GetVisibilityInfo().queue then return end
	TSM:UpdateCraftReverseLookup()

	local visibleSpellIds = {}
	for _, spellId in ipairs(C_TradeSkillUI.GetFilteredRecipeIDs()) do
		visibleSpellIds[spellId] = true
	end

	local stData = {}
	local bagTotals = TSM:GetInventoryTotals()
	local currentProfession = gsub(TSM:GetCurrentProfessionName(), TSMAPI.Util:StrEscape(" (" .. GARRISON_LOCATION_TOOLTIP..")"), "")
	local queueCrafts, queueMats, totalCost, totalProfit = TSM.Queue:GetStatus()

	-- update estimated total cost / profit labels
	totalCost = totalCost and TSMAPI:MoneyToString(totalCost, TSMAPI.Design:GetInlineColor("link")) or (TSMAPI.Design:GetInlineColor("link") .. "---|r")
	totalProfit = totalProfit and (totalProfit < 0 and "|cffff0000-|r" .. TSMAPI:MoneyToString(-totalProfit, "|cffff0000") or TSMAPI:MoneyToString(totalProfit, "|cff00ff00")) or TSMAPI.Design:GetInlineColor("link") .. "---|r"
	private.frame.queue.profitLabel:SetText(format(L["Estimated Cost: %s\nEstimated Profit: %s"], totalCost, totalProfit))

	for profession, crafts in pairs(queueCrafts) do
		-- get all the players with this profession or the garrison building
		local garrisonProfession = profession .. " (" .. GARRISON_LOCATION_TOOLTIP..")"

		local players = {}
		for player, data in pairs(TSM.db.factionrealm.playerProfessions) do
			if data[profession] or data[garrisonProfession] then
				tinsert(players, player)
			end
		end

		-- determine what color to use for the player / profession name
		local professionColor, playerColor
		if TSM.db.factionrealm.playerProfessions[UnitName("player")][profession] or TSM.db.factionrealm.playerProfessions[UnitName("player")][garrisonProfession] then
			playerColor = "|cffffffff"
			if profession == currentProfession then
				professionColor = "|cffffffff"
			else
				professionColor = "|cffff0000"
			end
		else
			playerColor = "|cffff0000"
			professionColor = "|cffff0000"
		end

		-- add header row for profession
		local professionIsCollapsed = TSM.db.factionrealm.queueStatus.collapsed[profession]
		local headerText = format("%s (%s) %s%s|r", professionColor .. profession .. "|r", playerColor .. table.concat(players, ", ") .. "|r", TSMAPI.Design:GetInlineColor("link"), professionIsCollapsed and "[+]" or "[-]")
		tinsert(stData, { cols = { { value = headerText } }, isTitle = true, profession = profession })

		if not professionIsCollapsed then
			for spellId, numQueued in pairs(crafts) do
				local craft = TSM.db.factionrealm.crafts[spellId]
				-- figure out how many we can craft with mats in our bags
				local numCanCraft = math.huge
				for itemString, quantity in pairs(craft.mats) do
					numCanCraft = max(min(numCanCraft, floor((bagTotals[itemString] or 0) / quantity)), 0)
				end

				local leader, craftStatus
				if numCanCraft >= numQueued then
					-- green (can craft all)
					leader = visibleSpellIds[spellId] and "|cff00ff00" or "|cff008800"
				elseif numCanCraft > 0 then
					-- blue (can craft some)
					leader = visibleSpellIds[spellId] and "|cff5599ff" or "|cff224488"
				else
					-- orange (can't craft any)
					leader = visibleSpellIds[spellId] and "|cffff7700" or "|cff883300"
				end

				if not visibleSpellIds[spellId] and craft.players[UnitName("player")] and craft.profession == currentProfession then
					leader = L["|cffff0000[Filtered]|r "] .. leader
				end

				-- add leading space
				leader = "    " .. leader
				-- add row to temporary table for this profession
				local rowText = format("%s[%d] %s|r", leader, numQueued, TSM.db.factionrealm.crafts[spellId].name or "?")
				local velName = craft.mats[TSM.VELLUM_ITEM_STRING] and (GetItemInfo(TSM.VELLUM_ITEM_STRING) or TSM.db.factionrealm.mats[TSM.VELLUM_ITEM_STRING].name) or nil
				local craftProfit = select(3, TSM.Cost:GetSpellCraftPrices(spellId))
				tinsert(stData, { cols = { { value = rowText } }, spellId = spellId, canCraft = numCanCraft, numQueued = numQueued, velName = velName, profit = craftProfit, profession = profession })
			end
		end
	end
	sort(stData, private.SortQueue)
	private.craftNextInfo = nil
	for _, row in ipairs(stData) do
		-- set the craftNextInfo to the first thing we can craft in the queue
		if row.spellId and row.canCraft > 0 then
			private.craftNextInfo = { spellId = row.spellId, quantity = min(row.numQueued, row.canCraft), velName = row.velName }
			break
		end
	end
	private.frame.queue.craftST:SetData(stData)

	stData = {} -- clear for mat rows
	for itemString, quantity in pairs(queueMats) do
		local matCost = TSM.Cost:GetMatCost(itemString)
		local numNeeded = max(quantity - TSMAPI.Inventory:GetTotalQuantity(itemString), 0)
		local color, order
		if numNeeded == 0 then
			local bagQty = TSMAPI.Inventory:GetBagQuantity(itemString) + TSMAPI.Inventory:GetReagentBankQuantity(itemString)
			if bagQty >= quantity then
				color = "|cff00ff00"
				order = 1
			else
				color = "|cffffff00"
				order = 2
			end
		else
			color = "|cffff0000"
			order = 3
		end

		tinsert(stData, {
			cols = {
				{ value = color .. TSM.db.factionrealm.mats[itemString].name .. "|r" },
				{ value = color .. numNeeded .. "|r" },
				{ value = color .. quantity .. "|r" },
				{ value = TSMAPI:MoneyToString(matCost) or "---" },
			},
			itemString = itemString,
			name = TSM.db.factionrealm.mats[itemString].name,
			order = order,
		})
	end
	sort(stData, function(a, b) return a.order < b.order end)
	private.frame.queue.matST:SetData(stData)
	TSM.TradeSkill.Gather:QueueUpdate()
end
