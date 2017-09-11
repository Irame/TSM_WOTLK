-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_ItemTracker.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_ItemTracker Locale - deDE
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_ItemTracker/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_ItemTracker", "deDE")
if not L then return end

L["Delete Character:"] = "Lösche Charakter:"
L["Full"] = "Voll"
L["Here, you can choose what ItemTracker info, if any, to show in tooltips. \"Simple\" will show only show totals for bags/banks and for guild banks. \"Full\" will show detailed information for every character and guild."] = [=[Hier kannst du auswählen, welche Info's ItemTracker, sofern sie existieren, in den Tooltips zeigt. "Einfach" zeigt nut die Gesamtzahl in Taschen/Banken und für die Gildenbank. "Voll" zeigt detallierte Informationen für jeden Charakter und Gilde.
]=]
L["If you previously used TSM_Gathering, note that inventory data was not transfered to TSM_ItemTracker and will not show up until you log onto each character and visit the bank / gbank / auction house."] = "Wenn du vorher TSM_Gathering verwendet hast, beachte, dass die Inventardaten nicht zu TSM_ItemTracker importiert wurden und nicht auftauchen werden, bis du dich auf jedem Charakter angemeldet hast und die Bank / Gildenbank / Auktionshaus besucht hast."
L["If you rename / transfer / delete one of your characters, use this dropdown to remove that character from ItemTracker. There is no confirmation. If you accidentally delete a character that still exists, simply log onto that character to re-add it to ItemTracker."] = "Wenn du ein deiner Charakter umbenennst / transferierst / löschst, nutze das Dropdownmenü um den Charakter aus ItemTracker zu löschen. Es gibt keine Bestätigung. Wenn du aus Versehen einen Charakter löschst der noch existiert, logge dich einfach auf den Charakter ein um in wieder zu ItemTracker hinzuzufügen. "
L["ItemTracker: %s on player, %s on alts, %s in guild banks, %s on AH"] = "ItemTracker: %s beim Spieler, %s auf alts, %s in der Gilden Bank, %s im AH"
L["No Tooltip Info"] = "Keine Tooltip Info"
L["Options"] = "Optionen"
L["Simple"] = "Einfach"
L["\"%s\" removed from ItemTracker."] = "\"%s\" aus ItemTracker entfernt."
L["%s: %s in guild bank"] = "%s: %s in der Gilden Bank"
L["%s: %s (%s in bags, %s in bank, %s on AH)"] = "%s: %s (%s in Tachen, %s in der Bank, %s im AH)"
L["trackerMessage"] = "trackerNachricht"
