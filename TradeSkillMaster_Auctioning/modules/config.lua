-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Auctioning - AddOn by Sapu94							 	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_auctioning.aspx  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


local TSM = select(2, ...)
local Config = TSM:NewModule("Config", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization table
local AceGUI = LibStub("AceGUI-3.0")

local goldSettingKeys = {threshold=true, fallback=true, resetMaxCost=true, resetMinProfit=true}
local specialSettingKeys = {thresholdPriceMethod="threshold", thresholdPercent="threshold",
	fallbackPriceMethod="fallback", fallbackPercent="fallback",
	resetMaxCostPriceMethod="resetMaxCost", resetMaxCostPercent="resetMaxCost",
	resetMinProfitPriceMethod="resetMinProfit", resetMinProfitPercent="resetMinProfit"}

function Config:GetConfigObject(itemString, noCaching)
	local configObject = {itemString=itemString, cache=(not noCaching and {})}
	setmetatable(configObject, {__index=function(self, key)
			local itemString, cache = rawget(self, "itemString"), rawget(self, "cache")
			if key == "auctionItem" then
				return TSM.Scan.auctionData[itemString]
			else
				if cache then
					cache[key] = cache[key] or Config:GetConfigValue(itemString, key)
					return cache[key]
				end
				return Config:GetConfigValue(itemString, key)
			end
		end})
	return configObject
end

function Config:GetConfigValue(itemString, key, isGroup)
	local groupValue
	local specialSettingKey = specialSettingKeys[key]
	if specialSettingKey then
		if TSM.db.profile.groups[itemString] or TSM.db.profile.categories[itemString] then
			if TSM.db.profile[specialSettingKey][itemString] then
				groupValue = itemString
			elseif TSM.db.profile[specialSettingKey][TSM.groupReverseLookup[itemString]] then
				groupValue = TSM.groupReverseLookup[itemString]
			else
				groupValue = "default"
			end
		else
			groupValue = "default"
		end
	elseif goldSettingKeys[key] then
		if TSM.itemReverseLookup[itemString] and TSM.db.profile[key][TSM.itemReverseLookup[itemString]] and TSM.db.profile[key][TSM.itemReverseLookup[itemString]] then
			groupValue = TSM.itemReverseLookup[itemString]
		elseif TSM.groupReverseLookup[TSM.itemReverseLookup[itemString] or ""] and TSM.db.profile[key][TSM.groupReverseLookup[TSM.itemReverseLookup[itemString] or ""]] then
			groupValue = TSM.groupReverseLookup[TSM.itemReverseLookup[itemString]]
		elseif TSM.db.profile.groups[itemString] or TSM.db.profile.categories[itemString] then
			-- we got passed a group not an itemString (used by GetGroupMoney method in the options)
			if TSM.db.profile[key][itemString] then
				groupValue = itemString
			elseif TSM.groupReverseLookup[itemString] and TSM.db.profile[key][TSM.groupReverseLookup[itemString]] then
				groupValue = TSM.groupReverseLookup[itemString]
			else
				groupValue = "default"
			end
		else
			groupValue = "default"
		end
		if TSM.db.profile[key][groupValue] ~= nil then
			TSM.db.profile[key.."PriceMethod"][groupValue] = TSM.db.profile[key.."PriceMethod"][groupValue] or "gold"
		end
		local method = TSM.db.profile[key.."PriceMethod"][groupValue]
		if method ~= "gold" then
			local group = TSM.itemReverseLookup[itemString] or (TSM.db.profile.groups[itemString] and itemString)
			if not group then return 0 end
			local percent = TSM.db.profile[key.."Percent"][groupValue]
			local value = TSM:GetMarketValue(group, percent, method)
			return value
		end
	else
		if not isGroup then
			if TSM.itemReverseLookup[itemString] and TSM.db.profile[key][TSM.itemReverseLookup[itemString]] then
				groupValue = TSM.itemReverseLookup[itemString]
			elseif TSM.groupReverseLookup[TSM.itemReverseLookup[itemString] or ""] and TSM.db.profile[key][TSM.groupReverseLookup[TSM.itemReverseLookup[itemString] or ""]] then
				groupValue = TSM.groupReverseLookup[TSM.itemReverseLookup[itemString]]
			else
				groupValue = "default"
			end
		else
			if TSM.db.profile[key][itemString] then
				groupValue = itemString
			elseif TSM.groupReverseLookup[itemString] and TSM.db.profile[key][TSM.groupReverseLookup[itemString]] then
				groupValue = TSM.groupReverseLookup[itemString]
			else
				groupValue = "default"
			end
		end
	end
	return TSM.db.profile[key][groupValue]
end

function Config:GetBoolConfigValue(itemString, key, isGroup)
	local val
	local groupName = not isGroup and TSM.itemReverseLookup[itemString] or itemString
	local categoryName = TSM.groupReverseLookup[groupName or ""]
	
	val = TSM.db.profile[key][groupName or ""]
	if val == nil and categoryName then
		val = TSM.db.profile[key][categoryName]
	end
	
	if val ~= nil then
		return val
	end
	return TSM.db.profile[key].default
end

function Config:LoadOptions(parent)
	if TSM.db.global.hideAdvanced == nil then
		StaticPopupDialogs["TSMAucHideAdvancedPopup"] = {
			text = L["Would you like to load these options in beginner or advanced mode? If you have not used APM, QA3, or ZA before, beginner is recommended. Your selection can always be changed using the \"Hide advanced options\" checkbox in the \"Options\" page."],
			button1 = L["Beginner"],
			button2 = L["Advanced"],
			timeout = 0,
			whileDead = true,
			hideOnEscape = false,
			OnAccept = function() TSM.db.global.hideAdvanced = true end,
			OnCancel = function() TSM.db.global.hideAdvanced = false end,
		}
		TSMAPI:ShowStaticPopupDialog("TSMAucHideAdvancedPopup")
	end

	local treeGroup = AceGUI:Create("TSMTreeGroup")
	treeGroup:SetLayout("Fill")
	treeGroup:SetCallback("OnGroupSelected", function(...) Config:SelectTree(...) end)
	treeGroup:SetStatusTable(TSM.db.global.treeGroupStatus)
	parent:AddChild(treeGroup)
	
	--TSMAPI:SetCurrentHelpInfo("Auctioning Groups/Options", nil, "auctioning auc_import")
	Config.treeGroup = treeGroup
	Config:UpdateTree()
	Config.treeGroup:SelectByPath(1)
end

function Config:UpdateTree()
	if not Config.treeGroup then return end
	TSM:UpdateGroupReverseLookup()

	local categoryTreeIndex = {}
	local treeGroups = {{value=1, text=L["Options"]}, {value=2, text=L["Categories / Groups"], children={{value="~", text=TSMAPI.Design:GetInlineColor("category2")..L["<Uncategorized Groups>"].."|r", disabled=true, children={}}}}, {value=3, text="Auctioning Wizard"}}
	local pageNum
	for categoryName, groups in pairs(TSM.db.profile.categories) do
		for groupName, v in pairs(groups) do
			if not TSM.db.profile.groups[groupName] then
				v = nil
			end
		end
		tinsert(treeGroups[2].children, {value=categoryName, text=TSMAPI.Design:GetInlineColor("category")..categoryName.."|r"})
		categoryTreeIndex[categoryName] = #(treeGroups[2].children)
	end
	for name in pairs(TSM.db.profile.groups) do
		if TSM.groupReverseLookup[name] then
			local index = categoryTreeIndex[TSM.groupReverseLookup[name]]
			treeGroups[2].children[index].children = treeGroups[2].children[index].children or {}
			tinsert(treeGroups[2].children[index].children, {value=name, text=name})
		else
			tinsert(treeGroups[2].children[1].children, {value=name, text=name})
		end
	end
	sort(treeGroups[2].children, function(a, b) return strlower(a.value) < strlower(b.value) end)
	for _, data in pairs(treeGroups[2].children) do
		if data.children then
			sort(data.children, function(a, b) return strlower(a.value) < strlower(b.value) end)
		end
	end
	Config.treeGroup:SetTree(treeGroups)
end

function Config:SelectTree(treeFrame, _, selection)
	TSM:UpdateGroupReverseLookup()
	treeFrame:ReleaseChildren()
	local content = AceGUI:Create("TSMSimpleGroup")
	content:SetLayout("Fill")
	treeFrame:AddChild(content)

	local selectedParent, selectedChild, selectedSubChild = ("\001"):split(selection)
	if not selectedChild or tonumber(selectedChild) == 0 then
		if tonumber(selectedParent) == 1 then
			local offsets, previousTab = {}, 1
			local tg = AceGUI:Create("TSMTabGroup")
			tg:SetLayout("Fill")
			tg:SetFullHeight(true)
			tg:SetFullWidth(true)
			tg:SetTabs({{value=1, text=L["General"]}, {value=2, text=L["Whitelist"]}, {value=3, text=L["Blacklist"]}, {value=4, text=L["Profiles"]}})
			tg:SetCallback("OnGroupSelected", function(self,_,value)
				if tg.children and tg.children[1] and tg.children[1].localstatus then
					offsets[previousTab] = tg.children[1].localstatus.offset
				end
				tg:ReleaseChildren()
				content:DoLayout()
				
				if value == 1 then
					Config:DrawGeneralOptions(tg)
				elseif value == 2 then
					Config:DrawWhitelist(tg)
				elseif value == 3 then
					Config:DrawBlacklist(tg)
				elseif value == 4 then
					Config:DrawProfiles(tg)
				end
				
				if tg.children and tg.children[1] and tg.children[1].localstatus then
					tg.children[1].localstatus.offset = (offsets[value] or 0)
				end
				previousTab = value
			end)
			content:AddChild(tg)
			tg:SelectTab(1)
		elseif tonumber(selectedParent) == 3 then
			TSM.Wizard:DrawWizard(content)
		else
			local offsets, previousTab = {}, 1
			local tg = AceGUI:Create("TSMTabGroup")
			tg:SetLayout("Fill")
			tg:SetFullHeight(true)
			tg:SetFullWidth(true)
			tg:SetTabs({{value=1, text=L["Auction Defaults"]}, {value=2, text=L["Create Category / Group"]}, {value=3, text=L["Quick Group Creation"]}})
			tg:SetCallback("OnGroupSelected", function(self,_,value)
				if tg.children and tg.children[1] and tg.children[1].localstatus then
					offsets[previousTab] = tg.children[1].localstatus.offset
				end
				tg:ReleaseChildren()
				content:DoLayout()
				
				if value == 1 then
					Config:DrawGroupGeneral(tg, "default")
				elseif value == 2 then
					Config:DrawItemGroups(tg)
				elseif value == 3 then
					Config:DrawQuickCreation(tg)
				end
				
				if tg.children and tg.children[1] and tg.children[1].localstatus then
					tg.children[1].localstatus.offset = (offsets[value] or 0)
				end
				previousTab = value
			end)
			content:AddChild(tg)
			tg:SelectTab(1)
		end
	else
		selectedChild = strlower(selectedSubChild or selectedChild)
		local offsets, previousTab = {}, 1
		local isCategory = TSM.db.profile.categories[selectedChild]
		
		local addRemoveTabOrder = TSM.db.global.tabOrder
		local overrideTabOrder
		if addRemoveTabOrder == 1 then
			overrideTabOrder = 2
		else
			overrideTabOrder = 1
		end
		
		local groupTabs = {}
		groupTabs[overrideTabOrder] = {value=1, text=L["Group Overrides"]}
		groupTabs[addRemoveTabOrder] = {value=2, text=L["Add/Remove Items"]}
		groupTabs[3] = {value=3, text=L["Management"]}
		
		local categoryTabs = {}
		categoryTabs[overrideTabOrder] = {value=1, text=L["Category Overrides"]}
		categoryTabs[addRemoveTabOrder] = {value=2, text=L["Add/Remove Groups"]}
		categoryTabs[3] = {value=3, text=L["Management"]}
		
		local tg = AceGUI:Create("TSMTabGroup")
		tg:SetLayout("Fill")
		tg:SetFullHeight(true)
		tg:SetFullWidth(true)
		tg:SetTabs(isCategory and categoryTabs or groupTabs)
		tg:SetCallback("OnGroupSelected", function(self,_,value)
			if tg.children and tg.children[1] and tg.children[1].localstatus then
				offsets[previousTab] = tg.children[1].localstatus.offset
			end
			tg:ReleaseChildren()
			content:DoLayout()
			Config:UnregisterAllEvents()
			
			if value == 1 then
				Config:DrawGroupGeneral(tg, selectedChild)
			elseif value == 2 then
				if isCategory then
					Config:DrawAddRemoveGroup(tg, selectedChild)
				else
					Config:RegisterEvent("BAG_UPDATE", function() tg:SelectTab(2) end)
					Config:DrawAddRemoveItem(tg, selectedChild)
				end
			elseif value == 3 then
				if isCategory then
					Config:DrawCategoryManagement(tg, selectedChild)
				else
					Config:DrawGroupManagement(tg, selectedChild)
				end
			end
			
			if tg.children and tg.children[1] and tg.children[1].localstatus then
				tg.children[1].localstatus.offset = (offsets[value] or 0)
			end
			previousTab = value
		end)
		content:AddChild(tg)
		tg:SelectTab(overrideTabOrder)
	end
end

function Config:DrawGeneralOptions(container)
	local macroOptions = {down=true, up=true, ctrl=true, shift=false, alt=false}

	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["General"],
					children = {
						{
							type = "CheckBox",
							label = L["Hide help text"],
							quickCBInfo = {TSM.db.global, "hideHelp"},
							tooltip = L["Hides auction setting help text throughout the options."],
						},
						{
							type = "CheckBox",
							label = L["Hide advanced options"],
							quickCBInfo = {TSM.db.global, "hideAdvanced"},
							tooltip = L["Hides advanced auction settings. Provides for an easier learning curve for new users."],
						},
						{
							type = "CheckBox",
							label = L["Hide poor quality items"],
							quickCBInfo = {TSM.db.global, "hideGray"},
							tooltip = L["Hides all poor (gray) quality items from the 'Add items' pages."],
						},
						{
							type = "CheckBox",
							label = L["Enable sounds"],
							quickCBInfo = {TSM.db.global, "enableSounds"},
							tooltip = L["Plays the ready check sound when a post / cancel scan is complete and items are ready to be posting / canceled (the gray bar is all the way across)."],
						},
						{
							type = "CheckBox",
							label = L["Show group name in tooltip"],
							quickCBInfo = {TSM.db.global, "showTooltip"},
							callback = function(_,_,value)
									if value then
										TSMAPI:RegisterTooltip("TradeSkillMaster_Auctioning", function(...) return TSM:LoadTooltip(...) end)
									else
										TSMAPI:UnregisterTooltip("TradeSkillMaster_Auctioning")
									end
								end,
							tooltip = L["Shows the name of the group an item belongs to in that item's tooltip."],
						},
						{
							type = "CheckBox",
							label = L["Smart group creation"],
							quickCBInfo = {TSM.db.global, "smartGroupCreation"},
							tooltip = L["If enabled, when you create a new group, your bags will be scanned for items with names that include the name of the new group. If such items are found, they will be automatically added to the new group."],
						},
						{
							type = "CheckBox",
							label = L["Match whitelist prices"],
							relativeWidth = 1,
							quickCBInfo = {TSM.db.global, "matchWhitelist"},
							tooltip = L["If enabled, when the lowest auction is by somebody on your whitelist, it will post your auction at the same price. If disabled, it won't post the item at all."],
						},
						{
							type = "Dropdown",
							label = L["First Tab in Group / Category Settings"],
							list = {L["Add/Remove"], L["Overrides"]},
							value = TSM.db.global.tabOrder,
							relativeWidth = 0.5,
							callback = function(_,_,value) TSM.db.global.tabOrder = value end,
							tooltip = L["Determines which order the group / category settings tabs will appear in."],
						},
						{
							type = "Slider",
							value = TSM.db.global.maxRetries,
							label = L["Max Scan Retries (Advanced)"],
							relativeWidth = 0.5,
							min = 1,
							max = 100,
							step = 1,
							callback = function(_,_,value) TSM.db.global.maxRetries = value end,
							tooltip = L["This controls how many times Auctioning will retry a query before giving up and moving on. Each retry takes about 2-3 seconds."],
						},
					}
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Canceling"],
					children = {
						{
							type = "CheckBox",
							label = L["Cancel auctions with bids"],
							quickCBInfo = {TSM.db.global, "cancelWithBid"},
							tooltip = L["Will cancel auctions even if they have a bid on them, you will take an additional gold cost if you cancel an auction with bid."],
						},
						{
							type = "CheckBox",
							label = L["Cancel to repost higher"],
							quickCBInfo = {TSM.db.global, "repostCancel"},
							tooltip = L["If checked, will cancel auctions that can be reposted for a higher amount (ie you haven't been undercut and the auction you originally undercut has expired)."],
						},
						{
							type = "CheckBox",
							label = L["Smart canceling"],
							quickCBInfo = {TSM.db.global, "smartCancel"},
							tooltip = L["Disables canceling of auctions which can not be reposted (ie the market price is below your threshold)."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Macro Help"],
					children = {
						{
							type = "Label",
							text = format(L["There are two ways of making clicking the Post / Cancel Auction button easier. You can put %s and %s in a macro (on separate lines), or use the utility below to have a macro automatically made and bound to scrollwheel for you."], "\""..TSMAPI.Design:GetInlineColor("link").."/click TSMAuctioningPostButton|r\"", "\""..TSMAPI.Design:GetInlineColor("link").."/click TSMAuctioningCancelButton|r\""),
							relativeWidth = 1,
						},
						{
							type = "HeadingLine"
						},
						{
							type = "Label",
							text = L["ScrollWheel Direction (both recommended):"],
							relativeWidth = 0.59,
						},
						{
							type = "CheckBox",
							label = L["Up"],
							relativeWidth = 0.2,
							quickCBInfo = {macroOptions, "up"},
							tooltip = L["Will bind ScrollWheelUp (plus modifiers below) to the macro created."],
						},
						{
							type = "CheckBox",
							label = L["Down"],
							relativeWidth = 0.2,
							quickCBInfo = {macroOptions, "down"},
							tooltip = L["Will bind ScrollWheelDown (plus modifiers below) to the macro created."],
						},
						{
							type = "Label",
							text = L["Modifiers:"],
							relativeWidth = 0.24,
							fontObject = GameFontNormal,
						},
						{
							type = "CheckBox",
							label = L["ALT"],
							relativeWidth = 0.25,
							quickCBInfo = {macroOptions, "alt"},
						},
						{
							type = "CheckBox",
							label = L["CTRL"],
							relativeWidth = 0.25,
							quickCBInfo = {macroOptions, "ctrl"},
						},
						{
							type = "CheckBox",
							label = L["SHIFT"],
							relativeWidth = 0.25,
							quickCBInfo = {macroOptions, "shift"},
						},
						{
							type = "Button",
							relativeWidth = 1,
							text = L["Create Macro and Bind ScrollWheel (with selected options)"],
							callback = function()
									DeleteMacro("TSMAucBClick")
									CreateMacro("TSMAucBClick", 1, "/click TSMAuctioningCancelButton\n/click TSMAuctioningPostButton")
									
									local modString = ""
									if macroOptions.ctrl then
										modString = modString .. "CTRL-"
									end
									if macroOptions.alt then
										modString = modString .. "ALT-"
									end
									if macroOptions.shift then
										modString = modString .. "SHIFT-"
									end
									
									local bindingNum = GetCurrentBindingSet()
									bindingNum = (bindingNum == 1) and 2 or 1
									
									if macroOptions.up then
										SetBinding(modString.."MOUSEWHEELUP", nil, bindingNum)
										SetBinding(modString.."MOUSEWHEELUP", "MACRO TSMAucBClick", bindingNum)
									end
									if macroOptions.down then
										SetBinding(modString.."MOUSEWHEELDOWN", nil, bindingNum)
										SetBinding(modString.."MOUSEWHEELDOWN", "MACRO TSMAucBClick", bindingNum)
									end
									SaveBindings(2)
									
									TSM:Print(L["Macro created and keybinding set!"])
								end,
						},
					},
				},
			},
		}
	}
	
	if not AucAdvanced then
		for i, v in ipairs(page[1].children[1].children) do
			if v.label == L["Block Auctioneer while scanning"] then
				tremove(page[1].children[1].children, i)
				break
			end
		end
	end
	
	TSMAPI:BuildPage(container, page)
