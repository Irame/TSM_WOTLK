-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Warehousing - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_warehousing.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Warehousing Locale - deDE
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Warehousing/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Warehousing", "deDE")
if not L then return end

L["   1.1) You can delete a group by typing in its name and hitting okay."] = "1.1) Du kannst eine Gruppe löschen, indem Du deren Name eingibst und auf okay klickst."
L["   1) Open up a bank (either the gbank or personal bank)"] = "1) Öffne eine Bank (entweder Gildenbank oder eigene Bank)"
L["   1) Type a name in the textbox labeled \"Create New Group\", hit okay"] = "1) Gib einen Namen in dem Textfeld mit der Bezeichnung \"Neue Gruppe erstellen\" ein und klicke auf okay"
L["   2) Select that group using the table on the left, you should then see a list of all the items currently in your bags with a quantity"] = "2) Wähle diese Gruppe mittels der linken Tabelle aus. Damit werden alle Gegenstände in Deinen Taschen mit Mengenangabe angezeigt."
L["   2) You should see a window on your right with a list of groups"] = "2) Auf der rechten Seite solltest Du ein Fenster haben, in dem Gruppen aufgelistet sind"
L["   3) Right click to increase, left click to decrease by the current increment"] = "3) Mit Rechtsklick erhöhst, und mit einem Linksklick veringerst Du den Wert um das angegebene Inkrement"
L["   3) Select a group and hit either"] = "3) Wähle eine Gruppe aus und klicke entweder"
L["   Again warehousing will try to fill out the order, but if it is short, it will remember how much it is short by and adjust its counts. So then you can go to another bank or another character and warehousing will grab the difference. Once the order has been completely filled out, warehousing will reset the count back to the original total. You cannot move a Crafting Queue bags->bank, only bank->bags."] = "Wie gesagt versucht die Lagerung die Gegenstände für Warteschlange zu bekommen. Wenn die Menge nicht ausreicht, merkt es sich die Differenz und passt die Zahlen an. Damit kannst Du eine andere Bank sogar von einem anderen Charakter öffnen und die Differenz aufnehmen. Wenn einmal die komplette Menge entnommen wurde, setzt die Lagerung die Mengen auf die ursprüngliche Menge zurück. Eine Handwerkswarteschlange kann nicht von den Taschen in die Bank verschoben werden, nur von der Bank in die Taschen."
L["Auctioning"] = "Auktionshandel"
L["Crafting"] = "Herstellen"
L["Create New Group"] = "Neue Gruppe erstellen"
L["Delete Group"] = "Gruppe löschen"
L["Empty Bags"] = "Taschen leeren"
L["Empty Bags/Restore Bags"] = "Taschen leeren/Taschen wiederherstellen"
L["Group Behaviors"] = "Verhalten der Gruppe"
L["Groups"] = "Gruppen"
L["How To"] = "HowTo"
L["Inventory Manager"] = "Inventar Manager"
L["Item"] = "Gegenstand"
L["Move Group to Bags"] = "Gruppe in Taschen verschieben"
L["Move Group To Bags"] = "Gruppe in Taschen verschieben"
L["Move Group to Bank"] = "Gruppe in die Bank verschieben"
L["Move Group To Bank"] = "Gruppe in die Bank verschieben"
L["New Group"] = "Neue Gruppe"
L["or"] = "oder"
L["Quantity"] = "Menge"
L["Reset Crafting Queue"] = "Handwerkswarteschlange zurücksetzen"
L["Restore Bags"] = "Taschen wiederherstellen"
L["Set Increment"] = "Inkrement festlegen"
L["   Simply hit empty bags, warehousing will remember what you had so that when you hit restore, it will grab all those items again. If you hit empty bags while your bags are empty it will overwrite the previous bag state, so you will not be able to use restore."] = "Klicke einfach auf \"Taschen leeren\". Lagerung merkt sich, was Du im Inventar hattest. Dadurch werden alle Gegenstände wieder hergestellt, wenn Du auf \"Wiederherstellen\" klickst. Wenn Du auf \"Taschen leeren\" klickst, während Deine Taschen leer waren, dann wird der vorherige Taschenstatus überschrieben, wodurch Du \"Wiederherstellen\" nicht mehr nutzen kannst."
L["To create a Warehousing Group"] = "Um eine Lager-Gruppe zu erstellen"
L["To move a Group:"] = "Um eine Gruppe zu verschieben:"
L["TradeSkillMaster_InventoryManager"] = "TradeSkillMaster_Inventar Manager"
L["Warehousing"] = "Lagerung"
L["Warehousing will only keep track of items that you have moved out of you bank and into your bags via the Inventory_Manager.  Finaly if you ever feel the need to reset the counts for a queue simply use the dropdown menu below."] = "Warehousing verfolgt nur solche Gegenstände, die mittels Inventar Manager von der Bank in Deine Taschen verschoben wurden. Solltest Du jemals die Zählmengen zurücksetzen wollen, kannst Du einfach das nachstehende Dropdown-Menü verwenden."
L["   Warehousing will simply move all of each of the items in the group from the source to the destination."] = "Lagerung schiebt einfach alle Gegenstände der Gruppe von der Quelle zum Ziel."
L["   Warehousing will try to get the right number of items, if there are not enough in the bank to fill out order, it will grab all that there is."] = "Lagerung versucht die korrekte Anzahl an Gegenständen zu entnehmen. Wenn in der Bank nicht genügend Gegenstände vorhanden sind, werden alle verfügbaren Gegenstände entnommen."
