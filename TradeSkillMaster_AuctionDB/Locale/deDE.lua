-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_AuctionDB - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_auctiondb.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_AuctionDB Locale - deDE
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_AuctionDB/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_AuctionDB", "deDE")
if not L then return end

L["A full auction house scan will scan every item on the auction house but is far slower than a GetAll scan. Expect this scan to take several minutes or longer."] = "Ein voller Auktionshausscan wird jedes einzelne Item im Auktionshaus scannen, ist aber sehr viel langsamer als der GetAll-Scan. Erwarte, dass es mehrere Minuten dauert oder länger."
L["A GetAll scan is the fastest in-game method for scanning every item on the auction house. However, it may disconnect you from the game and has a 15 minute cooldown."] = "Ein GetAll-Scan ist die schnellste In-Game-Methode um jedes Item im Auktionshaus zu scannen. Es kann passieren, dass du vom Spiel ausgeloggt wirst und es hat eine Abklingzeit von 15 Minuten."
L["Alchemy"] = "Alchemie"
L["Any items in the AuctionDB database that contain the search phrase in their names will be displayed."] = "Es werden alle Gegenstände in der \"AuctionDB\" Datenbank angezeigt, deren Namen mit der Sucheingabe übereinstimmen."
L["A profession scan will scan items required/made by a certain profession."] = "Ein Beruf-Scan wird jedes Item, was bei dem Beruf benötigt/gemacht wird, scannen."
L["Are you sure you want to clear your AuctionDB data?"] = "Sind Sie sicher, dass Sie die \"AuctionDB\" Daten löschen wollen?"
L["Ascending"] = "Aufsteigend"
L["AuctionDB - Market Value"] = "AuctionDB - Marktwert"
L["AuctionDB Market Value:"] = "AuctionDB Markwert:"
L["AuctionDB Min Buyout:"] = "AuctionDB Min. Sofortkauf:"
L["AuctionDB - Minimum Buyout"] = "AuctionDB - Mindestpreis"
L["AuctionDB Seen Count:"] = "AuctionDB Anzahl gesehen:"
L["Blacksmithing"] = "Schmiedekunst"
L["|cffff0000WARNING:|r As of 4.0.1 there is a bug with GetAll scans only scanning a maximum of 42554 auctions from the AH which is less than your auction house currently contains. As a result, thousands of items may have been missed. Please use regular scans until blizzard fixes this bug."] = "|cffff0000WARNUNG:|r Seit 4.0.1 existiert ein Bug mit Komplettscans, da nur maximal 42554 Auktionen eingelesen werden können. Da das Auktionshaus momentan mehr Auktionen hat, könnten dadurch tausende Items übersehen werden. Bitte nutze normale Scans bis Blizzard diesen Bug fixed."
L["Cooking"] = "Kochen"
L["Descending"] = "Absteigend"
L["Done Scanning"] = "Scannen beendet"
L["Enable display of AuctionDB data in tooltip."] = "Aktiviere die Anzeige der AuctionDB-Daten im Tooltip."
L["Enchanting"] = "Verzauberkunst"
L["Engineering"] = "Ingenieurskunst"
L["General Options"] = "Allgemeine Optionen"
L["Hide poor quality items"] = "Verstecke Gegenstände schlechter Qualität"
L["If checked, poor quality items won't be shown in the search results."] = "Wenn markiert, tauchen Gegenstände schlechter Qualität nicht in den Suchergebnissen auf."
L["Inscription"] = "Inschriftenkunde"
L["Invalid value entered. You must enter a number between 5 and 500 inclusive."] = "Eingebener Wert ist ungültig. Sie müssen eine Zahl zwischen 5 und 500 eingeben."
L["Item Link"] = "Gegenstands-Link"
L["Item MinLevel"] = "Gegenstand MinLevel"
L["Items per page"] = "Gegenstände pro Seite"
L["Items %s - %s (%s total)"] = "Gegenstände %s - %s (%s gesamt)"
L["Item SubType Filter"] = "Gegenstands-Unterkategorie-Filter"
L["Item Type Filter"] = "Gegenstands-Kategorie-Filter"
L["It is strongly recommended that you reload your ui (type '/reload') after running a GetAll scan. Otherwise, any other scans (Post/Cancel/Search/etc) will be much slower than normal."] = "Es wird sehr empfohlen, dass du die UI neu lädst (tippe \"/reload\"), nachdem du einen GetAll-Scan gemacht hast. Sonst werden andere Scans (Posten/Abbrechen/Suchen/etc) sehr viel langsamer als Normal laufen." -- Needs review
L["Jewelcrafting"] = "Juwelenschleifen"
L["Last Scanned"] = "Zuletzt gescannt"
L["Leatherworking"] = "Lederverarbeitung"
L["Market Value"] = "Marktwert"
L["Minimum Buyout"] = "Minimaler Sofortkaufpreis"
L["Never scan the auction house again!"] = "Scanne das Auktionshaus nie wieder!"
L["Next Page"] = "Nächste Seite"
L["No items found"] = "Keine Gegenstände gefunden"
L["Not Ready"] = "Nicht bereit"
L["Num(Yours)"] = "Num(Deine)"
L["Options"] = "Optionen"
L["Previous Page"] = "Vorherige Seite"
L["Professions:"] = "Berufe:"
L["Ready"] = "Bereit"
L["Ready in %s min and %s sec"] = "Bereit in %s Minuten und %s Sekunden"
L["Refresh"] = "Aktualisieren"
L["Refreshes the current search results."] = "Aktualisiert die derzeitigen Suchergebnisse."
L["Removed %s from AuctionDB."] = "%s von AuctionDB entfernt."
L["Reset Data"] = "Daten zurücksetzen"
L["Resets AuctionDB's scan data"] = "Setzt die Scandaten der \"AuctionDB\" zurück"
L["Run Full Scan"] = "Starte einen vollen Scan"
L["Run GetAll Scan"] = "Starte Komplettscan"
L["Run Profession Scan"] = "Starte ein Berufe-Scan"
L["Run Scan"] = "Starte scan"
L["%s ago"] = "Vor %s"
L["Scan interrupted."] = "Scannen unterbrochen"
L["Scanning..."] = "Scannen..."
L["Scan the auction house with AuctionDB to update its market value and min buyout data."] = "Scanne das Auktionshaus mit AuctionDB um die Marktwerte und Mindesverkaufspreise zu aktualisieren."
L["Search"] = "Suche"
L["Search Options"] = "Suchoptionen"
L["Select how you would like the search results to be sorted. After changing this option, you may need to refresh your search results by hitting the \"Refresh\" button."] = "Wählen Sie aus, wie die Suchergebnisse sortiert werden sollen. Nach Ändern der Option kann es notwendig sein Ihre Suchergebnisse zu aktualisieren, indem Sie den \"Aktualisieren\"-Button drücken."
L["Select professions to include in the profession scan."] = "Wähle Berufe aus, die im Berufe-Scan benutzt werden."
L["Shift-Right-Click to clear all data for this item from AuctionDB."] = "Shift-Rechtsklick um alle Daten für das Item aus AuctionDB zu löschen."
L["Sort items by"] = "Sortiere Gegenstände nach"
L["Sort search results in ascending order."] = "Sortiere Suchergebnisse in aufsteigender Reihenfolge."
L["Sort search results in descending order."] = "Sortiere Suchergebnisse in absteigender Reihenfolge."
L["%s - Scanning page %s/%s of filter %s/%s"] = "%s - Gescannte Seite %s/%s von Filter %s/%s"
L["Tailoring"] = "Schneiderei"
L["The author of TradeSkillMaster has created an application which uses blizzard's online auction house APIs to update your AuctionDB data automatically. Check it out at the link in TSM_AuctionDB's description on curse or at: %s"] = "Der Autor von TradeSkillMaster hat eine Anwendung erstellt, welche Blizzards Auktionshaus API benutzt, um deine AuctionDB Daten automatisch zu aktualisieren. Guck es dir via dem Link in der Beschreibung von TSM_AuctionDB bei Curse an oder auf: %s"
L["This determines how many items are shown per page in results area of the \"Search\" tab of the AuctionDB page in the main TSM window. You may enter a number between 5 and 500 inclusive. If the page lags, you may want to decrease this number."] = "Dies bestimmt wieviele Gegenstände pro Seite im Ergebnisbereich des \"Suche\"-Reiters der \"AuctionDB\" im TSM Hauptfenster angezeigt werden. Sie können eine Zahl zwischen 5 und 500 eingeben. Wenn die Seite Verzögerungen verursacht, wäre es ratsam die Anzahl zu reduzieren."
L["Use the search box and category filters above to search the AuctionDB data."] = "Benutzen Sie die Sucheingabe und Kategorie-Filter oben um die \"AuctionDB\"-Daten zu durchsuchen."
L["Waiting for data..."] = "Warte auf Daten..."
L["You can filter the results by item subtype by using this dropdown. For example, if you want to search for all herbs, you would select \"Trade Goods\" in the item type dropdown and \"Herbs\" in this dropdown."] = "Sie können die Ergebnisse eingrenzen, indem Sie eine Gegenstands-Unterkategorie aus der Auswahlliste wählen. Wenn Sie zum Beispiel nach allen Kräutern suchen wollen, würden Sie \"Handwerkswaren\" als Gegenstands-Kategorie wählen und \"Kräuter\" in dieser Auswahlliste."
L["You can filter the results by item type by using this dropdown. For example, if you want to search for all herbs, you would select \"Trade Goods\" in this dropdown and \"Herbs\" as the subtype filter."] = "Sie können die Ergebnisse eingrenzen, indem Sie eine Gegenstands-Kategorie aus der Auswahlliste wählen. Wenn Sie zum Beispiel nach allen Kräutern suchen wollen, würden Sie \"Handwerkswaren\" in dieser Auswahlliste wählen und \"Kräuter\" in der Auswahlliste für die Gegenstands-Unterkategorie."
L["You can use this page to lookup an item or group of items in the AuctionDB database. Note that this does not perform a live search of the AH."] = "Diese Seite können Sie benutzen um Gegenstände oder Gegenstandsgruppe in der \"AuctionDB\"-Datenbank nachzuschlagen. Beachten Sie, dass dies keine Echtzeitsuche für das AH ist."
 