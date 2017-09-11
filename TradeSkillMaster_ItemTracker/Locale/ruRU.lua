-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_ItemTracker.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_ItemTracker Locale - ruRU
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_ItemTracker/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_ItemTracker", "ruRU")
if not L then return end

L["Delete Character:"] = "Удалить персонажа:"
L["Full"] = "Полный"
L["Here, you can choose what ItemTracker info, if any, to show in tooltips. \"Simple\" will show only show totals for bags/banks and for guild banks. \"Full\" will show detailed information for every character and guild."] = "Настройка отображение данных модуля itemTracker в подсказках. \"Простой\" - показывается только общее количество предметов в сумках/банках и в банках гильдий. \"Полный\" - показывается детальная информация для каждого персонажа и гильдии."
L["If you previously used TSM_Gathering, note that inventory data was not transfered to TSM_ItemTracker and will not show up until you log onto each character and visit the bank / gbank / auction house."] = "Если вы до этого пользовались модулем TSM_Gathering, обратите внимание, что данные инвентаря не были перенесены в TSM_ItemTracker и не будут отображаться до тех пор, пока вы не зайдёте в игру каждым персонажем и не посетите банк / банк гильдии / аукционный дом." -- Needs review
L["If you rename / transfer / delete one of your characters, use this dropdown to remove that character from ItemTracker. There is no confirmation. If you accidentally delete a character that still exists, simply log onto that character to re-add it to ItemTracker."] = "Без подтверждения! Если вы переименуете / перенесёте / удалите одного из ваших персонажей, используйте этот список для удаления данного персонажа из модуля ItemTracker. Если вы случайно удалили персонажа, то просто зайдите этим персонажем в игру для добавления его в модуль." -- Needs review
L["ItemTracker: %s on player, %s on alts, %s in guild banks, %s on AH"] = "ItemTracker: %s у игрока, %s у альтов, %s в банках гильдий, %s на ауке"
L["No Tooltip Info"] = "Без подсказок"
L["Options"] = "Настройки"
L["Simple"] = "Простой"
L["\"%s\" removed from ItemTracker."] = "\"%s\" удалено из ItemTracker."
L["%s: %s in guild bank"] = "%s: %s в банке гильдии"
L["%s: %s (%s in bags, %s in bank, %s on AH)"] = "%s: %s (%s в сумках, %s в банке, %s на ауке)"
-- L["trackerMessage"] = ""
