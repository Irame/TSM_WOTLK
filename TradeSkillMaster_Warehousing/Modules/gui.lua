-- ---------------------------------------------------------------------------------------
-- 					TradeSkillMaster_Destroying - AddOn by Geemoney			   --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_destroying.aspx --
--																	   --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/	   --
-- 	Please contact the license holder (Sapu) via email at	sapu94@gmail.com with any   --
--		questions or concerns regarding this license.				 		   --
-- ---------------------------------------------------------------------------------------
--TSMAPI:RegisterSlashCommand("destroying", GUI:Load, "/TSM Destroying", notLoadFunc)

-- loads the localization table --
local L = LibStub("AceLocale-3.0"):GetLocale("TradeSkillMaster_Warehousing") 

-- load the parent file (TSM) into a local variable and register this file as a module
local TSM = select(2, ...)
local GUI = TSM:NewModule("GUI", "AceEvent-3.0", "AceHook-3.0")--TSM:NewModule("GUI", "AceEvent-3.0")
local AceGUI = LibStub("AceGUI-3.0") -- load the AceGUI libraries

local function getHelpString1()
    return
        L["Warehousing"]..":\n"..
        L["   Warehousing will try to get the right number of items, if there are not enough in the bank to fill out order, it will grab all that there is."].."\n"..
        "\n"..L["Crafting"]..":\n"..
        L["   Again warehousing will try to fill out the order, but if it is short, it will remember how much it is short by and adjust its counts. So then you can go to another bank or another character and warehousing will grab the difference. Once the order has been completely filled out, warehousing will reset the count back to the original total. You cannot move a Crafting Queue bags->bank, only bank->bags."]..
        L["Warehousing will only keep track of items that you have moved out of you bank and into your bags via the Inventory_Manager.  Finaly if you ever feel the need to reset the counts for a queue simply use the dropdown menu below."] 
end

local function getHelpString2()
    return
       "\n"..L["Auctioning"]..":\n"..
        L["   Warehousing will move the difference between your post cap and the number of auctions you have from the source to the destination."].."\n"..
        "\n"..L["Empty Bags/Restore Bags"].."\n" ..
        L["   Simply hit empty bags, warehousing will remember what you had so that when you hit restore, it will grab all those items again. If you hit empty bags while your bags are empty it will overwrite the previous bag state, so you will not be able to use restore."].."\n"..
        "\n"..L["To create a Warehousing Group"]..":\n"..
        L["   1) Type a name in the textbox labeled \"Create New Group\", hit okay"].."\n" ..
        L["   1.1) You can delete a group by typing in its name and hitting okay."].."\n" ..
        L["   2) Select that group using the table on the left, you should then see a list of all the items currently in your bags with a quantity"].."\n"..
        L["   3) Right click to increase, left click to decrease by the current increment"].."\n"..
        "\n"..L["To move a Group:"].."\n"..
        L["   1) Open up a bank (either the gbank or personal bank)"].."\n"..
        L["   2) You should see a window on your right with a list of groups"].."\n"..
        L["   3) Select a group and hit either"].."\""..L["Move Group to Bank"].."\""..L["or"].."\""..L["Move Group to Bags"].."\"".."\n"
    
end

local function getHelpString3()
    return
       "\n"..L["Guild Bank"]..":\n"..
        L["   By default there is a four secound timeout when moving items from the guildbank.  This is nessary to "]..
        L["to ensure consistent results.  If you feel then need you can adjust this.  The timeout can be no less then"]..
        L["one secound and no greater then five.  Be warned I make no promises if you do decide to adjust this.  You have been warned."]
end

local function getHelpString4()
    return
       "\n"..L["Bank UI"]..":\n"..
        L["   You can toogle the Bank UI by typing the command "].."\\tsm bankui "
        
end


