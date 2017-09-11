-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_AuctionDB - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_AuctionDB.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_AuctionDB Locale - ptBR
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_AuctionDB/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_AuctionDB", "ptBR")
if not L then return end

L["A full auction house scan will scan every item on the auction house but is far slower than a GetAll scan. Expect this scan to take several minutes or longer."] = "Um escaneamento completo da casa de leilões irá escanear todos os itens da casa de leilões, porém é bem mais lento que um escaneamento PegaTudo. Espere que este escaneamento demore vários minutos ou mais." -- Needs review
L["A GetAll scan is the fastest in-game method for scanning every item on the auction house. However, it may disconnect you from the game and has a 15 minute cooldown."] = "Um escaneamento PegaTudo é o método mais rápido para escanear todos os itens da casa de leilões. Porém, ele pode te desconectar do jogo e possui uma recarga de 15 minutos." -- Needs review
L["Alchemy"] = "Alquimia" -- Needs review
L["Any items in the AuctionDB database that contain the search phrase in their names will be displayed."] = "Qualquer item no bando de dados do AuctionDB que contém a frase procurada em seus nomes serão exibidos." -- Needs review
L["A profession scan will scan items required/made by a certain profession."] = "Um escaneamento de profissão escaneará itens necessários/criados por uma certa profissão." -- Needs review
L["Are you sure you want to clear your AuctionDB data?"] = "Você tem certeza de que quer limpar os dados do seu AuctionDB?" -- Needs review
L["Ascending"] = "Crescente" -- Needs review
L["AuctionDB - Market Value"] = "AuctionDB - Valor de Mercado" -- Needs review
L["AuctionDB Market Value:"] = "AuctionDB Valor de Mercado:" -- Needs review
L["AuctionDB Min Buyout:"] = "AuctionDB Arremate Mínimo:" -- Needs review
L["AuctionDB - Minimum Buyout"] = "AuctionDB - Arremate Mínimo" -- Needs review
L["AuctionDB Seen Count:"] = "AuctionDB Vezes Visto:" -- Needs review
L["Blacksmithing"] = "Ferraria" -- Needs review
L["|cffff0000WARNING:|r As of 4.0.1 there is a bug with GetAll scans only scanning a maximum of 42554 auctions from the AH which is less than your auction house currently contains. As a result, thousands of items may have been missed. Please use regular scans until blizzard fixes this bug."] = "|cffff0000WARNING:|r Desde o 4.0.1 existe um bug com o BuscarTodos escaneando um máximo de 42554 leilões da CL que é menos o que sua casa de leilão contém atualmente. Como resultado, milhares de itens podem ter sido ignorados. Por favor use escaneamentos normais até a Blizzard arrumar o problema." -- Needs review
L["Cooking"] = "Culinária" -- Needs review
L["Descending"] = "Decrescente" -- Needs review
L["Done Scanning"] = "Escaneamento Completo" -- Needs review
L["Enable display of AuctionDB data in tooltip."] = "Habilita a exibição de dados do AuctionDB nas dicas de interface." -- Needs review
L["Enchanting"] = "Encantamento" -- Needs review
L["Engineering"] = "Engenharia" -- Needs review
L["General Options"] = "Opções Gerais" -- Needs review
L["Hide poor quality items"] = "Esconder itens de qualidade inferior" -- Needs review
L["If checked, poor quality items won't be shown in the search results."] = "Se marcado, itens de qualidade inferior não serão exibidos nos resultados das buscas." -- Needs review
L["Inscription"] = "Escrivania" -- Needs review
L["Invalid value entered. You must enter a number between 5 and 500 inclusive."] = "Valor inválido. Você deve digitar um número entre 5 e 500 (inclusive)." -- Needs review
L["Item Link"] = "Link do Item" -- Needs review
L["Item MinLevel"] = "NívelMín do Item" -- Needs review
L["Items per page"] = "Itens por página" -- Needs review
L["Items %s - %s (%s total)"] = "Itens %s - %s (%s no total)" -- Needs review
L["Item SubType Filter"] = "Filtro de SubTipo de Item" -- Needs review
L["Item Type Filter"] = "Filtro de Tipo de Item" -- Needs review
L["It is strongly recommended that you reload your ui (type '/reload') after running a GetAll scan. Otherwise, any other scans (Post/Cancel/Search/etc) will be much slower than normal."] = "É altamente recomendado que você recarregue sua IU (digite '/reload') após rodar um escaneamento PegaTudo. De outra forma, qualquer outro escaneamento (Postagem/Cancelamento/Busca/etc) será muito mais lento que o normal." -- Needs review
L["Jewelcrafting"] = "Joalheria" -- Needs review
L["Last Scanned"] = "Escaneado pela última vez" -- Needs review
L["Leatherworking"] = "Couraria" -- Needs review
L["Market Value"] = "Valor de Mercado" -- Needs review
L["Minimum Buyout"] = "Arremate Mínimo" -- Needs review
L["Never scan the auction house again!"] = "Nunca escaneie a casa de leilões novamente!" -- Needs review
L["Next Page"] = "Próxima Página" -- Needs review
L["No items found"] = "Nenhum item encontrado" -- Needs review
L["Not Ready"] = "Não está pronto" -- Needs review
L["Num(Yours)"] = "Num(Seu)" -- Needs review
L["Options"] = "Opções" -- Needs review
L["Previous Page"] = "Página anterior" -- Needs review
L["Professions:"] = "Profissões:" -- Needs review
L["Ready"] = "Pronto" -- Needs review
L["Ready in %s min and %s sec"] = "Pronto em $s min e %s seg" -- Needs review
L["Refresh"] = "Refrescar" -- Needs review
L["Refreshes the current search results."] = "Refrescar os resultados da busca atual." -- Needs review
L["Removed %s from AuctionDB."] = "%s removido do AuctionDB." -- Needs review
L["Reset Data"] = "Redefinir Dados" -- Needs review
L["Resets AuctionDB's scan data"] = "Redefine os dados de escaneamento do AuctionDB" -- Needs review
L["Run Full Scan"] = "Rodar um Escaneamento Completo" -- Needs review
L["Run GetAll Scan"] = "Executar Escaneamento PegarTudo" -- Needs review
L["Run Profession Scan"] = "Rodar um Escaneamento de Profissão" -- Needs review
L["Run Scan"] = "Executar Escaneamento" -- Needs review
L["%s ago"] = "%s atrás" -- Needs review
L["Scan interrupted."] = "Escaneamento interrompido." -- Needs review
L["Scanning..."] = "Escaneando..." -- Needs review
L["Scan the auction house with AuctionDB to update its market value and min buyout data."] = "Escaneia a casa de leilões com o AuctionDB para atualizar seus dados de valores de mercado e arremates mínimos." -- Needs review
L["Search"] = "Buscar" -- Needs review
L["Search Options"] = "Opções de Busca" -- Needs review
L["Select how you would like the search results to be sorted. After changing this option, you may need to refresh your search results by hitting the \"Refresh\" button."] = "Selecione como você gostaria que os resultados da busca sejam ordenados. Depois de alterar esta opção você deve refrescar os resultados de sua busca clicando no botão \"Refrescar\"." -- Needs review
L["Select professions to include in the profession scan."] = "Selecione profissões a incluir no escaneamento de profissão." -- Needs review
L["Shift-Right-Click to clear all data for this item from AuctionDB."] = "Shift-Clique-Direito para limpar todos os dados para este item do AuctionDB." -- Needs review
L["Sort items by"] = "Ordenar items por" -- Needs review
L["Sort search results in ascending order."] = "Ordenas resultada da busca em ordem crescente." -- Needs review
L["Sort search results in descending order."] = "Ordenar resultados da busca em ordem decrescente." -- Needs review
L["%s - Scanning page %s/%s of filter %s/%s"] = "%s - Escaneando a página %s/%s do filtro %s/%s" -- Needs review
L["Tailoring"] = "Alfaiataria" -- Needs review
L["The author of TradeSkillMaster has created an application which uses blizzard's online auction house APIs to update your AuctionDB data automatically. Check it out at the link in TSM_AuctionDB's description on curse or at: %s"] = "O autor do TradeSkillMaster criou um aplicativo que utiliza as APIs de casas de leilões da Blizzard para atualizar seus dados do AuctionDB automaticamente. Verifique no link da descrição do TSM_AuctionDB no curse ou em: %s" -- Needs review
L["This determines how many items are shown per page in results area of the \"Search\" tab of the AuctionDB page in the main TSM window. You may enter a number between 5 and 500 inclusive. If the page lags, you may want to decrease this number."] = "Determina quantos itens são mostrados por página na área de resultados da aba \"Busca\" da página do AuctionDB na janela principal do TSM. Você pode digitar um número entre 5 e 500 (inclusive). Se houver demora na página você pode querer diminuir este número." -- Needs review
L["Use the search box and category filters above to search the AuctionDB data."] = "Use a caixa de busca e filtros de categoria acima para procurar nos dados do AuctionDB." -- Needs review
L["Waiting for data..."] = "Aguardando pelos dados..." -- Needs review
L["You can filter the results by item subtype by using this dropdown. For example, if you want to search for all herbs, you would select \"Trade Goods\" in the item type dropdown and \"Herbs\" in this dropdown."] = "Você pode filtrar os resultados por subtipo de item usando esta opção. Por exemplo, se você quer procurar todas as ervas você deve selecionar \"Mercadorias\" no menu de tipo de item e \"Ervas\" neste menu." -- Needs review
L["You can filter the results by item type by using this dropdown. For example, if you want to search for all herbs, you would select \"Trade Goods\" in this dropdown and \"Herbs\" as the subtype filter."] = "Você pode filtrar os resultados por tipo de item usando esta opção. Por exemplo, se você quer procurar todas as ervas você deve selecionar \"Mercadorias\" neste menu e \"Ervas\" no menu de subtipo. " -- Needs review
L["You can use this page to lookup an item or group of items in the AuctionDB database. Note that this does not perform a live search of the AH."] = "Você pode usar esta página para procurar por um item ou grupo de itens no banco de dados do AuctionDB. Observe que isto não executará uma pesquisa ao vivo na CL." -- Needs review
 