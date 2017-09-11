-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Auctioning - AddOn by Sapu94							 	  --
--   			http://www.curse.com/addons/wow/tradeskillmaster_accounting  		  			  --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --


local TSM = select(2, ...)
local Wizard = TSM:NewModule("Wizard")
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Auctioning") -- loads the localization tables

function Wizard:GetErrorText(key)
	local value = Wizard.data[key]
	local default = TSM.db.profile[key] and TSM.db.profile[key].default
	if value == default then
		return ""
	elseif value == false then
		return "|cffff0000".."Invalid".."|r"
	else
		return "|cff00ff00".."Valid".."|r"
	end
end

function Wizard:DrawWizard(container)
	Wizard:LoadPages()
	Wizard.data = {}
	Wizard.container = container
	Wizard:LoadWizardPage(1)
end

function Wizard:LoadWizardPage(num)
	Wizard.page = num or Wizard.page
	
	if Wizard.page > #Wizard.pages then
		-- go to group options
		return TSM.Config.treeGroup:SelectByPath(2, "~", Wizard.data.groupName)
	elseif Wizard.page == #Wizard.pages then
		-- create the group
		local itemString = Wizard.data.itemString
		local groupName = Wizard.data.groupName
		Wizard.data.thresholdPriceMethod = "gold"
		Wizard.data.fallbackPriceMethod = "gold"
		TSM.db.profile.groups[groupName] = {[itemString]=true}
		for key, data in pairs(Wizard.data) do
			if TSM.db.profile[key] then
				TSM.db.profile[key][groupName] = data
			end
		end
		TSM.Config:UpdateTree()
	end
	
	if #Wizard.container.children > 0 then
		Wizard.container:ReleaseChildren()
	end
	
	local currentPage = Wizard.pages[Wizard.page]
	local desc = type(currentPage.desc) == "function" and currentPage.desc() or currentPage.desc
	local pageSteps = CopyTable(currentPage.pageSteps)
	local widgets, keys = {}, {}
	for i, step in ipairs(pageSteps) do
		tinsert(widgets, {type="Label", text=step.desc, fullWidth=true})
		
		local widget = step.widget
		if widget then
			local parser, key = widget.parser, widget.key
			local defaultValue = TSM.db.profile[key] and TSM.db.profile[key].default
			if Wizard.data[key] == nil then
				Wizard.data[key] = defaultValue
			end
		
			if type(widget.value) == "function" then
				widget.value = widget.value()
			end
			widget.value = widget.value or Wizard.data[key]
			widget.callback = function(_,_,value)
				if parser then
					value = parser(value)
				end
				
				if defaultValue then
					value = value or defaultValue
				end
				Wizard.data[key] = value
				Wizard:LoadWizardPage()
			end
			
			tinsert(keys, key)
			tinsert(widgets, widget)
			tinsert(widgets, {type="Label", text=Wizard:GetErrorText(key), relativeWidth=0.29})
		end
		
		if i ~= #pageSteps then
			tinsert(widgets, {type="HeadingLine"})
		end
	end
	
	local function IsPageComplete()
		for _, key in ipairs(keys) do
			if not Wizard.data[key] then
				return false
			end
		end
		
		return true
	end
	
	local page = {
		{	-- scroll frame to contain everything
			type = "ScrollFrame",
			layout = "List",
			children = {
				{
					type = "InlineGroup",
					layout = "flow",
					title = format("Setup Wizard (page %s/%s)", Wizard.page, #Wizard.pages),
					children = {
						{
							type = "Label",
							text = desc,
							fullWidth = true,
						},
					},
				},
				{
					type = "InlineGroup",
					layout = "flow",
					children = widgets,
				},
				{
					type = "InlineGroup",
					layout = "flow",
					children = {
						{
							type = "Label",
							text = "Once this page has been completely filled out, the button below will allow you to proceed to the next page.",
							relativeWidth = 1,
						},
						{
							type = "Button",
							text = "Next Page",
							disabled = not IsPageComplete(),
							relativeWidth = 1,
							callback = function() Wizard:LoadWizardPage(Wizard.page+1) end,
						}
					}
				}
			},
		},
	}

	TSMAPI:BuildPage(Wizard.container, page)
end


function Wizard:LoadPages()
	if Wizard.pages then return end
	local color = TSMAPI.Design:GetInlineColor("category2")

	-- all the pages which make up this wizard
	Wizard.pages = {
		{ -- page 1 - Item / Group Name
			desc = "This wizard will walk you through setting up TradeSkillMaster_Auctioning to manage the posting, canceling, and/or resetting of your items. Be sure to read the instructions carefully and remember that you can always change the settings later. Take note of the terms which are in "..color.."this color|r as they are part of the common TSM_Auctioning terminology and you'll see them again later.",
			pageSteps = {
				{
					desc = "Auctioning uses "..color.."groups|r as a container of items which you'd like to post/cancel/reset in the same fasion. Each group can have its own unique set of settings associated with it and can contain one or more items."
				},
				{
					desc = "Place the item link of an item which you'd like to set up an Auctioning group for in the box below. You can either shift click the item link from chat or drag the item into the box from your inventory.",
					widget = {
						type = "EditBox",
						label = "Item Link",
						relativeWidth = 0.7,
						value = function() return Wizard.data.itemString and select(2, GetItemInfo(Wizard.data.itemString)) or "" end,
						parser = function(value)
								local ok, itemString = pcall(function() return TSMAPI:GetItemString(value) end)
								Wizard.data.itemString = ok and itemString or false
								if Wizard.data.itemString and not Wizard.data.groupName then
									local groupName = TSM.Util:ValidateGroupName(value)
									Wizard.data.groupName = groupName or Wizard.data.groupName
								end
								return Wizard.data.itemString
							end,
						key = "itemString",
					},
				},
				{
					desc = "By default, this wizard will give this group the name of the item you entered above. You can change the name below. |cffff0000NOTE: Group names must be completely lower case but may contain numbers and symbols.|r",
					widget = {
						type = "EditBox",
						label = "Group Name",
						value = function() return Wizard.data.groupName or "" end,
						relativeWidth = 0.7,
						parser = function(value) return TSM.Util:ValidateGroupName(value) end,
						key = "groupName",
					},
				},
			}
		},
		{ -- page 2 - Posting: Per auction, Post cap, Post time, (Use per auction as cap)
			desc = function() return format("This page will set up a few settings which control how Auctioning will post the items in the '%s' group.\n\n|cffff0000NOTE: For sliders, you can drag the slider or type a number into the box underneath the slider. If you do the latter, make sure you hit 'enter' to save the value.|r", Wizard.data.groupName) end,
			pageSteps = {
				{
					desc = "What size of stack should Auctioning post items in? Setting the "..color.."per auction|r to 20 would post the items in this group in stacks of 20.",
					widget = {
						type="Slider",
						label = L["Per auction"],
						relativeWidth = 0.5,
						min = 1,
						max = 1000,
						step = 1,
						key = "perAuction",
					},
				},
				{
					desc = "How many auctions of the items in this group should be posted at any given time? Auctioning calls this the "..color.."post cap|r.",
					widget = {
						type = "Slider",
						label = L["Post cap"],
						relativeWidth = 0.5,
						min = 1,
						max = 500,
						step = 1,
						key = "postCap",
					},
				},
				{
					desc = "How long should auctions be posted for? Auctioning calls this the "..color.."post time|r.",
					widget = {
						type = "Dropdown",
						label = L["Post time"],
						list = {[12] = L["12 hours"], [24] = L["24 hours"], [48] = L["48 hours"]},
						key = "postTime",
					},
				},
				{
					desc = "|cffff0000NOTE: This wizard does not cover the '|r"..color.."use per auction as cap|r|cffff0000' setting. You can read about and configure this setting by finding it in the group options after the wizard is completed.|r"
				},
			}
		},
		{ -- page 3 - Posting: Threshold, Fallback
			desc = function() return format("This page sets a few price points that Auctioning will use when posting the items in the '%s' group. For the "..color.."price threshold|r and "..color.."fallback price|r, this wizard requires you to enter a fixed gold amount, but it's possible to have Auctioning calculate the value as a %% of some price source. You can set this up in the group options after you've completed the wizard.\n\n|cffff0000NOTE:Your fallback must be at least 1c greater than your threshold!|r", Wizard.data.groupName) end,
			pageSteps = {
				{
					desc = "What is the lowest price per item (NOT per stack), which you want Auctioning to post this item for? This is known as the "..color.."price threshold|r (aka 'threshold') and is typically the lowest price you'd consider selling the item for.\n\n|cffff0000NOTE: You must enter this in the form of '#g#s#c' ('3g50s', '100g', '5s2c' are all valid).|r",
					widget = {
						type = "EditBox",
						value = function() return TSM:FormatTextMoney(Wizard.data.threshold) end,
						label = L["Price threshold"],
						relativeWidth = 0.5,
						parser = function(value) return TSM.Util:UnformatTextMoney(value) end,
						key = "threshold",
					},
				},
				{
					desc = "What price should Auctioning post this item at if you are the only one posting? This is known as the "..color.."fallback price|r (aka 'fallback') and is typically the highest price you think you could reasonably sell the item for.\n\n|cffff0000NOTE: You must enter this in the form of '#g#s#c' ('3g50s', '100g', '5s2c' are all valid).|r",
					widget = {
						type = "EditBox",
						value = function() return TSM:FormatTextMoney(Wizard.data.fallback) end,
						label = L["Fallback price"],
						relativeWidth = 0.5,
						parser = function(value) return TSM.Util:UnformatTextMoney(value) end,
						key = "fallback",
					},
				},
			}
		},
		{ -- page 4 - Posting: Max price, Undercut, bid
			desc = function() return format("This page sets up more settings which Auctioning will use when posting the items in the '%s' group.", Wizard.data.groupName) end,
			pageSteps = {
				{
					desc = "What percentage of your fallback should Auctioning use as your "..color.."maximum price|r? Along with using your fallback price when you're the only person posting an item, Auctioning will also use it when you're the only one posting below your maximum price. This protects you from pointlessly undercutting auctions which are way above the reasonable price for an item.",
					widget = {
						type = "Slider",
						label = L["Maximum price"],
						isPercent = true,
						min = 1,
						max = 10,
						step = 0.1,
						key = "fallbackCap",
					},
				},
				{
					desc = "By how much should Auctioning undercut the competition? This setting defines how much below the current cheapest auction yours will be posted (assuming this price satisfies the other rules).\n\n|cffff0000NOTE: You must enter this in the form of '#g#s#c' ('3g50s', '100g', '5s2c' are all valid).|r",
					widget = {
						type = "EditBox",
						value = function() return TSM:FormatTextMoney(Wizard.data.undercut) end,
						label = L["Undercut by"],
						relativeWidth = 0.5,
						parser = function(value) return TSM.Util:UnformatTextMoney(value) end,
						key = "undercut",
					},
				},
				{
					desc = "What % of your buyout price should the bid be set to when posting auctions? If this is 100%, your buyout and starting bid will be identical.",
					widget = {
						type = "Slider",
						label = L["Bid percent"],
						isPercent = true,
						min = 0,
						max = 1,
						step = 0.05,
						key = "bidPercent",
					},
				},
				{
					desc = "By default, if the current market (cheapest auction) for a given item is below the threshold you have set, Auctioning will not post the item. You can set Auctioning to instead post the item at your fallback, threshold, or a custom value. This '"..color.."reset method|r' setting is not covered by this wizard and can be configured in the group options afterwards.",
				},
			}
		},
		{ -- page 6 - General: Ignore stacks under, Ignore stacks over
			desc = function() return format("The settings on this page apply when Auctioning is posting, canceling, and resetting the items in the '%s' group.", Wizard.data.groupName) end,
			pageSteps = {
				{
					desc = "When scanning, should Auctioning throw out auctions which are |cffff0000below|r a certain stack size? For example, if you're posting 20 stacks you may not want to worry about undercutting people who are posting single stacks, so you'd set this to a value greater than 1. By default, this is set to 1 which means this setting has no effect.",
					widget = {
						type = "Slider",
						label = L["Ignore stacks under"],
						min = 1,
						max = 1000,
						step = 1,
						key = "ignoreStacksUnder",
					},
				},
				{
					desc = "When scanning, should Auctioning throw out auctions which are |cffff0000above|r a certain stack size? For example, if you're posting single stacks you may not want to worry about undercutting people who are posting 20 stacks, so you'd set this to a value less than 20. By default, this is set to 1000 which means this setting has no effect.",
					widget = {
						type = "Slider",
						label = L["Ignore stacks over"],
						min = 1,
						max = 1000,
						step = 1,
						key = "ignoreStacksOver",
					},
				},
				{
					desc = "Should Auctioning ignore auctions with a low amount of time remaining when it posts, cancels, or resets? Any auctions with less time left than selected below will be ignored.",
					widget = {
						type = "Dropdown",
						label = L["Ignore low duration auctions"],
						list = {[0]=L["<none>"], [1]=L["short (less than 30 minutes)"], [2]=L["medium (less than 2 hours)"], [3]=L["long (less than 12 hours)"]},
						key = "minDuration",
					},
				},
			}
		},
		{ -- page 7 - The End
			desc = function() return format("You have now setup the '%s' group for posting and canceling!", Wizard.data.groupName) end,
			pageSteps = {
				{
					desc = "There are some settings which this tutorial didn't conver. Be sure to visit the group options and read their tooltips to learn about how to take advantage of them.",
				},
				{
					desc = "One big feature that wasn't covered is the reset scan. This has its own section in the group settings and allows you to raise the price on items which you have Auctioning groups setup for (and the reset scan enabled for by purchasing the cheap auctions and reposting them at a higher price.",
				},
				{
					desc = "You can keep your groups organized by creating categories!",
				},
				{
					desc = "|cffff0000Click on the 'next page' button to go to options for the group you just created.|r",
				},
			}
		},
	}
end