function GUI:Load(parent)


    local tabGroupTable={}
    local tabGroup = AceGUI:Create("TSMTabGroup")
    tabGroup:SetLayout("Fill")
    local select = 1

    table.insert(tabGroupTable, {text=L["Warehousing"], value=1} )
   -- table.insert(tabGroupTable, {text=L["Crafting"], value=2} )
   -- table.insert(tabGroupTable, {text=L["Auctioning"], value=3} )
    table.insert(tabGroupTable, {text=L["How To"], value=4} )
    
    tabGroup:SetTabs(tabGroupTable)

    tabGroup:SetCallback("OnGroupSelected", function(self, _, value)
        tabGroup:ReleaseChildren()
        TSM.scrollTable:HideTables()		
        if value == 1  then
            GUI:DrawUI(self)
            TSM.scrollTable:refresh(self)
        elseif value == 2  then
            GUI:DrawCrafting(self)
            TSM.craftingScrollTable:refresh(self)
        elseif value == 3  then
            GUI:DrawAuctioning(self)
        elseif value == 4  then
            GUI:DrawHelp(self)
        end
        parentcontainer = self		
    end)
    local simpleGroup = AceGUI:Create("TSMSimpleGroup")
    simpleGroup:SetLayout("Fill")
    
    parent:AddChild(simpleGroup)
    simpleGroup:AddChild(tabGroup)
    tabGroup:SelectTab(select)
    
   GUI:HookScript(simpleGroup.frame, "OnHide", function() 
        GUI:UnhookAll() 
        TSM.scrollTable:cleanup()
		TSM.scrollTable:HideTables() 
	end)
    
end

local tradeSkills = {
    {name="Enchanting", spellID=7411}, 
    {name="Inscription", spellID=45357},
    {name="Jewelcrafting", spellID=25229}, 
    {name="Alchemy", spellID=2259},
    {name="Blacksmithing", spellID=2018}, 
    {name="Leatherworking", spellID=2108},
    {name="Tailoring", spellID=3908}, 
    {name="Engineering", spellID=4036},
    {name="Cooking", spellID=2550}
}

function GUI:DrawUI(container)
    local page = 
    {
		{
			type = "SimpleGroup",
			layout = "Flow",
			children = 
			{
                {	--NewGroup TextBox
					type = "EditBox",
					relativeWidth = 0.25,
                    label = L["Create New Group"],
					callback = function(_,_,value) 
                        --TSM.db.factionrealm.WarehousingGroups = {}
                        table.insert(TSM.db.factionrealm.WarehousingGroups, {data={}, name = value})
                        TSM.scrollTable:refresh(container)
					end					
				}, 	--NewGroup TextBox
                {	--delete TextBox
					type = "EditBox",
					relativeWidth = 0.25,
                    label = L["Delete Group"],
					callback = function(_,_,value) 
                        --TSM.db.factionrealm.WarehousingGroups = {}
                        local _,index=TSM.bankui:getWarehouseTable(value)
                        table.remove(TSM.db.factionrealm.WarehousingGroups, index)
                        TSM.scrollTable:refresh(container)
					end					
				},
                {	--Increment TextBox
					type = "EditBox",
					relativeWidth = 0.25,
                    label = L["Set Increment"],
                    value = TSM.db.global.defaultIncrement,
					callback = function(_,_,value)
                        if tonumber(value) ~= nil then
                            TSM.db.global.defaultIncrement = value
                        end
					end					
				}
            }
        }
    }
    TSMAPI:BuildPage(container, page)
end

local current
local ddTable = {}

local function populateMenu()
    ddTable = {}
    for _,prof in ipairs(tradeSkills) do
        local total,_ = TSMAPI:GetData("shopping", prof.name)
        if total and #total > 0 then table.insert (ddTable, prof.name) end
    end
    return ddTable
end

