-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Accounting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_Accounting.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Accounting Locale - deDE
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Accounting/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Accounting", "deDE")
if not L then return end

L["Accounting"] = "Buchhaltung"
L["Activity Log"] = "Aktivitätshistorie"
L["Activity Type"] = "Art der Aktivität"
L["Auctions"] = "Auktionen"
L["Average Prices:"] = "Durchschnittliche Preise:"
L["Avg Buy Price"] = "Durchschn. Kaufpreis"
L["Avg Resale Profit"] = "Durchschn. Wiederverkaufsgewinn"
L["Avg Sell Price"] = "Durchschn. Kaufpreis"
L["Back to Previous Page"] = "Zurück zur vorherigen Seite"
L["Bought"] = "Gekauft"
L["Buyer/Seller"] = "Käufer/Verkäufer"
L["Clear Old Data"] = "Lösche alte Daten"
L["Click for a detailed report on this item."] = "Klicken für einen detaillierten Bericht zum Gegenstand."
L["Click this button to permanently remove data older than the number of days selected in the dropdown."] = "Clicke diesen Button um Daten die älter sind wie im Dropdown Menü in Tagen gewählt, permanent zu löschen"
L["Common Quality Items"] = "Gegenstände gewöhnlicher Qualität"
L["Data older than this many days will be deleted when you click on the button to the right."] = "Daten die älter sind wie diese vielen Tage werden gelöscht wenn du den Button auf der rechten Seite klickst"
L["Days:"] = "Tage:"
L["DD/MM/YY HH:MM"] = "TT/MM/JJ SS:MM"
L["Earned Per Day:"] = "Eingenommen pro Tag:"
L["Epic Quality Items"] = "Gegenstände epischer Qualität"
L["General Options"] = "Einstellungen"
L["Gold Earned:"] = "Gold eingenommen:"
L["Gold Spent:"] = "Gold ausgegeben:"
L["_ Hr _ Min ago"] = "vor _ St _ Min"
L["If checked, the average purchase price that shows in the tooltip will be the average price for the most recent X you have purchased, where X is the number you have in your bags / bank / gbank using data from the ItemTracker module. Otherwise, a simple average of all purchases will be used."] = "Wenn aktiviert, wird der durchschnittliche Kaufpreis, der in den Tooltips angezeigt wird, der durchschnittliche Preis für die letzen X die du erworben hast sein. Wobei X für die Anzahl der items steht, die du in deinen Taschen / Bank / gbank laut Daten des ItemTracker Moduls hast. Andernfalls wird ein einfacher Durchschnitt aller Käufe genutzt werden. "
L["If checked, the number you have purchased and the average purchase price will show up in an item's tooltip."] = "Zeige Anzahl gekaufter Gegenstände und durchschnittlichen Kaufpreis im Tooltip des Gegenstands."
L["If checked, the number you have sold and the average sale price will show up in an item's tooltip."] = "Zeige Anzahl verkaufter Gegenstände und durchschnittlichen Verkaufspreis im Tooltip des Gegenstands."
L["Item Name"] = "Gegenstandsname"
L["Items"] = "Gegenstände"
L["Items in an Auctioning Group"] = "Gegenstände, die in einer Auktionsgruppe sind"
L["Items NOT in an Auctioning Group"] = "Gegenstände, die NICHT in einer Auktionsgruppe sind"
L["Items/Resale Price Format"] = "Item/Verkauf Preis Format"
L["Last 30 Days:"] = "Letzte 30 Tage:"
L["Last 7 Days:"] = "Letzte 7 Tage:"
L["Last Purchase"] = "Letzter Kauf"
L["Last Sold"] = "Letzter Verkauf"
L["Market Value"] = "Martkwert"
L["Market Value Source"] = "Quelle des Marktwertes"
L["MM/DD/YY HH:MM"] = "MM/TT/JJ SS:MM"
L["MySales Import Complete! Imported %s sales. Was unable to import %s sales."] = "MySales Import komplett! Importiert %s Verkäufe. Fehler beim Import von %s Verkäufen"
L["MySales Import Progress"] = "MySales Import Fortschritt"
L["MySales is currently disabled. Would you like Accounting to enable it and reload your UI so it can transfer settings?"] = "MySales ist deaktiviert. Willst du das Accounting es aktiviert und die UI neu lädt, sodass die Einstellungen transferiert werden?"
L["none"] = "nichts"
L["Options"] = "Optionen"
L["Price Per Item"] = "Preis pro Gegenstand"
L["Purchase"] = "Kauf"
L["Purchase Data"] = "Kauf Daten"
L["Purchased (Avg Price): %s (%s)"] = "Gekauft (Durschn. Preis): %s (%s)"
L["Purchased (Smart Avg): %s (%s)"] = "Gekauft (Kluges Avg): %s (%s)"
L["Purchases"] = "Käufe"
L["Quantity"] = "Anzahl"
L["Quantity Bought:"] = "Anzahl gekaufter:"
L["Quantity Sold:"] = "Anzahl verkaufter:"
L["Rare Quality Items"] = "Gegenstände rarer Qualität"
L["Removed a total of %s old records and %s items with no remaining records."] = "%s alte Daten entfernt und %s Items ohne Aufzeichnungen."
L["Remove Old Data (No Confirmation)"] = "Alte Daten entfernen (keine Bestätigung)"
L["Resale"] = "Wiederverkauf"
L["%s ago"] = "vor %s"
L["Sale"] = "Verkauf"
L["Sale Data"] = "Verkaufsdaten"
L["Sales"] = "Verkäufe"
L["Search"] = "Suche"
L["Select how you would like prices to be shown in the \"Items\" and \"Resale\" tabs; either average price per item or total value."] = "Wähle aus wie die Preise in den \"Items\"- und \"Wiederverkauf\"tabs angezeigt werden; entweder nach Durchschnittspreis oder totaler Preis"
L["Select what format Accounting should use to display times in applicable screens."] = "Wähle aus, welches Format Accounting benutzen soll, um Zeiten in den Fenstern anzuzeigen."
L["Select where you want Accounting to get market value info from to show in applicable screens."] = "Wähle aus wo Accounting die Marktwertinformationen herbekommen soll, um die in den Fenstern anzuzeigen."
L["Show purchase info in item tooltips"] = "Zeige Kaufinformationen im Tooltip der Gegenstände"
L["Show sale info in item tooltips"] = "Zeige Verkaufsinformationen im Tooltip der Gegenstände"
L["Sold"] = "Verkauft"
L["Sold (Avg Price): %s (%s)"] = "Verkauft (Durchschn. Preis): %s (%s)"
L["Special Filters"] = "Spezielle Filter"
L["Spent Per Day:"] = "Ausgegeben pro Tag:"
L["Stack Size"] = "Stapelgröße"
L["Starting to import MySales data. This requires building a large cache of item names which will take about 20-30 seconds. Please be patient."] = "Starte den Import von MySales Daten. Cache wird erstellt, dieses kann 20-30 Sekunden dauern. Bitte habe Geduld"
L["Summary"] = "Zusammenfassung"
L["There is no purchase data for this item."] = "Keine Kaufstatistik für diesen Gegenstand vorhanden."
L["There is no sale data for this item."] = "Keine Verkaufsstatistik für diesen Gegenstand vorhanden."
L["Time"] = "Zeit"
L["Time Format"] = "Zeitformat"
L["Tooltip Options"] = "Tooltip Einstellungen"
L["Top Buyers:"] = "Beste Käufer:"
L["Top Item by Gold:"] = "Bester Gegentand nach Gold:"
L["Top Item by Quantity:"] = "Bester Gegenstand nach Anzahl:"
L["Top Sellers:"] = "Beste Verkäufer:"
L["Total:"] = "Gesamt:"
L["Total Buy Price"] = "Gesamtkaufpreis"
L["Total Price"] = "Gesamtpreis"
L["Total Sale Price"] = "Gesamtverkaufpreis"
L["Total Spent:"] = "Insgesamt ausgegeben:"
L["Total Value"] = "Gesamtwert"
L["TradeSkillMaster_Accounting has detected that you have MySales installed. Would you like to transfer your data over to Accounting?"] = "TradeSkillMaster_Accounting hat fest gestellt das sie MySales installiert haben. Möchten sie die Daten nach Accounting übertragen?"
L["Uncommon Quality Items"] = "Gegenstände seltener Qualität"
L["Use smart average for purchase price"] = "Benutze intelligenten Durchschnitt für Kaufpreis"
L[ [=[You can use the options below to clear old data. It is recommened to occasionally clear your old data to keep Accounting running smoothly. Select the minimum number of days old to be removed in the dropdown, then click the button.

NOTE: There is no confirmation.]=] ] = [=[Du kannst die Optionen unten nutzen um alte Daten zu löschen. Es wird vorgeschlagen deine alten Daten regelmäßig zu löschen um Accounting besser laufen zu lassen. Wähle ein Minimum in Tagen im Dropdown Menü, in welchen Daten gelöscht werden soll.

NOTIZ: Es gibt keine Bestätigung.]=]
L["YY/MM/DD HH:MM"] = "JJ/MM/TT SS:MM"
 