end

function Config:DrawGroupGeneral(container, groupName)
	local group = Config:GetConfigObject(groupName, true)

	local isDefaultPage = (groupName == "default")
	local overrideTooltip = "|cffff8888"..L["Right click to override this setting."].."|r"
	local unoverrideTooltip = "\n\n|cffff8888"..L["Right click to remove the override of this setting."].."|r"
	if isDefaultPage then
		overrideTooltip = ""
		unoverrideTooltip = ""
	end
	TSM:UpdateGroupReverseLookup()
	
	local priceMethodList = {["gold"]=L["Fixed Gold Amount"]}
	for k,v in pairs(TSMAPI:GetPriceSources()) do
		priceMethodList[strlower(k)]=L["%% of %s"]:format(v)
	end
	
	local GetGroupMoney
	
	local function GetValue(key)
		local categoryName = TSM.groupReverseLookup[groupName]
		return TSM.db.profile[key][groupName] or (categoryName and TSM.db.profile[key][categoryName]) or TSM.db.profile[key].default
	end
	
	local function GetInfo(num)
		local color = TSMAPI.Design:GetInlineColor("link")
		local isGroup = not (TSM.db.profile.categories[groupName] or isDefaultPage)
	
		if num == 1 then
			local stacksOver = color..GetValue("ignoreStacksOver").."|r"
			local stacksUnder = color..GetValue("ignoreStacksUnder").."|r"
			local noCancel = GetValue("noCancel")
			local disabled = GetValue("disabled")
			
			if disabled then
				return format(L["Items in this group will not be posted or canceled automatically."])
			elseif noCancel then
				return format(L["When posting, ignore auctions with more than %s items or less than %s items in them. Items in this group will not be canceled automatically."], stacksOver, stacksUnder)
			else
				return format(L["When posting and canceling, ignore auctions with more than %s item(s) or less than %s item(s) in them."], stacksOver, stacksUnder)
			end
		elseif num == 2 then
			local duration = color..GetValue("postTime").."|r"
			local perAuction = color..GetValue("perAuction").."|r"
			local postCap = color..GetValue("postCap").."|r"
			local perAuctionIsCap = GetValue("perAuctionIsCap")
		
			if perAuctionIsCap and not TSM.db.global.hideAdvanced then
				return format(L["Auctions will be posted for %s hours in stacks of up to %s. A maximum of %s auctions will be posted."], duration, perAuction, postCap)
			else
				return format(L["Auctions will be posted for %s hours in stacks of %s. A maximum of %s auctions will be posted."], duration, perAuction, postCap)
			end
		elseif num == 3 then
			local undercut = TSM:FormatTextMoney(GetValue("undercut"))
			local bidPercent = color..(GetValue("bidPercent")*100).."|r"
		
			return format(L["Auctioning will undercut your competition by %s. When posting, the bid of your auctions will be set to %s percent of the buyout."], undercut, bidPercent)
		elseif num == 4 then
			local threshold = GetGroupMoney("threshold", true)
			local thresholdMethod = group.thresholdPriceMethod
			local percentText
			if thresholdMethod and thresholdMethod ~= "gold" and priceMethodList[thresholdMethod] then
				percentText = (group.thresholdPercent*100)..priceMethodList[thresholdMethod]
			end
			
			if not isGroup and percentText then
				threshold = percentText
			elseif percentText then
				threshold = threshold.." ("..percentText..")"
			end
			
			if TSM.db.global.hideAdvanced then
				return format(L["Auctioning will never post your auctions for below %s."], threshold)
			else
				return format(L["Auctioning will follow the 'Advanced Price Settings' when the market goes below %s."], threshold)
			end
		elseif num == 5 then
			local fallback = GetGroupMoney("fallback", true)
			local fallbackCap = TSM:FormatTextMoney(GetValue("fallbackCap")*GetGroupMoney("fallback", true, true))
			
			local fallbackMethod = group.fallbackPriceMethod
			local percentText
			local capText
			if fallbackMethod and fallbackMethod ~= "gold" then
				local percent = group.fallbackPercent
				percentText = (percent*100)..(priceMethodList[fallbackMethod] or "")
				capText = percent*100*GetValue("fallbackCap")..(priceMethodList[fallbackMethod] or "")
			end
			
			if not isGroup and percentText then
				fallback = percentText
				fallbackCap = capText
			elseif percentText then
				fallback = fallback.." ("..percentText..")"
			end
		
			return format(L["Auctioning will post at %s when you are the only one posting below %s."], fallback, fallbackCap)
		elseif num == 6 then
			local reset = GetValue("reset")
			local fallbackMethod = group.fallbackPriceMethod
			local thresholdMethod = group.thresholdPriceMethod
			local fallback
			local threshold
			local percentText
			if fallbackMethod ~= "gold" then
				local percent = group.fallbackPercent
				fallback = (percent*100)..(priceMethodList[fallbackMethod] or "")
			else
				fallback = TSM:FormatTextMoney(GetValue("fallback"))
			end
			if thresholdMethod ~= "gold" then
				local percent = group.thresholdPercent
				threshold = (percent*100)..(priceMethodList[thresholdMethod] or "")
			else
				threshold = TSM:FormatTextMoney(GetValue("threshold"))
			end
			local resetPrice = TSM:FormatTextMoney(GetValue("resetPrice"))
			
			if reset == "none" then
				return L["Auctions will not be posted when the market goes below your threshold."]
			elseif reset == "threshold" then
				return format(L["Auctions will be posted at your threshold price of %s when the market goes below your threshold."], threshold)
			elseif reset == "fallback" then
				return format(L["Auctions will be posted at your fallback price of %s when the market goes below your threshold."], fallback)
			elseif reset == "custom" then
				return format(L["Auctions will be posted at %s when the market goes below your threshold."], resetPrice)
			end
		elseif num == 7 then
			if GetValue("resetEnabled") then
				local resetMaxCost = TSM:FormatTextMoney(GetValue("resetMaxCost"))
				local resetMinProfit = TSM:FormatTextMoney(GetValue("resetMinProfit"))
				local resetMaxQuantity = GetValue("resetMaxQuantity")
				local resetMaxPricePer = TSM:FormatTextMoney(GetValue("resetMaxPricePer"))
				
				return format(L["Auctioning will reset items where you can make a profit of at least %s per item by buying at most %s items for a maximum of %s, paying no more than %s for any single item."], resetMinProfit, resetMaxQuantity, resetMaxCost, resetMaxPricePer)
			else
				return L["This item will not be included in the reset scan."]
			end
		end
	end
	
	local function SetGroupOverride(key, value, widget)
		if not value then
			TSM.db.profile[key][groupName] = nil
		else
			TSM.db.profile[key][groupName] = Config:GetConfigValue(groupName, key, true)
		end
		
		widget:SetDisabled(not value)
		if widget.type == "TSMOverrideEditBox" and key ~= "searchTerm" then
			widget:SetText(GetGroupMoney(key))
		elseif widget.type == "TSMOverrideSlider" then
			widget:SetValue(Config:GetConfigValue(groupName, key, true))
			widget.editbox:ClearFocus()
		end
	end

	local function GetGroupOverride(key)
		if isDefaultPage then return false end
		
		return TSM.db.profile[key][groupName] ~= nil
	end
	
	local function SetGroupMoney(key, value, editBox)
		local gold = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)g|r") or string.match(value, "([0-9]+)g"))
		local silver = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)s|r") or string.match(value, "([0-9]+)s"))
		local copper = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)c|r") or string.match(value, "([0-9]+)c"))
		local percent = tonumber(string.match(value, "([0-9]+)|c([0-9a-fA-F]+)%%|r") or string.match(value, "([0-9]+)%%"))
		local goldMethod = TSM.db.profile[key.."PriceMethod"] and TSM.db.profile[key.."PriceMethod"][groupName] == "gold" or not TSM.db.profile[key.."PriceMethod"]
		
		if not gold and not silver and not copper and goldMethod then
			TSM:Print(L["Invalid money format entered, should be \"#g#s#c\", \"25g4s50c\" is 25 gold, 4 silver, 50 copper."])
			editBox:SetFocus()
			return
		elseif not percent and TSM.db.profile[key.."PriceMethod"] and TSM.db.profile[key.."PriceMethod"][groupName] ~= "gold" then
			TSM:Print(L["Invalid percent format entered, should be \"#%\", \"105%\" is 105 percent."])
			editBox:SetFocus()
			return
		elseif gold or silver or copper then
			-- Convert it all into copper
			copper = (copper or 0) + ((gold or 0) * COPPER_PER_GOLD) + ((silver or 0) * COPPER_PER_SILVER)
			TSM.db.profile[key][groupName] = copper
		elseif percent then
			TSM.db.profile[key.."Percent"][groupName] = percent/100
		end
		
		editBox:SetText(GetGroupMoney(key))
		container:SelectTab(1)
	end

	GetGroupMoney = function(key, noExtraText, noFormatting)
		local groupValue = group[key]
		local defaultValue = TSM.db.profile[key].default
		local extraText = ""
		
		if goldSettingKeys[key] and group[key.."PriceMethod"] ~= "gold" then
			local percent = group[key.."Percent"]
			if percent then
				if not noExtraText then return (percent*100).."%" end
				extraText = " ("..(percent*100).."%)"
			else
				percent = floor((TSMAPI:SafeDivide(group[key] or 0, TSM:GetMarketValue(groupName, nil, group[key.."PriceMethod"])))*1000 + 0.5)/10
				TSM.db.profile[key.."Percent"][groupName] = percent/100
				if not noExtraText then return percent.."%" end
				extraText = " ("..percent.."%)"
			end
			
			-- if it's not a group then it's either a category or default in which case just return the percent
			if not TSM.db.profile.groups[groupName] then
				if noFormatting then
					return percent*100
				else
					return percent*100 .. "%"
				end
			end
		end
		
		if noExtraText then extraText = "" end
		
		-- if we aren't overriding, the option will be disabled so strip color codes so it all grays out
		if not isDefaultPage and not TSM.db.profile[key][groupName] then
			if not noFormatting then
				return TSM:FormatTextMoney(groupValue or defaultValue, nil, not noExtraText) .. extraText
			else
				return tonumber(groupValue)
			end
		end
		if not noFormatting then
			return TSM:FormatTextMoney(groupValue) .. extraText
		else
			return tonumber(groupValue)
		end
	end
	
	local function GetCustomResetSliderValues(func)
		local fallback = Config:GetConfigValue(groupName, "fallback", true)
		local threshold = Config:GetConfigValue(groupName, "threshold", true)
		local fallbackCap = Config:GetConfigValue(groupName, "fallbackCap", true)
		return func(floor(threshold*0.5/COPPER_PER_GOLD+0.5), floor(fallback*fallbackCap/COPPER_PER_GOLD+0.5))
	end
	
	local function ChangeItemIDGroup(_, _, value)
		TSM.db.profile.itemIDGroups[groupName] = value
		if value then
			TSM:UpdateItemReverseLookup()
			
			local newGroupItems = {}
			for itemString in pairs(TSM.db.profile.groups[groupName]) do
				local itemID = TSMAPI:GetItemID(itemString)
				if itemID then
					newGroupItems[itemID] = true
				end
			end
			TSM.db.profile.groups[groupName] = newGroupItems
			
			for itemString, group in pairs(TSM.itemReverseLookup) do
				local itemID = TSMAPI:GetItemID(itemString)
				if group ~= groupName and itemID and newGroupItems[itemID] then
					TSM.db.profile.groups[group][itemString] = nil
					local link = select(2, GetItemInfo(itemString)) or itemString
					TSM:Printf(L["%s removed from '%s' as a result of converting the current group to itemIDs."], link, group)
				end
			end
		else
			local newGroupItems = {}
			for itemID in pairs(TSM.db.profile.groups[groupName]) do
				local itemString = TSMAPI:GetItemString(itemID)
				if itemString then
					newGroupItems[itemString] = true
				end
			end
			TSM.db.profile.groups[groupName] = newGroupItems
		end
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{ -- Help
					type = "InlineGroup",
					layout = "flow",
					title = L["Help"],
					hidden = not isDefaultPage,
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = L["The below are fallback settings for groups, if you do not override a setting in a group then it will use the settings below.\n\nWarning! All auction prices are per item, not overall. If you set it to post at a fallback of 1g and you post in stacks of 20 that means the fallback will be 20g."],
						},
					},
				},
				{ -- General Settings
					type = "InlineGroup",
					layout = "Flow",
					title = L["General Settings"],
					hidden = TSM.db.global.hideAdvanced,
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = GetInfo(1),
							hidden = TSM.db.global.hideHelp,
						},
						{
							type = "HeadingLine",
							hidden = TSM.db.global.hideHelp,
						},
						{
							type = "Slider",
							settingInfo = {"ignoreStacksUnder", 1},
							label = L["Ignore stacks under"],
							min = 1,
							max = 1000,
							step = 1,
							tooltip = L["Items that are stacked beyond the set amount are ignored when calculating the lowest market price."]..unoverrideTooltip,
						},
						{
							type = "Slider",
							settingInfo = {"ignoreStacksOver", 1},
							label = L["Ignore stacks over"],
							min = 1,
							max = 1000,
							step = 1,
							tooltip = L["Items that are stacked beyond the set amount are ignored when calculating the lowest market price."]..unoverrideTooltip,
						},
						{
							type = "Dropdown",
							settingInfo = {"minDuration", 1},
							label = L["Ignore low duration auctions"],
							list = {[0]=L["<none>"], [1]=L["short (less than 30 minutes)"], [2]=L["medium (less than 2 hours)"], [3]=L["long (less than 12 hours)"]},
							tooltip = L["Any auctions at or below the selected duration will be ignored. Selecting \"<none>\" will cause no auctions to be ignored based on duration."]..unoverrideTooltip,
						},
						{
							type = "Label",
							relativeWidth = 0.45,
						},
						{
							type = "CheckBox",
							settingInfo = {"noCancel", 1},
							label = L["Disable auto cancelling"],
							tooltip = L["Disable automatically cancelling of items in this group if undercut."]..unoverrideTooltip,
							hidden = isDefaultPage,
						},
						{
							type = "CheckBox",
							settingInfo = {"disabled", 1},
							label = L["Disable posting and canceling"],
							tooltip = L["Completely disables this group. This group will not be scanned for and will be effectively invisible to Auctioning."]..unoverrideTooltip,
							hidden = isDefaultPage,
						},
						{
							type = "EditBox",
							settingInfo = {"searchTerm", 1},
							label = L["Common Search Term"],
							relativeWidth = 0.5,
							tooltip = L["If all items in this group have the same phrase in their name, use this phrase instead to speed up searches. For example, if this group contains only glyphs, you could put \"glyph of\" and Auctioning will search for that instead of each glyph name individually. Leave empty for default behavior."]..unoverrideTooltip,
							hidden = isDefaultPage,
						},
						{
							type = "CheckBox",
							value = TSM.db.profile.itemIDGroups[groupName],
							label = L["Add Items by ItemID"],
							relativeWidth = 0.49,
							callback = ChangeItemIDGroup,
							tooltip = L["If checked, items in this group will be added as itemIDs rather than itemStrings. This is useful if you'd like to ignore random enchants on items.\n\nNote: Any common search term will be ignored for groups with this box checked."],
							hidden = TSM.db.profile.categories[groupName] or isDefaultPage,
						},
					},
				},
				{ -- Spacer
					type = "Spacer",
				},
				{ -- Post Settings
					type = "InlineGroup",
					layout = "Flow",
					title = L["Post Settings (Quantity / Duration)"],
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = GetInfo(2),
							hidden = TSM.db.global.hideHelp,
						},
						{
							type = "HeadingLine",
							hidden = TSM.db.global.hideHelp,
						},
						{
							type = "Dropdown",
							settingInfo = {"postTime", 2},
							label = L["Post time"],
							list = {[12] = L["12 hours"], [24] = L["24 hours"], [48] = L["48 hours"]},
							tooltip = L["How long auctions should be up for."]..unoverrideTooltip,
						},
						{
							type = "Slider",
							settingInfo = {"postCap", 2},
							label = L["Post cap"],
							min = 1,
							max = 500,
							step = 1,
							tooltip = L["How many auctions at the lowest price tier can be up at any one time."]..unoverrideTooltip,
						},
						{
							type = "Slider",
							settingInfo = {"perAuction", 2},
							label = L["Per auction"],
							min = 1,
							max = 1000,
							step = 1,
							tooltip = L["How many items should be in a single auction, 20 will mean they are posted in stacks of 20."]..unoverrideTooltip,
						},
						{
							type = "CheckBox",
							settingInfo = {"perAuctionIsCap", 2},
							label = L["Use per auction as cap"],
							tooltip = L["If you don't have enough items for a full post, it will post with what you have."]..unoverrideTooltip,
							hidden = TSM.db.global.hideAdvanced,
						},
					},
				},
				{ -- Spacer
					type = "Spacer",
				},
				{ -- General Price Settings
					type = "InlineGroup",
					layout = "flow",
					title = L["General Price Settings (Undercut / Bid)"],
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = GetInfo(3),
							hidden = TSM.db.global.hideHelp,
						},
						{
							type = "HeadingLine",
							hidden = TSM.db.global.hideHelp,
						},
						{
							type = "EditBox",
							value = TSM:FormatTextMoney(Config:GetConfigValue(groupName, "undercut", true), nil, TSM.db.profile.undercut[groupName] == nil),
							label = L["Undercut by"],
							relativeWidth = 0.48,
							disabled = TSM.db.profile.undercut[groupName] == nil,
							disabledTooltip = overrideTooltip,
							callback = function(self, _, value) SetGroupMoney("undercut", value, self) end,
							onRightClick = function(self, value) SetGroupOverride("undercut", value, self) end,
							tooltip = L["How much to undercut other auctions by, format is in \"#g#s#c\" but can be in any order, \"50g30s\" means 50 gold, 30 silver and so on."]..unoverrideTooltip,
						},
						{
							type = "Slider",
							settingInfo = {"bidPercent", 3, true},
							label = L["Bid percent"],
							isPercent = true,
							min = 0,
							max = 1,
							step = 0.05,
							tooltip = L["Percentage of the buyout as bid, if you set this to 90% then a 100g buyout will have a 90g bid."]..unoverrideTooltip,
						},
					},
				},
				{ -- Spacer
					type = "Spacer",
				},
				{ -- Minimum Price Settings
					type = "InlineGroup",
					layout = "flow",
					title = L["Minimum Price Settings (Threshold)"],
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = GetInfo(4),
							hidden = TSM.db.global.hideHelp
						},
						{
							type = "HeadingLine",
							hidden = TSM.db.global.hideHelp
						},
						{
							type = "EditBox",
							value = GetGroupMoney("threshold"),
							label = L["Price threshold"],
							relativeWidth = 0.48,
							disabled = TSM.db.profile.threshold[groupName] == nil,
							disabledTooltip = overrideTooltip,
							callback = function(self, _, value) SetGroupMoney("threshold", value, self) end,
							onRightClick = function(self, value)
									if not value then
										TSM.db.profile.thresholdPriceMethod[groupName] = nil
									else
										TSM.db.profile.thresholdPriceMethod[groupName] = Config:GetConfigValue(groupName, "thresholdPriceMethod", true)
									end
									if not value or Config:GetConfigValue(groupName, "thresholdPriceMethod", true) == "gold" then
										TSM.db.profile.thresholdPercent[groupName] = nil
									else
										TSM.db.profile.thresholdPercent[groupName] = Config:GetConfigValue(groupName, "thresholdPercent", true)
									end
									SetGroupOverride("threshold", value, self)
									container:SelectTab(1)
								end,
							tooltip = L["How low the market can go before an item should no longer be posted. The minimum price you want to post an item for."]..unoverrideTooltip,
						},
						{
							type = "Dropdown",
							label = L["Set threshold as a"],
							relativeWidth = 0.48,
							list = priceMethodList,
							value = group.thresholdPriceMethod,
							disabled = TSM.db.profile.threshold[groupName] == nil,
							callback = function(self,_,value)
									if value == "gold" then
										TSM.db.profile.thresholdPercent[groupName] = nil
									elseif TSM.db.profile.thresholdPriceMethod[groupName] ~= "gold" then
										TSM.db.profile.thresholdPriceMethod[groupName] = value
										TSM.db.profile.threshold[groupName] = group.threshold
									end
									TSM.db.profile.thresholdPriceMethod[groupName] = value
									local siblings = self.parent.children
									for i, v in pairs(siblings) do
										if v == self then
											siblings[i-1]:SetText(GetGroupMoney("threshold"))
											break
										end
									end
									container:SelectTab(1)
								end,
							tooltip = L["You can set a fixed threshold, or have it be a percentage of some other value."],
							hidden = TSM.db.global.hideAdvanced,
						},
					},
				},
				{ -- Spacer
					type = "Spacer",
				},
				{ -- Maximum Price Settings
					type = "InlineGroup",
					layout = "flow",
					title = L["Maximum Price Settings (Fallback)"],
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = GetInfo(5),
							hidden = TSM.db.global.hideHelp
						},
						{
							type = "HeadingLine",
							hidden = TSM.db.global.hideHelp
						},
						{
							type = "EditBox",
							value = GetGroupMoney("fallback"),
							label = L["Fallback price"],
							relativeWidth = 0.48,
							disabled = TSM.db.profile.fallback[groupName] == nil,
							disabledTooltip = overrideTooltip,
							callback = function(self, _, value) SetGroupMoney("fallback", value, self) end,
							onRightClick = function(self, value)
									if not value then
										TSM.db.profile.fallbackPriceMethod[groupName] = nil
									else
										TSM.db.profile.fallbackPriceMethod[groupName] = Config:GetConfigValue(groupName, "fallbackPriceMethod", true)
									end
									if Config:GetConfigValue(groupName, "fallbackPriceMethod", true) == "gold" then
										TSM.db.profile.fallbackPercent[groupName] = nil
									else
										TSM.db.profile.fallbackPercent[groupName] = Config:GetConfigValue(groupName, "fallbackPercent", true)
									end
									SetGroupOverride("fallback", value, self)
									container:SelectTab(1)
								end,
							tooltip = L["Price to fallback too if there are no other auctions up, the lowest market price is too high."]..unoverrideTooltip,
						},
						{
							type = "Dropdown",
							label = L["Set fallback as a"],
							relativeWidth = 0.48,
							list = priceMethodList,
							value = group.fallbackPriceMethod,
							disabled = TSM.db.profile.fallback[groupName] == nil,
							callback = function(self,_,value)
									if value == "gold" then
										TSM.db.profile.fallbackPercent[groupName] = nil
									elseif TSM.db.profile.fallbackPriceMethod[groupName] ~= "gold" then
										TSM.db.profile.fallbackPriceMethod[groupName] = value
										TSM.db.profile.fallback[groupName] = group.fallback
									end
									TSM.db.profile.fallbackPriceMethod[groupName] = value
									local siblings = self.parent.children
									for i, v in pairs(siblings) do
										if v == self then
											siblings[i-1]:SetText(GetGroupMoney("fallback"))
											break
										end
									end
									container:SelectTab(1)
								end,
							tooltip = L["You can set a fixed fallback price for this group, or have the fallback price be automatically calculated to a percentage of a value. If you have multiple different items in this group and use a percentage, the highest value will be used for the entire group."],
							hidden = TSM.db.global.hideAdvanced,
						},
						{
							type = "Slider",
							settingInfo = {"fallbackCap", 5, true},
							label = L["Maximum price"],
							isPercent = true,
							min = 1,
							max = 10,
							step = 0.1,
							tooltip = L["If the market price is above fallback price * maximum price, items will be posted at the fallback * maximum price instead.\n\nEffective for posting prices in a sane price range when someone is posting an item at 5000g when it only goes for 100g."]..unoverrideTooltip,
							hidden = TSM.db.global.hideAdvanced,
						},
					},
				},
				{ -- Spacer
					type = "Spacer",
				},
				{ -- Advanced Price Settings
					type = "InlineGroup",
					layout = "flow",
					title = L["Advanced Price Settings (Reset Method)"],
					hidden = TSM.db.global.hideAdvanced,
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = GetInfo(6),
							hidden = TSM.db.global.hideHelp
						},
						{
							type = "HeadingLine",
							hidden = TSM.db.global.hideHelp
						},
						{
							type = "Dropdown",
							label = L["Reset Method"],
							relativeWidth = 0.48,
							list = {["none"]=L["Don't Post Items"], ["threshold"]=L["Post at Threshold"], ["fallback"]=L["Post at Fallback"], ["custom"]=L["Custom Value"]},
							value = Config:GetConfigValue(groupName, "reset", true),
							disabled = TSM.db.profile.reset[groupName] == nil,
							disabledTooltip = overrideTooltip,
							callback = function(self,_,value)
									local oldValue = TSM.db.profile.reset[groupName]
									TSM.db.profile.reset[groupName] = value
									if value == "custom" or oldValue == "custom" then
										TSM.db.profile.resetPrice[groupName] = (TSM.db.profile.threshold[groupName] or TSM.db.profile.threshold.default)
										container:SelectTab(1)
									end
									if value ~= "custom" then
										TSM.db.profile.resetPrice[groupName] = nil
									end
									container:SelectTab(1)
								end,
							onRightClick = function(self, value) SetGroupOverride("reset", value, self) container:SelectTab(1) end,
							tooltip = L["This dropdown determines what Auctioning will do when the market for an item goes below your threshold value. You can either not post the items or post at your fallback/threshold/a custom value."]
						},
						{
							type = "Slider",
							value = (Config:GetConfigValue(groupName, "resetPrice", true) or 50000)/COPPER_PER_GOLD,
							label = L["Custom Reset Price (gold)"],
							relativeWidth = 0.48,
							min = GetCustomResetSliderValues(min),
							max = GetCustomResetSliderValues(max),
							step = 1,
							callback = function(self,_,value)
									TSM.db.profile.resetPrice[groupName] = value*COPPER_PER_GOLD
									if not TSM.db.global.hideHelp then self.parent.children[1]:SetText(GetInfo(6)) end
								end,
							tooltip = L["Custom market reset price. If the market goes below your threshold, items will be posted at this price."],
							hidden = TSM.db.profile.reset[groupName] ~= "custom",
						},
						{
							type = "Slider",
							settingInfo = {"resetResolutionPercent", 6, true},
							--value = Config:GetConfigValue(groupName, "resetResolution", true),
							label = format(L["Price resolution for %s"], Config:GetConfigValue(groupName, "reset", true)),
							relativeWidth = 0.48,
							min = 0,
							max = 25,
							step = 1,
							--callback = function(self,_,value)
									--Config:GetConfigValue(groupName, "resetResolution", true) = value
								--end,
							tooltip = format(L["Custom percentage change of market price. If the market price changes by this percentage, your items will be reposted at the %s value."], Config:GetConfigValue(groupName, "reset", true)),
							hidden = function()
								local resetMethod = Config:GetConfigValue(groupName, "reset", true)
								local priceMethod = (resetMethod == "threshold" or resetMethod == "fallback") and Config:GetConfigValue(groupName, resetMethod.."PriceMethod", true)
								if (resetMethod == "threshold" or resetMethod == "fallback") and priceMethod ~= "gold" then
									return false
								else
									return true
								end
							end,
						},
					},
				},
				{ -- Spacer
					type = "Spacer",
				},
				{ -- Reset Scan Settings
					type = "InlineGroup",
					layout = "flow",
					title = L["Reset Scan Settings"],
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = GetInfo(7),
							hidden = TSM.db.global.hideHelp
						},
						{
							type = "HeadingLine",
							hidden = TSM.db.global.hideHelp
						},
						{
							type = "CheckBox",
							settingInfo = {"resetEnabled", 7, nil, true},
							relativeWidth = 1,
							label = L["Include in reset scan"],
							callback = function() container:SelectTab(1) end,
							tooltip = L["If checked, the items in this group will be included when running a reset scan and the reset scan options will be shown."]..unoverrideTooltip,
						},
						{
							type = "EditBox",
							value = GetGroupMoney("resetMaxCost"),
							label = L["Max reset cost"],
							relativeWidth = 0.48,
							disabled = TSM.db.profile.resetMaxCost[groupName] == nil,
							disabledTooltip = overrideTooltip,
							callback = function(self, _, value) SetGroupMoney("resetMaxCost", value, self) end,
							onRightClick = function(self, value)
									if not value then
										TSM.db.profile.resetMaxCostPriceMethod[groupName] = nil
									else
										TSM.db.profile.resetMaxCostPriceMethod[groupName] = Config:GetConfigValue(groupName, "resetMaxCostPriceMethod", true)
									end
									if not value or Config:GetConfigValue(groupName, "resetMaxCostPriceMethod", true) == "gold" then
										TSM.db.profile.resetMaxCostPercent[groupName] = nil
									else
										TSM.db.profile.resetMaxCostPercent[groupName] = Config:GetConfigValue(groupName, "resetMaxCostPercent", true)
									end
									SetGroupOverride("resetMaxCost", value, self)
									container:SelectTab(1)
								end,
							tooltip = L["The maximum amount that you want to spend in order to reset a particular item. This is the total amount, not a per-item amount."]..unoverrideTooltip,
							hidden = not isDefaultPage and not Config:GetBoolConfigValue(groupName, "resetEnabled", true),
						},
						{
							type = "Dropdown",
							label = L["Set max reset cost as a"],
							relativeWidth = 0.48,
							list = priceMethodList,
							value = group.resetMaxCostPriceMethod,
							disabled = TSM.db.profile.resetMaxCost[groupName] == nil,
							callback = function(self,_,value)
									if value == "gold" then
										TSM.db.profile.resetMaxCostPercent[groupName] = nil
									elseif TSM.db.profile.resetMaxCostPriceMethod[groupName] ~= "gold" then
										TSM.db.profile.resetMaxCostPriceMethod[groupName] = value
										TSM.db.profile.resetMaxCost[groupName] = group.resetMaxCost
									end
									TSM.db.profile.resetMaxCostPriceMethod[groupName] = value
									local siblings = self.parent.children
									for i, v in pairs(siblings) do
										if v == self then
											siblings[i-1]:SetText(GetGroupMoney("resetMaxCost"))
											break
										end
									end
									container:SelectTab(1)
								end,
							tooltip = L["You can set a fixed max reset cost, or have it be a percentage of some other value."],
							hidden = TSM.db.global.hideAdvanced or (not isDefaultPage and not Config:GetBoolConfigValue(groupName, "resetEnabled", true)),
						},
						{
							type = "EditBox",
							value = GetGroupMoney("resetMinProfit"),
							label = L["Min reset profit"],
							relativeWidth = 0.48,
							disabled = TSM.db.profile.resetMinProfit[groupName] == nil,
							disabledTooltip = overrideTooltip,
							callback = function(self, _, value) SetGroupMoney("resetMinProfit", value, self) end,
							onRightClick = function(self, value)
									if not value then
										TSM.db.profile.resetMinProfitPriceMethod[groupName] = nil
									else
										TSM.db.profile.resetMinProfitPriceMethod[groupName] = Config:GetConfigValue(groupName, "resetMinProfitPriceMethod")
									end
									if not value or Config:GetConfigValue(groupName, "resetMinProfitPriceMethod", true) == "gold" then
										TSM.db.profile.resetMinProfitPercent[groupName] = nil
									else
										TSM.db.profile.resetMinProfitPercent[groupName] = Config:GetConfigValue(groupName, "resetMinProfitPercent", true)
									end
									SetGroupOverride("resetMinProfit", value, self)
									container:SelectTab(1)
								end,
							tooltip = L["The minimum profit you would want to make from doing a reset. This is a per-item price where profit is the price you reset to minus the average price you spent per item."]..unoverrideTooltip,
							hidden = not isDefaultPage and not Config:GetBoolConfigValue(groupName, "resetEnabled", true),
						},
						{
							type = "Dropdown",
							label = L["Set min reset price as a"],
							relativeWidth = 0.48,
							list = priceMethodList,
							value = group.resetMinProfitPriceMethod,
							disabled = TSM.db.profile.resetMinProfit[groupName] == nil,
							callback = function(self,_,value)
									if value == "gold" then
										TSM.db.profile.resetMinProfitPercent[groupName] = nil
									elseif TSM.db.profile.resetMinProfitPriceMethod[groupName] ~= "gold" then
										TSM.db.profile.resetMinProfitPriceMethod[groupName] = value
										TSM.db.profile.resetMinProfit[groupName] = group.resetMinProfit
									end
									TSM.db.profile.resetMinProfitPriceMethod[groupName] = value
									local siblings = self.parent.children
									for i, v in pairs(siblings) do
										if v == self then
											siblings[i-1]:SetText(GetGroupMoney("resetMinProfit"))
											break
										end
									end
									container:SelectTab(1)
								end,
							tooltip = L["You can set a fixed min reset price, or have it be a percentage of some other value."],
							hidden = TSM.db.global.hideAdvanced or (not isDefaultPage and not Config:GetBoolConfigValue(groupName, "resetEnabled", true)),
						},
						{
							type = "Slider",
							settingInfo = {"resetMaxQuantity", 7},
							label = L["Max quantity to buy"],
							min = 1,
							max = 200,
							step = 1,
							tooltip = L["This is the maximum number of items you're willing to buy in order to perform a reset."]..unoverrideTooltip,
							hidden = not isDefaultPage and not Config:GetBoolConfigValue(groupName, "resetEnabled", true),
						},
						{
							type = "EditBox",
							value = TSM:FormatTextMoney(Config:GetConfigValue(groupName, "resetResolution", true), nil, TSM.db.profile.resetResolution[groupName] == nil),
							label = L["Price resolution"],
							relativeWidth = 0.48,
							disabled = TSM.db.profile.resetResolution[groupName] == nil,
							disabledTooltip = overrideTooltip,
							callback = function(self, _, value) SetGroupMoney("resetResolution", value, self) end,
							onRightClick = function(self, value) SetGroupOverride("resetResolution", value, self) end,
							tooltip = L["This determines what size range of prices should be considered a single price point for the reset scan. For example, if this is set to 1s, an auction at 20g50s20c and an auction at 20g49s45c will both be considered to be the same price level."]..unoverrideTooltip,
							hidden = not isDefaultPage and not Config:GetBoolConfigValue(groupName, "resetEnabled", true),
						},
						{
							type = "EditBox",
							value = TSM:FormatTextMoney(Config:GetConfigValue(groupName, "resetMaxPricePer", true), nil, TSM.db.profile.resetMaxPricePer[groupName] == nil),
							label = L["Max price per item"],
							relativeWidth = 0.48,
							disabled = TSM.db.profile.resetMaxPricePer[groupName] == nil,
							disabledTooltip = overrideTooltip,
							callback = function(self, _, value) SetGroupMoney("resetMaxPricePer", value, self) end,
							onRightClick = function(self, value) SetGroupOverride("resetMaxPricePer", value, self) end,
							tooltip = L["This is the maximum amount you want to pay for a single item when reseting."]..unoverrideTooltip,
							hidden = not isDefaultPage and not Config:GetBoolConfigValue(groupName, "resetEnabled", true),
						},
					},
				},
			},
		},
	}
	
	local function PreparePage(data)
		for i=#data, 1, -1 do
			if (type(data[i].hidden) == "function" and data[i].hidden()) or (type(data[i].hidden) ~= "function" and data[i].hidden) then
				tremove(data, i)
			elseif data[i].onRightClick and isDefaultPage then
				data[i].onRightClick = nil
				data[i].disabledTooltip = nil
			elseif data[i].children then
				PreparePage(data[i].children)
			end
		end
		
		for i=1, #data do
			if data[i].settingInfo then
				local key, num, rounding, isBool = unpack(data[i].settingInfo)
				local oldCallback = data[i].callback
				if isBool then
					data[i].value = Config:GetBoolConfigValue(groupName, key, true)
				else
					data[i].value = Config:GetConfigValue(groupName, key, true)
				end
				data[i].relativeWidth = data[i].relativeWidth or 0.48
				data[i].disabled = TSM.db.profile[key][groupName] == nil
				
				if not isDefaultPage then
					data[i].disabledTooltip = overrideTooltip
					data[i].onRightClick = function(self, value)
						SetGroupOverride(key, value, self)
						if oldCallback then
							oldCallback()
						end
					end
				end
				
				if num then
					local oldCallback = data[i].callback
					data[i].callback = function(self, _, value)
						if rounding then
							value = floor(value*100 + 0.5)/100
						end
						TSM.db.profile[key][groupName] = value
						if not TSM.db.global.hideHelp then
							self.parent.children[1]:SetText(GetInfo(num))
						end
						if oldCallback then
							oldCallback()
						end
					end
				end
				data[i].settingInfo = nil
			end
		end
	end
	
	PreparePage(page[1].children)
	TSMAPI:BuildPage(container, page)