function GUI:DrawHelp(container)
    local page = 
    {
		{
			type = "ScrollFrame",
			layout = "Flow",
			children = 
			{
                {	--NewGroup TextBox
					type = "Label",
					text = getHelpString1(),
					fontObject = GameFontNormalMedium,
					fullWidth = true,
                    relativeHeight = 1,
					
				}, 	--NewGroup TextBox
                
                {	--Prospecting DD
					type = "Dropdown",
					relativeWidth = 0.25,
					list = populateMenu(),
					value = current,
					callback =	function(this, event, item) current = item; end			
				}, 	-- End Prospecting DD
                
                {	--ClearButton
					type = "Button",
					text = L["Reset Crafting Queue"],
					relativeWidth = 0.25,
					callback = function() 
                         if (ddTable[current]) then
                             TSM.db.factionrealm.CraftingGroups[ddTable[current]] = nil
                             TSM:UpdatePlayerBagState()
                             TSM:Print(ddTable[current],"queue has been reset.")
                         end
					end					
				}, 	-- End ClearButton
                
                {	--NewGroup TextBox
                    type = "Label",
                    text = getHelpString2(),
                    fontObject = GameFontNormalMedium,
                    fullWidth = true,
                    relativeHeight = 1,

                }, --NewGroup TextBox
                {	--NewGroup TextBox
                    type = "Label",
                    text = getHelpString3(),
                    fontObject = GameFontNormalMedium,
                    fullWidth = true,
                    relativeHeight = 1,

                },
                {	--delete TextBox
                    type = "EditBox",
                    relativeWidth = 0.20,
                    label = L["Guild Bank Timeout"],
                    value = TSM.db.global.DefaultTimeOut,
                    callback = function(_,_,value) 
                        if tonumber(value) ~= nil and tonumber(value) <= 60 and tonumber(value) >=1 then 
                            TSM.db.global.DefaultTimeOut = value 
                        else
                            TSM:Print("Please select a timeout between 1 and 5")
                        end
                    end					
                },
                {	--NewGroup TextBox
                    type = "Label",
                    text = getHelpString4(),
                    fontObject = GameFontNormalMedium,
                    fullWidth = true,
                    relativeHeight = 1,

                },
                
            }--end childern
        }
    }
    TSMAPI:BuildPage(container, page)
end

local function getCraftingHelpString()
    return "You can use this to manage your Warehousing crafting queues."
end

function GUI:DrawCrafting(container)
    local page = 
    {
		{
			type = "ScrollFrame",
			layout = "Flow",
			children = 
			{
                {	--NewGroup TextBox
					type = "Label",
					text =  getCraftingHelpString(),
					fontObject = GameFontNormalMedium,
					fullWidth = true,
                    relativeHeight = .12,
					
				}, 	--NewGroup TextBox
                {	--Prospecting DD
					type = "Dropdown",
					relativeWidth = 0.25,
					list = populateMenu(),
					value = current,
					callback =	function(this, event, item) 
                        TSM.craftingScrollTable:updateST(ddTable[item])
                        current = item
                    end			
				}, 	-- End Prospecting DD
                
                {	--ClearButton
					type = "Button",
					text = L["Reset Crafting Queue"],
					relativeWidth = 0.25,
					callback = function() 
                         if (ddTable[current]) then
                             TSM.db.factionrealm.CraftingGroups[ddTable[current]] = nil
                             TSM:UpdatePlayerBagState()
                             TSM:Print(ddTable[current],"queue has been reset.")
                         end
                         TSM.craftingScrollTable:refresh(container)
					end					
				}, 	-- End ClearButton
               
            }--end childern
        }
    }
    TSMAPI:BuildPage(container, page)
end

function GUI:DrawAuctioning(container)
    local page = 
    {
		{
			type = "ScrollFrame",
			layout = "Flow",
			children = 
			{
                {	--NewGroup TextBox
					type = "Label",
					text =  "Under Construction",
					fontObject = GameFontNormalMedium,
					fullWidth = true,
                    relativeHeight = .12,
					
				}, 	--NewGroup TextBox
               
            }--end childern
        }
    }
    TSMAPI:BuildPage(container, page)
end