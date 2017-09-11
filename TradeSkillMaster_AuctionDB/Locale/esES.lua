-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_AuctionDB - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_auctiondb.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_AuctionDB Locale - esES
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_AuctionDB/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_AuctionDB", "esES")
if not L then return end

-- L["A full auction house scan will scan every item on the auction house but is far slower than a GetAll scan. Expect this scan to take several minutes or longer."] = ""
-- L["A GetAll scan is the fastest in-game method for scanning every item on the auction house. However, it may disconnect you from the game and has a 15 minute cooldown."] = ""
L["Alchemy"] = "Alquimia"
L["Any items in the AuctionDB database that contain the search phrase in their names will be displayed."] = "Todos los artículos en la base de datos de AuctionDB que contienen la frase de búsqueda en su nombre en la pantalla." -- Needs review
-- L["A profession scan will scan items required/made by a certain profession."] = ""
L["Are you sure you want to clear your AuctionDB data?"] = "¿Está seguro que desea borrar los datos AuctionDB?" -- Needs review
L["Ascending"] = "Ascendente" -- Needs review
-- L["AuctionDB - Market Value"] = ""
L["AuctionDB Market Value:"] = "AuctionDB Valor de Mercado:" -- Needs review
L["AuctionDB Min Buyout:"] = "AuctionDB Compra Min:" -- Needs review
-- L["AuctionDB - Minimum Buyout"] = ""
L["AuctionDB Seen Count:"] = "AuctionDB Vistos:" -- Needs review
L["Blacksmithing"] = "Herreria" -- Needs review
-- L["|cffff0000WARNING:|r As of 4.0.1 there is a bug with GetAll scans only scanning a maximum of 42554 auctions from the AH which is less than your auction house currently contains. As a result, thousands of items may have been missed. Please use regular scans until blizzard fixes this bug."] = ""
L["Cooking"] = "Cocina" -- Needs review
L["Descending"] = "Descendiendo" -- Needs review
-- L["Done Scanning"] = ""
L["Enable display of AuctionDB data in tooltip."] = "Permitir la visualización de los datos AuctionDB en la descripción." -- Needs review
L["Enchanting"] = "Encantamiento" -- Needs review
L["Engineering"] = "Ingenieria" -- Needs review
L["General Options"] = "Opciones Generales" -- Needs review
L["Hide poor quality items"] = "Esconder objetos de calidad pobre" -- Needs review
L["If checked, poor quality items won't be shown in the search results."] = "Si se marca, los artículos de calidad pobre no se mostrará en los resultados de búsqueda." -- Needs review
L["Inscription"] = "Inscripcion" -- Needs review
L["Invalid value entered. You must enter a number between 5 and 500 inclusive."] = "Valor introducido no válido. Debe introducir un número entre 5 y 500." -- Needs review
L["Item Link"] = "Link de Objeto" -- Needs review
L["Item MinLevel"] = "NivelMin Objeto" -- Needs review
-- L["Items per page"] = ""
-- L["Items %s - %s (%s total)"] = ""
-- L["Item SubType Filter"] = ""
-- L["Item Type Filter"] = ""
-- L["It is strongly recommended that you reload your ui (type '/reload') after running a GetAll scan. Otherwise, any other scans (Post/Cancel/Search/etc) will be much slower than normal."] = ""
L["Jewelcrafting"] = "Joyeria" -- Needs review
-- L["Last Scanned"] = ""
L["Leatherworking"] = "Peletería" -- Needs review
-- L["Market Value"] = ""
-- L["Minimum Buyout"] = ""
-- L["Never scan the auction house again!"] = ""
-- L["Next Page"] = ""
-- L["No items found"] = ""
L["Not Ready"] = "No está listo" -- Needs review
-- L["Num(Yours)"] = ""
-- L["Options"] = ""
-- L["Previous Page"] = ""
-- L["Professions:"] = ""
L["Ready"] = "Listo" -- Needs review
L["Ready in %s min and %s sec"] = "Listo en %s min y %s sec." -- Needs review
-- L["Refresh"] = ""
-- L["Refreshes the current search results."] = ""
-- L["Removed %s from AuctionDB."] = ""
-- L["Reset Data"] = ""
-- L["Resets AuctionDB's scan data"] = ""
-- L["Run Full Scan"] = ""
L["Run GetAll Scan"] = "Hacer un GetAll Scan" -- Needs review
-- L["Run Profession Scan"] = ""
L["Run Scan"] = "Escanear" -- Needs review
L["%s ago"] = "hace %s" -- Needs review
-- L["Scan interrupted."] = ""
-- L["Scanning..."] = ""
-- L["Scan the auction house with AuctionDB to update its market value and min buyout data."] = ""
-- L["Search"] = ""
-- L["Search Options"] = ""
-- L["Select how you would like the search results to be sorted. After changing this option, you may need to refresh your search results by hitting the \"Refresh\" button."] = ""
-- L["Select professions to include in the profession scan."] = ""
-- L["Shift-Right-Click to clear all data for this item from AuctionDB."] = ""
-- L["Sort items by"] = ""
-- L["Sort search results in ascending order."] = ""
-- L["Sort search results in descending order."] = ""
-- L["%s - Scanning page %s/%s of filter %s/%s"] = ""
L["Tailoring"] = "Sastrería" -- Needs review
-- L["The author of TradeSkillMaster has created an application which uses blizzard's online auction house APIs to update your AuctionDB data automatically. Check it out at the link in TSM_AuctionDB's description on curse or at: %s"] = ""
-- L["This determines how many items are shown per page in results area of the \"Search\" tab of the AuctionDB page in the main TSM window. You may enter a number between 5 and 500 inclusive. If the page lags, you may want to decrease this number."] = ""
-- L["Use the search box and category filters above to search the AuctionDB data."] = ""
-- L["Waiting for data..."] = ""
-- L["You can filter the results by item subtype by using this dropdown. For example, if you want to search for all herbs, you would select \"Trade Goods\" in the item type dropdown and \"Herbs\" in this dropdown."] = ""
-- L["You can filter the results by item type by using this dropdown. For example, if you want to search for all herbs, you would select \"Trade Goods\" in this dropdown and \"Herbs\" as the subtype filter."] = ""
-- L["You can use this page to lookup an item or group of items in the AuctionDB database. Note that this does not perform a live search of the AH."] = ""
 