end

function Config:DrawProfiles(container)
	local text = {
		default = L["Default"],
		intro = L["You can change the active database profile, so you can have different settings for every character."],
		reset_desc = L["Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over."],
		reset = L["Reset Profile"],
		choose_desc = L["You can either create a new profile by entering a name in the editbox, or choose one of the already exisiting profiles."],
		new = L["New"],
		new_sub = L["Create a new empty profile."],
		choose = L["Existing Profiles"],
		copy_desc = L["Copy the settings from one existing profile into the currently active profile."],
		copy = L["Copy From"],
		delete_desc = L["Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file."],
		delete = L["Delete a Profile"],
		profiles = L["Profiles"],
		current = L["Current Profile:"] .. " " .. TSMAPI.Design:GetInlineColor("link") .. TSM.db:GetCurrentProfile() .. "|r",
	}
	
	-- Popup Confirmation Window used in this module
	StaticPopupDialogs["TSMAucProfiles.DeleteConfirm"] = StaticPopupDialogs["TSMAucProfiles.DeleteConfirm"] or {
		text = L["Are you sure you want to delete the selected profile?"],
		button1 = YES,
		button2 = CANCEL,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		OnCancel = false,
		-- OnAccept defined later
	}
	
	-- Returns a list of all the current profiles with common and nocurrent modifiers.
	-- This code taken from AceDBOptions-3.0.lua
	local function GetProfileList(db, common, nocurrent)
		local profiles = {}
		local tmpprofiles = {}
		local defaultProfiles = {["Default"] = L["Default"]}
		
		-- copy existing profiles into the table
		local currentProfile = db:GetCurrentProfile()
		for i,v in pairs(db:GetProfiles(tmpprofiles)) do 
			if not (nocurrent and v == currentProfile) then 
				profiles[v] = v 
			end 
		end
		
		-- add our default profiles to choose from ( or rename existing profiles)
		for k,v in pairs(defaultProfiles) do
			if (common or profiles[k]) and not (nocurrent and k == currentProfile) then
				profiles[k] = v
			end
		end
		
		return profiles
	end
	
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "Label",
					text = "TradeSkillMaster_Auctioning" .. "\n",
					fontObject = GameFontNormalLarge,
					fullWidth = true,
					colorRed = 255,
					colorGreen = 0,
					colorBlue = 0,
				},
				{
					type = "Label",
					text = text["intro"] .. "\n" .. "\n",
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{
					type = "Label",
					text = text["reset_desc"],
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{	--simplegroup1 for the reset button / current profile text
					type = "SimpleGroup",
					layout = "flow",
					fullWidth = true,
					children = {
						{
							type = "Button",
							text = text["reset"],
							callback = function() TSM.db:ResetProfile() end,
						},
						{
							type = "Label",
							text = text["current"],
							fontObject = GameFontNormal,
						},
					},
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Label",
					text = text["choose_desc"],
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{	--simplegroup2 for the new editbox / existing profiles dropdown
					type = "SimpleGroup",
					layout = "flow",
					fullWidth = true,
					children = {
						{
							type = "EditBox",
							label = text["new"],
							value = "",
							callback = function(_,_,value) 
									TSM.db:SetProfile(value)
									container:SelectTab(4)
								end,
						},
						{
							type = "Dropdown",
							label = text["choose"],
							list = GetProfileList(TSM.db, true, nil),
							value = TSM.db:GetCurrentProfile(),
							callback = function(_,_,value)
									if value ~= TSM.db:GetCurrentProfile() then
										TSM.db:SetProfile(value)
										container:SelectTab(4)
									end
								end,
						},
					},
				},
				{
					type = "Spacer",
					quantity = 1,
				},
				{
					type = "Label",
					text = text["copy_desc"],
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{
					type = "Dropdown",
					label = text["copy"],
					list = GetProfileList(TSM.db, true, nil),
					value = "",
					disabled = not GetProfileList(TSM.db, true, nil) and true,
					callback = function(_,_,value)
							if value ~= TSM.db:GetCurrentProfile() then
								TSM.db:CopyProfile(value)
								container:SelectTab(4)
							end
						end,
				},
				{
					type = "Spacer",
					quantity = 2,
				},
				{
					type = "Label",
					text = text["delete_desc"],
					fontObject = GameFontNormal,
					fullWidth = true,
				},
				{
					type = "Dropdown",
					label = text["delete"],
					list = GetProfileList(TSM.db, true, nil),
					value = "",
					disabled = not GetProfileList(TSM.db, true, nil) and true,
					callback = function(_,_,value)
							StaticPopupDialogs["TSMAucProfiles.DeleteConfirm"].OnAccept = function()
									TSM.db:DeleteProfile(value)
									container:SelectTab(4)
								end
							TSMAPI:ShowStaticPopupDialog("TSMAucProfiles.DeleteConfirm")
						end,
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:DrawItemGroups(container)
	local function AddGroup(editBox, _, value)
		local value, errMsg = TSM.Util:ValidateGroupName(value)
		if not value then
			TSM:Print(errMsg)
			editBox:SetFocus()
			return
		end
		
		TSM.db.profile.groups[value] = {}
		if TSM.db.global.smartGroupCreation then
			TSM:UpdateItemReverseLookup()
			local addedItems = {}
			
			for bag, slot, itemString in TSM:GetBagIterator(true) do
				if itemString then
					local name, link = GetItemInfo(itemString)
					if name and not TSM.itemReverseLookup[itemString] and not TSM.Util:IsSoulbound(bag, slot) then
						local name = gsub(strlower(name), "-", " ")
						local tempValue = gsub(value, "-", " ")
						if strfind(name, tempValue) then
							TSM.db.profile.groups[value][itemString] = true
							tinsert(addedItems, link)
						end
					end
				end
			end
			
			if #addedItems > 5 then
				TSM:Printf(L["Added %s items to %s automatically because they contained the group name in their name. You can turn this off in the options."], #addedItems, "\""..value.."\"")
			elseif #addedItems > 0 then
				TSM:Printf(L["Added the following items to %s automatically because they contained the group name in their name. You can turn this off in the options."], "\""..value.."\"")
				for i=1, #addedItems do
					print(addedItems[i])
				end
			end
		end
		
		Config:UpdateTree()
		if TSM.db.global.makeAnother then
			Config.treeGroup:SelectByPath(2)
			container:SelectTab(2)
		else
			Config.treeGroup:SelectByPath(2, "~", value)
		end
	end
	
	local function AddCategory(editBox, _, value)
		local value, errMsg = TSM.Util:ValidateGroupName(value)
		if not value then
			TSM:Print(errMsg)
			editBox:SetFocus()
			return
		end
		
		TSM.db.profile.categories[value] = {}
		Config:UpdateTree()
		Config.treeGroup:SelectByPath(2, value)
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Add group"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							fontObject = GameFontNormal,
							text = L["A group contains items that you wish to sell with similar conditions (stack size, fallback price, etc).  Default settings may be overridden by a group's individual settings."],
						},
						{
							type = "EditBox",
							label = L["Group name"],
							relativeWidth = 0.8,
							callback = AddGroup,
							tooltip = L["Name of the new group, this can be whatever you want and has no relation to how the group itself functions."],
						},
						{
							type = "Spacer",
						},
						{
							type = "Button",
							text = L["Import Auctioning Group"],
							relativeWidth = 0.5,
							callback = TSM.OpenImportFrame,
							tooltip = L["This feature can be used to import groups from outside of the game. For example, if somebody exported their group onto a blog, you could use this feature to import that group and Auctioning would create a group with the same settings / items."],
						},
						{
							type = "CheckBox",
							label = L["Make another after this one."],
							quickCBInfo = {TSM.db.global, "makeAnother"},
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Add category"],
					children = {
						{
							type = "Label",
							relativeWidth = 1,
							fontObject = GameFontNormal,
							text = L["A category contains groups with similar settings and acts like an organizational folder. You may override default settings by category (and then override category settings by group)."],
						},
						{
							type = "EditBox",
							label = L["Category name"],
							relativeWidth = 0.8,
							callback = AddCategory,
							tooltip = L["Name of the new category, this can be whatever you want and has no relation to how the category itself functions."],
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

local selectedItems = {}
function Config:DrawQuickCreation(container)
	TSM:UpdateItemReverseLookup()
	
	local itemsToAdd = {}

	local ungroupedItems, usedLinks = {}, {}
	for bag, slot, itemString in TSM:GetBagIterator(true) do
		if itemString and not TSM.Util:IsSoulbound(bag, slot) then
			local link = GetContainerItemLink(bag, slot)
			local itemID = TSMAPI:GetItemID(link)
			if not usedLinks[itemString] and not TSM.itemReverseLookup[itemString] and not TSM.itemReverseLookup[itemID] then
				local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(link)
				if name and not (TSM.db.global.hideGray and quality == 0) and not selectedItems[itemString] then
					tinsert(ungroupedItems, {value=itemString, text=link, icon=texture, name=name, tooltip=TSMAPI:GetItemID(link)})
					usedLinks[itemString] = true
				end
			end
		end
	end
	sort(ungroupedItems, function(a,b) return a.name < b.name end)
	
	for itemString in pairs(selectedItems) do
		local name, link, quality, _, _, _, _, _, _, texture = GetItemInfo(itemString)
		if link then
			tinsert(itemsToAdd, {value=itemString, text=link, icon=texture, name=name, tooltip=TSMAPI:GetItemID(link)})
		end
	end
	sort(itemsToAdd, function(a,b) return a.name < b.name end)
	
	local selectedCategory = "<Uncategorized Groups>"
	local categories = {["<Uncategorized Groups>"]="<Uncategorized Groups>"}
	local individualGroups = true
	
	for name in pairs(TSM.db.profile.categories) do
		categories[name] = name
	end
	
	local function OnButtonClick()
		for itemString in pairs(selectedItems) do
			local itemName = strlower(GetItemInfo(itemString))
			local groupName = itemName
			for i=1, 100 do
				if TSM.db.profile.groups[groupName] then
					groupName = itemName..i
				else
					break
				end
			end
			
			TSM.db.profile.groups[groupName] = {[itemString]=true}
			
			if selectedCategory ~= "<Uncategorized Groups>" then
				TSM.db.profile.categories[selectedCategory][groupName] = true
			end
		end
		selectedItems = {}
		Config:UpdateTree()
		container:SelectTab(2)
	end
	
	local page = {
		{
			type = "ScrollFrame",
			layout = "List",
			children = {
				{	-- simple group to contain everything
					type = "InlineGroup",
					layout = "Flow",
					children = {
						{
							type = "Label",
							text = "Select items in the selection list below to quickly create groups for them. Each item will be placed in its own individual group. Use the options below to control how these groups are created.",
							fullWidth = true,
						},
						{
							type = "HeadingLine",
						},
						{
							type = "Dropdown",
							label = "Add Groups to Category:",
							list = categories,
							value = selectedCategory,
							relativeWidth = 0.5,
							callback = function(_,_,value) selectedCategory = value end,
							tooltip = "Groups created will be added to the selected category.",
						},
						{
							type = "Button",
							text = "Create Groups!",
							relativeWidth = 0.49,
							callback = OnButtonClick,
						}
					},
				},
				{	-- simple group to contain everything
					type = "SimpleGroup",
					layout = "Fill",
					height = 420,
					children = {
						{
							type = "SelectionList",
							leftTitle = L["Items not in any group:"],
							rightTitle = L["Items to be added:"],
							leftList = ungroupedItems,
							rightList = itemsToAdd,
							onAdd = function(_,_,selected)
									for _, item in ipairs(selected) do
										selectedItems[item] = true
									end
									container:SelectTab(3)
								end,
							onRemove = function(_,_,selected)
									for _, item in ipairs(selected) do
										selectedItems[item] = nil
									end
									container:SelectTab(3)
								end,
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:DrawWhitelist(container)
	local function AddPlayer(self, _, value)
		value = string.trim(strlower(value or ""))
		if value == "" then return TSM:Print(L["No name entered."]) end
		
		if TSM.db.factionrealm.whitelist[value] then
			TSM:Printf(L["The player \"%s\" is already on your whitelist."], TSM.db.factionrealm.whitelist[value])
			return
		end
		
		if TSM.db.factionrealm.blacklist[value] then
			TSM:Print(L["You can not whitelist characters whom are on your blacklist."])
			return
		end
		
		for player in pairs(TSM.db.factionrealm.player) do
			if strlower(player) == value then
				TSM:Printf(L["You do not need to add \"%s\", alts are whitelisted automatically."], player)
				return
			end
		end
		
		TSM.db.factionrealm.whitelist[strlower(value)] = value
		self.parent.parent.parent:SelectTab(2)
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Help"],
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = L["Whitelists allow you to set other players besides you and your alts that you do not want to undercut; however, if somebody on your whitelist matches your buyout but lists a lower bid it will still consider them undercutting."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Add player"],
					children = {
						{
							type = "EditBox",
							label = L["Player name"],
							relativeWidth = 0.5,
							callback = AddPlayer,
							tooltip = L["Add a new player to your whitelist."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Whitelist"],
					children = {},
				},
			},
		},
	}
	
	for name in pairs(TSM.db.factionrealm.whitelist) do
		tinsert(page[1].children[3].children,
			{
				type = "Label",
				text = TSM.db.factionrealm.whitelist[name],
				fontObject = GameFontNormal,
			})
		tinsert(page[1].children[3].children,
			{
				type = "Button",
				text = L["Delete"],
				relativeWidth = 0.3,
				callback = function(self)
						TSM.db.factionrealm.whitelist[name] = nil
						container:SelectTab(2)
					end,
			})
	end
	
	if #(page[1].children[3].children) == 0 then
		tinsert(page[1].children[3].children,
			{
				type = "Label",
				text = L["You do not have any players on your whitelist yet."],
				fontObject = GameFontNormal,
				fullWidth = true,
			})
	end
	
	TSMAPI:BuildPage(container, page)
end

function Config:DrawBlacklist(container)
	local function AddPlayer(self, _, value)
		value = string.trim(strlower(value or ""))
		if value == "" then return TSM:Print(L["No name entered."]) end
		
		if TSM.db.factionrealm.blacklist[value] then
			TSM:Printf(L["The player \"%s\" is already on your blacklist."], TSM.db.factionrealm.blacklist[value])
			return
		end
		
		if TSM.db.factionrealm.whitelist[value] then
			TSM:Print(L["You can not blacklist characters whom are on your whitelist."])
			return
		end
		
		for player in pairs(TSM.db.factionrealm.player) do
			if strlower(player) == value then
				TSM:Print(L["You can not blacklist yourself."])
				return
			end
		end
		
		TSM.db.factionrealm.blacklist[strlower(value)] = value
		self.parent.parent.parent:SelectTab(3)
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Help"],
					children = {
						{
							type = "Label",
							fullWidth = true,
							fontObject = GameFontNormal,
							text = L["Blacklists allows you to undercut a competitor no matter how low their threshold may be. If the lowest auction of an item is owned by somebody on your blacklist, your threshold will be ignored for that item and you will undercut them regardless of whether they are above or below your threshold."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Add player"],
					children = {
						{
							type = "EditBox",
							label = L["Player name"],
							relativeWidth = 0.5,
							callback = AddPlayer,
							tooltip = L["Add a new player to your blacklist."],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Blacklist"],
					children = {},
				},
			},
		},
	}
	
	for name in pairs(TSM.db.factionrealm.blacklist) do
		tinsert(page[1].children[3].children,
			{
				type = "Label",
				text = TSM.db.factionrealm.blacklist[name],
				fontObject = GameFontNormal,
			})
		tinsert(page[1].children[3].children,
			{
				type = "Button",
				text = L["Delete"],
				relativeWidth = 0.3,
				callback = function(self)
						TSM.db.factionrealm.blacklist[name] = nil
						container:SelectTab(3)
					end,
			})
	end
	
	if #(page[1].children[3].children) == 0 then
		tinsert(page[1].children[3].children,
			{
				type = "Label",
				text = L["You do not have any players on your blacklist yet."],
				fontObject = GameFontNormal,
				fullWidth = true,
			})
	end
	
	TSMAPI:BuildPage(container, page)
end

function Config:DrawGroupManagement(container, group)
	TSM:UpdateGroupReverseLookup()
	local function RenameGroup(self, _, value)
		local value, errMsg = TSM.Util:ValidateGroupName(value)
		if not value then
			TSM:Print(errMsg)
			return
		end
		
		TSM:UpdateGroupReverseLookup()
		TSM.db.profile.groups[value] = CopyTable(TSM.db.profile.groups[group])
		TSM.db.profile.groups[group] = nil
		for key, data in pairs(TSM.db.profile) do
			if type(data) == "table" and data[group] ~= nil then
				data[value] = data[group]
				data[group] = nil
			end
		end
		if TSM.groupReverseLookup[group] then
			TSM.db.profile.categories[TSM.groupReverseLookup[group]][value] = true
			TSM.db.profile.categories[TSM.groupReverseLookup[group]][group] = nil
		end
		Config:UpdateTree()
		Config.treeGroup:SelectByPath(2, value)
		group = value
	end
	
	local function DeleteGroup(confirmed)
		if confirmed then
			-- Popup Confirmation Window used in this module
			StaticPopupDialogs["TSMAucGroups.DeleteConfirm"] = StaticPopupDialogs["TSMAucGroups.DeleteConfirm"] or {
				text = L["Are you SURE you want to delete this group?"],
				button1 = YES,
				button2 = CANCEL,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				OnCancel = false,
			}
			StaticPopupDialogs["TSMAucGroups.DeleteConfirm"].OnAccept = function() DeleteGroup() end,
			TSMAPI:ShowStaticPopupDialog("TSMAucGroups.DeleteConfirm")
			return
		end
		TSM:UpdateGroupReverseLookup()
		TSM.db.profile.groups[group] = nil
		for key, data in pairs(TSM.db.profile) do
			if type(data) == "table" and data[group] ~= nil then
				data[group] = nil
			end
		end
		if TSM.groupReverseLookup[group] then
			TSM.db.profile.categories[TSM.groupReverseLookup[group]][group] = nil
		end
		
		Config:UpdateTree()
		Config.treeGroup:SelectByPath(2)
	end

	local function CreateShoppingListFromGroup()
		local items = {}
		for itemString in pairs(TSM.db.profile.groups[group]) do
			local itemID
			if tonumber(itemString) then
				itemID = itemString
			else
				itemID = TSMAPI:GetItemID(itemString)
			end
			items[itemID] = true
		end
		local newName = TSMAPI:GetData("newShoppingList", group, items)
		if not newName then
			TSM:Print(L["Failed to create shopping list."] .. " Make sure your Shopping is up to date.")
		else
			TSM:Print(L["Created new shopping list: "] .. newName)
		end
	end
	
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Rename"],
					children = {
						{
							type = "EditBox",
							label = L["New group name"],
							callback = RenameGroup,
							tooltip = L["Rename this group to something else!"],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Delete"],
					children = {
						{
							type = "Button",
							text = L["Delete group"],
							relativeWidth = 0.3,
							callback = DeleteGroup,
							tooltip = L["Delete this group, this cannot be undone!"],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Export"],
					children = {
						{
							type = "Button",
							text = L["Export Group Data"],
							relativeWidth = 0.5,
							callback = function() TSM:OpenExportFrame(group) end,
							tooltip = L["Exports the data for this group. This allows you to share your group data with other TradeSkillMaster_Auctioning users."],
						},
						{
							type = "Button",
							text = L["Create Shopping List from Group"],
							relativeWidth = 0.5,
							callback = function() CreateShoppingListFromGroup() end,
							tooltip = L["Creates a shopping list that contains all the items which are in this group. There is no confirmation or popup window for this."],
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:DrawAddRemoveItem(container, group)
	if not TSM.db.profile.groups[group] then return end
	TSM:UpdateItemReverseLookup()
	
	local function SelectItemsMatching(selectionList, _, value)
		value = strlower(value:trim())
		selectionList:UnselectAllItems()
		if not value or value == "" then return end
		
		local itemList = {}
		for bag, slot, itemString in TSM:GetBagIterator(true) do
			if itemString then
				local name = GetItemInfo(itemString)
				if name and strmatch(strlower(name), value) and not TSM.itemReverseLookup[itemString] and not TSM.Util:IsSoulbound(bag, slot) then
					tinsert(itemList, itemString)
				end
			end
		end
		
		for itemString in pairs(TSM.db.profile.groups[group]) do
			local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(itemString)
			if name and strmatch(strlower(name), value) then
				tinsert(itemList, itemString)
			end
		end
		
		selectionList:SelectItems(itemList)
	end
	
	local itemsInGroup = {}
	for itemString in pairs(TSM.db.profile.groups[group]) do
		local name, link, _, _, _, _, _, _, _, texture = GetItemInfo(itemString)
		if name then
			tinsert(itemsInGroup, {value=itemString, text=link, icon=texture, name=name, tooltip=link})
		end
	end
	sort(itemsInGroup, function(a,b) return a.name < b.name end)

	local ungroupedItems, usedLinks = {}, {}
	for bag, slot, itemString in TSM:GetBagIterator(true) do
		if itemString and not TSM.Util:IsSoulbound(bag, slot) then
			local link = GetContainerItemLink(bag, slot)
			local itemID = TSMAPI:GetItemID(link)
			if not usedLinks[itemString] and not TSM.itemReverseLookup[itemString] and not usedLinks[itemID] and not TSM.itemReverseLookup[itemID] then
				if TSM.db.profile.itemIDGroups[group] then
					link = select(2, GetItemInfo(itemID)) or link
				end
				
				local name, _, quality, _, _, _, _, _, _, texture = GetItemInfo(link)
				if not name then
					texture, _, _, quality = GetContainerItemInfo(bag, slot)
					name = ""
				end
				if not (TSM.db.global.hideGray and quality == 0) then
					if TSM.db.profile.itemIDGroups[group] then
						tinsert(ungroupedItems, {value=itemID, text=link, icon=texture, name=name, tooltip=TSMAPI:GetItemID(link)})
						usedLinks[itemID] = true
					else
						tinsert(ungroupedItems, {value=itemString, text=link, icon=texture, name=name, tooltip=link})
						usedLinks[itemString] = true
					end
				end
			end
		end
	end
	sort(ungroupedItems, function(a,b) return a.name < b.name end)
	
	local page = {
		{	-- scroll frame to contain everything
			type = "SimpleGroup",
			layout = "Fill",
			children = {
				{
					type = "SelectionList",
					leftTitle = L["Items not in any group:"],
					rightTitle = L["Items in this group:"],
					filterTitle = L["Select Matches:"],
					filterTooltip = L["Selects all items in either list matching the entered filter. Entering \"Glyph of\" will select any item with \"Glyph of\" in the name."],
					leftList = ungroupedItems,
					rightList = itemsInGroup,
					onAdd = function(_,_,selected)
							for i=#selected, 1, -1 do
								TSM.db.profile.groups[group][selected[i]] = true
							end
							container:SelectTab(2)
						end,
					onRemove = function(_,_,selected)
							for i=#selected, 1, -1 do
								TSM.db.profile.groups[group][selected[i]] = nil
							end
							container:SelectTab(2)
						end,
					onFilter = SelectItemsMatching,
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:DrawCategoryManagement(container, category)
	local function RenameCategory(self, _, value)
		local value, errMsg = TSM.Util:ValidateGroupName(value)
		if not value then
			TSM:Print(errMsg)
			return
		end
		
		TSM.db.profile.categories[value] = CopyTable(TSM.db.profile.categories[category])
		TSM.db.profile.categories[category] = nil
		for key, data in pairs(TSM.db.profile) do
			if type(data) == "table" and data[category] ~= nil then
				data[value] = data[category]
				data[category] = nil
			end
		end
		Config:UpdateTree()
		Config.treeGroup:SelectByPath(2, value)
		category = value
	end
	
	local function DeleteCategory(notConfirmed)
		if notConfirmed then
			-- Popup Confirmation Window used in this module
			StaticPopupDialogs["TSM.Category.DeleteConfirm"] = StaticPopupDialogs["TSM.Category.DeleteConfirm"] or {
				text = L["Are you SURE you want to delete this category?"],
				button1 = YES,
				button2 = CANCEL,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				OnCancel = false,
			}
			StaticPopupDialogs["TSM.Category.DeleteConfirm"].OnAccept = function() DeleteCategory() end,
			TSMAPI:ShowStaticPopupDialog("TSM.Category.DeleteConfirm")
			return
		end
		
		TSM.db.profile.categories[category] = nil
		for key, data in pairs(TSM.db.profile) do
			if type(data) == "table" and data[category] ~= nil then
				data[category] = nil
			end
		end
		
		Config:UpdateTree()
		Config.treeGroup:SelectByPath(2)
	end
	
	local function DeleteGroupsInCategory(notConfirmed)
		if notConfirmed then
			-- Popup Confirmation Window used in this module
			StaticPopupDialogs["TSM.GroupsInCategory.DeleteConfirm"] = StaticPopupDialogs["TSM.GroupsInCategory.DeleteConfirm"] or {
				text = L["Are you SURE you want to delete all the groups in this category?"],
				button1 = YES,
				button2 = CANCEL,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				OnCancel = false,
			}
			StaticPopupDialogs["TSM.GroupsInCategory.DeleteConfirm"].OnAccept = function() DeleteGroupsInCategory() end,
			TSMAPI:ShowStaticPopupDialog("TSM.GroupsInCategory.DeleteConfirm")
			return
		end
		
		for groupName in pairs(TSM.db.profile.categories[category]) do
			for key, data in pairs(TSM.db.profile) do
				if type(data) == "table" and key ~= "groups" and key ~= "categories" then
					data[groupName] = nil
				end
			end
			TSM.db.profile.groups[groupName] = nil
		end
		TSM.db.profile.categories[category] = {}
		
		Config:UpdateTree()
		Config.treeGroup:SelectByPath(2, category)
	end
	
	local function CreateShoppingListFromCategory()
		local items = {}
		for group in pairs(TSM.db.profile.categories[category]) do
			for itemString in pairs(TSM.db.profile.groups[group]) do
				local itemID
				if tonumber(itemString) then
					itemID = itemString
				else
					itemID = TSMAPI:GetItemID(itemString)
				end
				items[itemID] = true
			end
		end
		local newName = TSMAPI:GetData("newShoppingList", category, items)
		if not newName then
			TSM:Print(L["Failed to create shopping list."] .. " Make sure your Shopping is up to date.")
		else
			TSM:Print(L["Created new shopping list: "] .. newName)
		end
	end

	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Rename"],
					children = {
						{
							type = "EditBox",
							label = L["New category name"],
							callback = RenameCategory,
							tooltip = L["Rename this category to something else!"],
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					title = L["Delete"],
					children = {
						{
							type = "Button",
							text = L["Delete category"],
							relativeWidth = 0.3,
							callback = DeleteCategory,
							tooltip = L["Delete this category, this cannot be undone!"],
						},
						{
							type = "Label",
							relativeWidth = 0.19,
						},
						{
							type = "Button",
							text = L["Delete All Groups In Category"],
							relativeWidth = 0.5,
							callback = DeleteGroupsInCategory,
							tooltip = L["Delete all groups inside this category. This cannot be undone!"],
						},
						{
							type = "Button",
							text = L["Create Shopping List from Category"],
							relativeWidth = 0.7,
							callback = function() CreateShoppingListFromCategory() end,
							tooltip = L["Creates a shopping list that contains all the items which are in this category. There is no confirmation or popup window for this."],
						},
					},
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end

function Config:DrawAddRemoveGroup(container, category)
	TSM:UpdateGroupReverseLookup()
	
	local groupsInCategory = {}
	for groupName in pairs(TSM.db.profile.categories[category]) do
		tinsert(groupsInCategory, {value=groupName, name=groupName, text=groupName, tooltip=groupName})
	end
	sort(groupsInCategory, function(a,b) return a.name < b.name end)
	
	local uncategorizedGroups = {}
	for groupName in pairs(TSM.db.profile.groups) do
		if not TSM.groupReverseLookup[groupName] then
			tinsert(uncategorizedGroups, {value=groupName, name=groupName, text=groupName, tooltip=groupName})
		end
	end
	sort(uncategorizedGroups, function(a,b) return a.name < b.name end)
	
	local page = {
		{	-- scroll frame to contain everything
			type = "SimpleGroup",
			layout = "Fill",
			children = {
				{
					type = "SelectionList",
					leftTitle = L["Uncategorized Groups:"],
					rightTitle = L["Groups in this Category:"],
					leftList = uncategorizedGroups,
					rightList = groupsInCategory,
					onAdd = function(_,_,selected)
							for i=#selected, 1, -1 do
								TSM.db.profile.categories[category][selected[i]] = true
							end
							Config:UpdateTree()
							container:SelectTab(2)
						end,
					onRemove = function(_,_,selected)
							for i=#selected, 1, -1 do
								TSM.db.profile.categories[category][selected[i]] = nil
							end
							Config:UpdateTree()
							container:SelectTab(2)
						end,
				},
			},
		},
	}
	
	TSMAPI:BuildPage(container, page)
end