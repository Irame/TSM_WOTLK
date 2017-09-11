-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_ItemTracker - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_ItemTracker.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_ItemTracker Locale - ptBR
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_ItemTracker/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_ItemTracker", "ptBR")
if not L then return end

L["Delete Character:"] = "Apagar Personagem:" -- Needs review
L["Full"] = "Completo" -- Needs review
L["Here, you can choose what ItemTracker info, if any, to show in tooltips. \"Simple\" will show only show totals for bags/banks and for guild banks. \"Full\" will show detailed information for every character and guild."] = "Aqui, você pode escolher quais informações do ItemTracker, se alguma, serão exibidas nas dicas. \"Simples\" exibirá apenas os totais para a mochila/bancos e para os bancos da guilda. \"Completo\" exibirá informações detalhadas para cada personagem e guilda." -- Needs review
L["If you previously used TSM_Gathering, note that inventory data was not transfered to TSM_ItemTracker and will not show up until you log onto each character and visit the bank / gbank / auction house."] = "Se você utilizou anteriormente o TSM_Gathering, note que os dados de inventário não foram transferidos ao TSM_ItemTracker e não serão exibidos até que você conecte em cada personagem e visite o banco / bancog / casa de leilões." -- Needs review
L["If you rename / transfer / delete one of your characters, use this dropdown to remove that character from ItemTracker. There is no confirmation. If you accidentally delete a character that still exists, simply log onto that character to re-add it to ItemTracker."] = "Se você renomear / transferir / remover um de seus personagens, utilize esta lista para remover aquele personagem do ItemTracker. Não há confirmação. Se você remover um personagem acidentalmente que ainda exista, simplesmente se conecte com aquele personagem e o readicione ao ItemTracker." -- Needs review
L["ItemTracker: %s on player, %s on alts, %s in guild banks, %s on AH"] = "ItemTracker: %s no jogador, %s em alts, %s nos bancos de guildas, %s na CL" -- Needs review
L["No Tooltip Info"] = "Nenhuma Informação de Dica" -- Needs review
L["Options"] = "Opções" -- Needs review
L["Simple"] = "Simples" -- Needs review
L["\"%s\" removed from ItemTracker."] = "\"%s\" removido do ItemTracker." -- Needs review
L["%s: %s in guild bank"] = "%s: %s no banco da guilda" -- Needs review
L["%s: %s (%s in bags, %s in bank, %s on AH)"] = "%s: %s (%s nas bolsas, %s no banco, %s na CL)" -- Needs review
L["trackerMessage"] = "MensagemDoTracker" -- Needs review
 