-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Shopping - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_shopping.aspx    --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Shopping Locale - deDE
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Shopping/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Shopping", "deDE")
if not L then return end

L["12 hours"] = "12 Stunden"
L["24 hours"] = "24 Stunden" -- Needs review
L["48 hours"] = "48 Sunden"
L["Accept"] = "Akzeptieren"
L["Add Item"] = "Füge Gegenstand hinzu"
L["Add Item / Search Term"] = "Füge Item hinzu / Suche Begriff"
L["Add item to dealfinding list"] = "Zur Angebotssuche hinzufügen" -- Needs review
L["Add Item to Dealfinding List"] = "Zur Angebotssuche hinzufügen" -- Needs review
L["Add Item to New List"] = "Zur Liste hinzufügen" -- Needs review
L["Add Item to Selected List"] = "Zur ausgewählten Liste hinzufügen" -- Needs review
L["Add item to shopping list"] = "Zur Einkaufsliste hinzufügen" -- Needs review
L["Add Item to Shopping List"] = "Zur Einkaufsliste hinzufügen" -- Needs review
L["Additional Options:"] = "Zusätzliche Optionen" -- Needs review
L["Add Search Term"] = "Suchausdruck hinzufügen" -- Needs review
L["Are you sure you want to delete the selected profile?"] = "Sind sie sicher, dass sie das ausgewählte Profil löschen möchten?"
L["Auction Buyout:"] = "Sofortkauf" -- Needs review
L["Auction Buyout (Stack Price):"] = "Sofortkauf (Preis/Stapel)" -- Needs review
L["Auction Duration"] = "Auktionsdauer" -- Needs review
L["Auction Item Price"] = "Auktions Einzelpreis" -- Needs review
L["Auction not found. Restarting search."] = "Keine Auktion gefunden. Starte Suche neu." -- Needs review
L["Auctions"] = "Auktionen" -- Needs review
L["Auction Stack Price"] = "Auktions Stapel-Preis" -- Needs review
L["Automatically Expand Single Result"] = "Einzelnes Ergebnis automatisch erweitern" -- Needs review
L["Below are some general options for the Shopping module."] = "Unten finden sich allgemeine Einstellungen für das Shopping Modul." -- Needs review
-- L["Bid Percent"] = ""
L["Cancel"] = "Abbrechen"
L["Canceling"] = "Annullierend" -- Needs review
L["Cannot change current item while scanning."] = "Aktueller Gegenstand während des Scans nicht änderbar." -- Needs review
L["Cannot create auction with 0 buyout."] = "Auktion kann nicht mit 0 Sofortkauf erstellt werden." -- Needs review
-- L["|cff99ffffRecent Searches"] = ""
--[==[ L[ [=[|cffffbb11No dealfinding or shopping lists found. You can create shopping/dealfinding lists through the TSM_Shopping options.

TIP: You can search for multiple items at a time by separating them with a semicolon. For example: "volatile life; volatile earth; volatile water"|r]=] ] = "" ]==]
--[==[ L[ [=[|cffffff00Inline Filters:|r You can easily add common search filters to your search such as rarity, level, and item type. For example '|cff99ffffarmor/leather/epic/85/i350/i377|r' will search for all leather armor of epic quality that requires level 85 and has an ilvl between 350 and 377 inclusive. Also, '|cff99ffffinferno ruby/exact|r' will display only raw inferno rubys (none of the cuts).
]=] ] = "" ]==]
--[==[ L[ [=[|cffffff00Multiple Search Terms:|r You can search for multiple things at once by simply separated them with a ';'. For example '|cff99ffffelementium ore; obsidium ore|r' will search for both elementium and obsidium ore.
]=] ] = "" ]==]
L["Click on this icon to enter disenchanting mode."] = "Klicke Icon um Entzauberungs-Modus zu aktivieren." -- Needs review
L["Click on this icon to enter milling mode."] = "Klicke Icon um Mahlen-Modus zu aktivieren." -- Needs review
L["Click on this icon to enter prospecting mode."] = "Klicke Icon um Sondierungs-Modus zu aktivieren." -- Needs review
-- L["Click on this icon to enter transformation mode."] = ""
L["Click to shop for this item."] = "Klicke um diesen Gegenstand einzukaufen." -- Needs review
L["Copy From"] = "Kopieren von"
L["Copy the settings from one existing profile into the currently active profile."] = "Kopiere die Einstellungen von einem anderen Profil in das derzeit aktive Profil."
L["Crafting Cost:"] = "Herstellungskosten:" -- Needs review
L["Crafting Mats"] = "Herstellungsmaterial" -- Needs review
L["Create a new empty profile."] = "Erstelle neues leeres Profil."
L["Current Profile:"] = "Aktuelles Profil:"
L["Data Imported to Group: %s"] = "Daten in Gruppe importieren: \"%s\"" -- Needs review
L["Dealfinding list deleted: \"%s\""] = "Angebotssuche gelöscht: \"%s\"" -- Needs review
L["Dealfinding List Name"] = "Name der Angebotssuche" -- Needs review
L["Dealfinding Lists"] = "Angebotssuche Listen" -- Needs review
L["Dealfinding Search"] = "Angebote suchen" -- Needs review
L["Default"] = "Standard"
L["Default Undercut"] = "Unterbieten (Standard)" -- Needs review
L["Delete a Profile"] = "Lösche ein Profil"
L["Delete existing and unused profiles from the database to save space, and cleanup the SavedVariables file."] = "Lösche unbenutzte Profile aus der Datenbank um Speicherplatz zu sparen, und säubere die SavedVariables Datei."
L["Delete / Export List"] = "Lösche / Exportiere Liste" -- Needs review
L["Delete List"] = "Lösche Liste" -- Needs review
-- L["Destroying Modes to Use:"] = ""
-- L["Destroying Results Default Sort (requires reload)"] = ""
L["Determines what percent of the buyout price Shopping will use for the starting bid when posting auctions."] = "Bestimmt die Höhe des Startgebots in Prozent des Sofortkaufpreises wenn Auktionen erstellt werden." -- Needs review
L["Did not add search term \"%s\". Already in this list."] = "Suchbegriff \"%s\" nicht hinzugefügt. Bereits in der Liste." -- Needs review
L["Disenchanting"] = "Entzaubern"
L["Enter the search term you would list to add below. You can add multiple search terms at once by separating them with semi-colons. For example, \"elementium ore; volatile\""] = "Unten den zur Liste hinzuzufügenden Suchbegriff eingeben. Du kannst mehrere, durch Semikolon getrennte, Suchbegriffe gleichzeitig eingeben. Z.B.: \"Elementiumerz; flüchtige\"" -- Needs review
L[ [=[Enter what you want to search for in this box. You can also use the following options for more complicated searches.
]=] ] = [=[Du kannst in dieser Box eingeben was du suchen möchtest. Du kannst die folgenden Optionen für eine erweiterte Suche nutzen.
]=] -- Needs review
L["Even Stacks Only"] = "Nur passende Stapel"
-- L["Even Stacks Only (Ore/Herbs)"] = ""
-- L["Even Stacks (Ore/Herbs)"] = ""
L["Existing Profiles"] = "Vorhandene Profile"
L["% Expected Cost"] = "% Erwartete Kosten"
L["Export List"] = "Liste exportieren" -- Needs review
-- L["Fallback Price Percent"] = ""
-- L["Fallback Price Source"] = ""
L["General Options"] = "Allgemeine Einstellungen"
-- L["Here you can add an item or a search term to this shopping list."] = ""
-- L["Here you can add an item to this dealfinding list."] = ""
-- L["Here you can choose in which situations Shopping should run a destroying search rather than a regular search for the target item."] = ""
-- L["Here, you can remove items from this list."] = ""
-- L["Here, you can remove search terms from this list."] = ""
-- L["Here, you can set the maximum price you want to pay for each item in this list."] = ""
-- L["Hide Results Above Dealfinding Price"] = ""
-- L["Hide Saved Searches"] = ""
-- L["How long auctions should be posted for."] = ""
-- L["How much to undercut other auctions by, format is in \"#g#s#c\", \"50g30s\" means 50 gold, 30 silver."] = ""
-- L["If checked, only 5/10/15/20 stacks of ore and herbs will be shown."] = ""
-- L["If checked, only 5/10/15/20 stacks of ore and herbs will be shown. Note that this setting is the same as the one that shows up when you run a Destroying search."] = ""
-- L["If checked, the results of a dealfinding scan will include items above the maximum price. This can be useful if you sometimes want to buy items that are just above your max price."] = ""
-- L["If there are none of an item on the auction house, Shopping will use this percentage of the fallback price source for the default post price."] = ""
-- L["If there are none of an item on the auction house, Shopping will use this price source for the default post price."] = ""
-- L["If the results of a search only contain one unique item, it will be automatically expanded to show all auctions of that item if this option is enabled."] = ""
-- L["Ignore Existing Items"] = ""
-- L["Import Dealfinding List"] = ""
-- L["Imported List"] = ""
-- L["Import List"] = ""
-- L["Import Shopping List"] = ""
-- L["Invalid Exact Only Filter"] = ""
-- L["Invalid Filter"] = ""
L["Invalid folder name. A folder with this name may already exist."] = "Ungültiger Ordnername. Ein Ordner mit diesem Namen existiert vielleicht schon."
-- L["Invalid Item Level"] = ""
-- L["Invalid Item Rarity"] = ""
-- L["Invalid Item SubType"] = ""
-- L["Invalid Item Type"] = ""
-- L["Invalid list name. A list with this name may already exist."] = ""
-- L["Invalid Min Level"] = ""
L["Invalid money format entered, should be \"#g#s#c\", \"25g4s50c\" is 25 gold, 4 silver, 50 copper."] = "Ungültige Geldeingabe. Muss im Format \"#g#s#c\" sein. \"25g4s50c\" sind 25 Gold 4 Silber und 50 Kupfer."
-- L["Invalid search term."] = ""
-- L["Invalid Usable Only Filter"] = ""
-- L["Item"] = ""
-- L["Item Buyout:"] = ""
-- L["Item is already in dealfinding list: %s"] = ""
-- L["Item Level"] = ""
-- L["Items"] = ""
-- L["Item Settings"] = ""
L["Item to Add"] = "Gegenstand hinzufügen"
-- L["Left-Click: |cffffffffRun this recent search.|r"] = ""
-- L["Left-Click: |cffffffffRun this shopping/dealfinding list.|r"] = ""
-- L["List Data"] = ""
-- L["List Data (just select all and copy the data from inside this box)"] = ""
-- L["List Management"] = ""
-- L["List Name"] = ""
-- L["List to Add Item to:"] = ""
L["% Market Value"] = "% Marktwert"
-- L["MAX"] = ""
L["% Max Price"] = "% Marktpreis"
-- L["Max Price Per Item"] = ""
L["Milling"] = "Mahlen"
L["Mode:"] = "Modus:"
-- L["Name of New List to Add Item to:"] = ""
-- L["Name of the new dealfinding list."] = ""
-- L["Name of the new shopping list."] = ""
L["New"] = "Neu"
-- L["New Dealfinding List"] = ""
-- L["New List Name"] = ""
-- L["No items found that can be turned into:"] = ""
-- L["Nothing to search for."] = ""
-- L["No valid search terms. Aborting search."] = ""
L["Only even stacks (5/10/15/20) of this item will be purchased. This is useful for buying herbs / ore to mill / prospect."] = "Es werden nur 5er, 10er, 15er, 20er Stapel gekauft. Nützlich um Erze / Kräuter zum Sondieren / Mahlen zu kaufen."
-- L["Opens a new window that allows you to import a dealfinding list."] = ""
-- L["Opens a new window that allows you to import a shopping list."] = ""
L["Options"] = "Einstellungen"
L["Post"] = "Erstellen" -- Needs review
L["Posting"] = "Erstellt" -- Needs review
-- L["Posting Options"] = ""
-- L["Price Per Crafting Mat"] = ""
-- L["Price Per Enchanting Mat"] = ""
-- L["Price Per Gem"] = ""
-- L["Price Per Ink"] = ""
-- L["Price Per Item"] = ""
-- L["Price Per Item/Stack"] = ""
-- L["Price Per Stack"] = ""
-- L["Price Per Target Item"] = ""
-- L["Primary Filter"] = ""
-- L["Professions to Buy Materials for:"] = ""
L["Profiles"] = "Profile"
L["Prospecting"] = "Sondieren"
-- L["Purchasing"] = ""
-- L["Quantity Needed:"] = ""
-- L["Remove"] = ""
-- L["Remove Item"] = ""
-- L["Remove Search Term"] = ""
-- L["Rename List"] = ""
L["Reset Profile"] = "Profil zurücksetzen"
L["Reset the current profile back to its default values, in case your configuration is broken, or you simply want to start over."] = "Setzte das Profil auf die Grundeinstellungen zurück, falls die Konfiguration Fehler hat oder Sie einfach nochmal neu Anfangen wollen."
-- L["Right-Click: |cffffffffCreate shopping list from this recent search.|r"] = ""
-- L["Right-Click: |cffffffffOpen the options for this shopping/dealfinding list|r"] = ""
-- L["Scanning"] = ""
-- L["Scanning page %s of %s for filter: %s"] = ""
-- L["Scanning page %s of %s for filter %s of %s..."] = ""
-- L["Searching for item..."] = ""
-- L["Search Mode: |cff99ffffDestroying Search|r"] = ""
-- L["Search Mode: |cff99ffffRegular Search|r"] = ""
-- L["Search Results Default Sort (requires reload)"] = ""
-- L["Secondary Filter"] = ""
-- L["Select all the professions for which you would like to buy materials."] = ""
-- L["Select Mode"] = ""
-- L["Select Primary Filter"] = ""
-- L["Seller"] = ""
-- L["Shift-Right-Click: |cffffffffDelete this shopping/dealfinding list. Cannot be undone!|r"] = ""
-- L["Shift-Right-Click: |cffffffffRemove from recent searches.|r"] = ""
-- L["Shop for materials required by the Crafting queue."] = ""
L["Shopping - Crafting Mats"] = "Einkaufen - Herstellungsmaterial"
-- L["Shopping/Dealfinding Lists"] = ""
-- L["Shopping/Dealfinding list with name \"%s\" already exists. Creating group under name \"%s\" instead."] = ""
-- L["Shopping for:"] = ""
-- L["Shopping list deleted: \"%s\""] = ""
-- L["Shopping List Name"] = ""
-- L["Shopping Lists"] = ""
L["Shopping Options"] = "Einkaufseinstellungen"
-- L["Show/Hide the saved searches frame. This frame shows all your recent searches as well as your shopping and dealfinding lists."] = ""
-- L["Showing summary of all |cff99ffff%s|r auctions for \"|cff99ffffDealfinding Search|r\""] = ""
-- L["Showing summary of all |cff99ffff%s|r auctions for list \"|cff99ffff%s|r\""] = ""
-- L["Showing summary of all |cff99ffff%s|r auctions that match filter \"|cff99ffff%s|r\""] = ""
-- L["Show Saved Searches"] = ""
L["%s is already in a dealfinding list and has been removed from this list."] = "%s ist bereits in einer Angebotssuche und ist von dieser Liste gelöscht worden." -- Needs review
L["%s item(s) will be removed (already in a dealfinding list)"] = "%s Item(s) werdem gelöscht (bereits in der Angebotssuche)" -- Needs review
-- L["Skipped the following search term because it's invalid."] = ""
-- L["Skipped the following search term because it's too long. Blizzard does not allow search terms over 63 characters."] = ""
-- L["Specifies the default sorting for results in the \"Destroying\" feature."] = ""
-- L["Specifies the default sorting for results in the \"Search\" feature."] = ""
-- L["Stack Info:"] = ""
-- L["Stack Size"] = ""
-- L["stacks of"] = ""
-- L["Starts a dealfinding search which searches for all your dealfinding lists at once."] = ""
-- L["Summary of all |cff99ffff%s|r auctions that can be turned into:"] = ""
-- L["Switch List Type"] = ""
-- L["Switch Type"] = ""
-- L["The data you are trying to import is invalid."] = ""
L["The item you entered was invalid. See the tooltip for the \"%s\" editbox for info about how to add items."] = "Der eingegebene Gegenstand ist ungültig. Schauen Sie sich den Tooltip für das Eingabefeld für \"%s\" an, um zu sehen wie man Gegenstände hinzufügt."
-- L["The list you are trying to import is not a dealfinding list. Please use the shopping list import feature instead."] = ""
-- L["The list you are trying to import is not a shopping list. Please use the dealfinding list import feature instead."] = ""
-- L["The options below control the \"Post\" button that is shown at the bottom of the auction frame inside the \"Search\" feature."] = ""
L["This is the maximum price you want to pay per item (NOT per stack) for this item. You will be prompted to buy all items on the AH that are below this price."] = "Dies ist der maximale Preis den Sie pro Gegenstand (NICHT pro Stapel) ausgeben möchten. Sie werden gefragt ob sie alle Gegenstände im AH unter diesem Preis kaufen möchten."
-- L["This item is already in the \"%s\" Dealfinding List."] = ""
-- L["This item is already in this group."] = ""
-- L["Time Left"] = ""
--[==[ L[ [=[Total value of your auctions: %s
Incoming gold: %s]=] ] = "" ]==]
-- L["Transforming"] = ""
-- L["Unknown Filter"] = ""
-- L["Use the box below to create a new dealfinding list. A dealfinding list is a list of items along with a max price you'd like to pay for each item. This is the equivalent of a \"snatch list\"."] = ""
-- L["Use the box below to create a new shopping list. A shopping list is a list of items and search terms you frequently search for."] = ""
--[==[ L[ [=[Use the button below to convert this list from a Dealfinding list to a Shopping list.

NOTE: Doing so will remove all item settings from the list! This cannot be undone.]=] ] = "" ]==]
--[==[ L[ [=[Use the button below to convert this list from a Shopping list to a Dealfinding list.

NOTE: Doing so will remove all search terms from this list as well as any items that are already in a dealfinding list! This cannot be undone.]=] ] = "" ]==]
-- L["Use this checkbox to temporarily modify the post duration. You can change the default value in the Shopping options."] = ""
-- L["Which list to add this item to."] = ""
L["You can change the active database profile, so you can have different settings for every character."] = "Sie können das aktive Datenbank Profil ändern, damit Sie unterschiedliche Einstellungen für jeden Charakter haben."
L["You can either create a new profile by entering a name in the editbox, or choose one of the already exisiting profiles."] = "Sie können entweder ein neues Profil, indem Sie einen Namen in das Feld eingeben, erstellen, oder eines der existierenden Profile auswählen."
L["You can either drag an item into this box, paste (shift click) an item link into this box, or enter an itemID."] = "Sie können diesem Fenster einen Gegenstand per Drag&Drop, Shift+Klick eines Gegenstand-Links oder durch Eingabe der Gegenstands-ID hinzufügen." -- Needs review
-- L["You currently have %s of this item and it stacks up to %s."] = ""
