-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Warehousing - AddOn by Geemoney							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_warehousing.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Warehousing Locale - ruRU
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Warehousing/localization/


local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Warehousing", "ruRU")
if not L then return end
L["   1.1) You can delete a group by typing in its name and hitting okay."] = "  1.1) Можно удалить группу, введя её название и нажав ОК"
L["   1) Open up a bank (either the gbank or personal bank)"] = "  1) Открыть банк (гильдийский или личный)"
L["   1) Type a name in the textbox labeled \"Create New Group\", hit okay"] = "  1) Написать название в поле \"Создать новую группу\", нажать ОК"
L["   2) Select that group using the table on the left, you should then see a list of all the items currently in your bags with a quantity"] = "  2) Выбрать эту группу в таблице слева. После этого должен появиться список всех предметов в сумках и их количество."
L["   2) You should see a window on your right with a list of groups"] = "  2) Справа должно быть окно со списком групп."
L["   3) Right click to increase, left click to decrease by the current increment"] = "  3) Правый клик - увеличить, левый - уменьшить значение." -- Needs review
L["   3) Select a group and hit either"] = "   3) Выберите группу и нажмите ***" -- Needs review
-- L["   Again warehousing will try to fill out the order, but if it is short, it will remember how much it is short by and adjust its counts. So then you can go to another bank or another character and warehousing will grab the difference. Once the order has been completely filled out, warehousing will reset the count back to the original total. You cannot move a Crafting Queue bags->bank, only bank->bags."] = ""
L["Auctioning"] = "Auctioning"
L["Crafting"] = "Crafting"
L["Create New Group"] = "Создать новую группу"
L["Delete Group"] = "Удалить группу"
L["Empty Bags"] = "Очистить сумки"
L["Empty Bags/Restore Bags"] = "Очистить сумки/Восстановить сумки"
L["Group Behaviors"] = "Настройки группы"
L["Groups"] = "Группы"
L["How To"] = "Как"
L["Inventory Manager"] = "Inventory Manager"
L["Item"] = "Предмет"
L["Move Group to Bags"] = "Переместить группу в сумки"
L["Move Group To Bags"] = "Переместить группу в сумки"
L["Move Group to Bank"] = "Переместить группу в банк"
L["Move Group To Bank"] = "Переместить группу в банк"
L["New Group"] = "Новая группа"
L["or"] = "или"
L["Quantity"] = "Количество"
L["Reset Crafting Queue"] = "Очистить очередь крафта"
L["Restore Bags"] = "Восстановить сумки"
L["Set Increment"] = "Задать инкремент"
-- L["   Simply hit empty bags, warehousing will remember what you had so that when you hit restore, it will grab all those items again. If you hit empty bags while your bags are empty it will overwrite the previous bag state, so you will not be able to use restore."] = ""
L["To create a Warehousing Group"] = "Для создания группы Warehousing"
L["To move a Group:"] = "Для перемещения группы:"
L["TradeSkillMaster_InventoryManager"] = "TradeSkillMaster_InventoryManager"
L["Warehousing"] = "Warehousing"
-- L["Warehousing will only keep track of items that you have moved out of you bank and into your bags via the Inventory_Manager.  Finaly if you ever feel the need to reset the counts for a queue simply use the dropdown menu below."] = ""
-- L["   Warehousing will simply move all of each of the items in the group from the source to the destination."] = ""
-- L["   Warehousing will try to get the right number of items, if there are not enough in the bank to fill out order, it will grab all that there is."] = ""

