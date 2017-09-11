-- 					TradeSkillMaster_Warehousing - AddOn by Geemoney							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/tradeskillmaster_warehousing.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Warehousing Locale - ptBR
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Warehousing/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Warehousing", "ptBR")
if not L then return end
L["   1.1) You can delete a group by typing in its name and hitting okay."] = "1.1) Você pode remover um grupo digitando seu nome e apertando Ok." -- Needs review
L["   1) Open up a bank (either the gbank or personal bank)"] = "') Abra um banco (qualquer um, o bancog ou o banco pessoal)" -- Needs review
L["   1) Type a name in the textbox labeled \"Create New Group\", hit okay"] = "1) Digite um nome na caixa de texto entitulada \"Criar Novo Grupo\", aperte Ok" -- Needs review
L["   2) Select that group using the table on the left, you should then see a list of all the items currently in your bags with a quantity"] = "2) Selecione aquele grupo utilizando a tabela na esquerda, você deve então ver uma lista de todos os itens nas suas bolsas no momento com uma quantidade" -- Needs review
L["   2) You should see a window on your right with a list of groups"] = "2) Você deve ver uma janela na sua direita com uma lista de grupos" -- Needs review
L["   3) Right click to increase, left click to decrease by the current increment"] = "3) Clique-direito para aumentar, clique-esquerdo para diminuir pelo incremento atual" -- Needs review
L["   3) Select a group and hit either"] = "3) Selecione um grupo e aperte em ambos" -- Needs review
L["   Again warehousing will try to fill out the order, but if it is short, it will remember how much it is short by and adjust its counts. So then you can go to another bank or another character and warehousing will grab the difference. Once the order has been completely filled out, warehousing will reset the count back to the original total. You cannot move a Crafting Queue bags->bank, only bank->bags."] = "Novamente o Warehousing tentará preencher o pedido, mas se faltar, ele se lembrará quanto faltou e ajustará suas contas. Para que então você possa ir a outro banco ou utilizar ou personagem e o Warehousing irá pegar a diferença. Uma vez que o pedido estiver completo, o Warehousing irá redefinir o contador de volta ao total original. Você não pode mover uma Fila de Produção das bolsas->banco, apenas do banco->bolsas." -- Needs review
L["Auctioning"] = "Leiloamento" -- Needs review
L["Crafting"] = "Produção" -- Needs review
L["Create New Group"] = "Criar Novo Grupo" -- Needs review
L["Delete Group"] = "Remover Grupo" -- Needs review
L["Empty Bags"] = "Esvaziar Bolsas" -- Needs review
L["Empty Bags/Restore Bags"] = "Esvaziar Bolsas/Restaurar Bolsas" -- Needs review
L["Group Behaviors"] = "Comportamentos de Grupo" -- Needs review
L["Groups"] = "Grupos" -- Needs review
L["How To"] = "Como" -- Needs review
L["Inventory Manager"] = "Gerenciador de Inventário" -- Needs review
L["Item"] = "Item" -- Needs review
L["Move Group to Bags"] = "Mover Grupo Para as Bolsas" -- Needs review
L["Move Group To Bags"] = "Mover Grupo Para as Bolsas" -- Needs review
L["Move Group to Bank"] = "Mover Grupo Para o Banco" -- Needs review
L["Move Group To Bank"] = "Mover Grupo Para o Banco" -- Needs review
L["New Group"] = "Novo Grupo" -- Needs review
L["or"] = "ou" -- Needs review
L["Quantity"] = "Quantidade" -- Needs review
L["Reset Crafting Queue"] = "Redefinir Fila de Produção" -- Needs review
L["Restore Bags"] = "Restaurar Bolsas" -- Needs review
L["Set Increment"] = "Definir Incremento" -- Needs review
L["   Simply hit empty bags, warehousing will remember what you had so that when you hit restore, it will grab all those items again. If you hit empty bags while your bags are empty it will overwrite the previous bag state, so you will not be able to use restore."] = "Simplesmente aperte em bolsas vazias, o Warehousing se lembrará o que você tinha para que quando você clicar em restaurar, ele pegue todos esses itens novamente. Se você clicou em bolsas vazias enquanto suas volsas estão vazias ele irá sobreescrever o estado anterior da bolsa, então você não será capaz de utilizar a restauração." -- Needs review
L["To create a Warehousing Group"] = "Para criar um Grupo do Warehousing" -- Needs review
L["To move a Group:"] = "Para mover um Grupo:" -- Needs review
L["TradeSkillMaster_InventoryManager"] = "TradeSkillMaster_InventoryManager" -- Needs review
L["Warehousing"] = "\009Warehousing" -- Needs review
L["Warehousing will only keep track of items that you have moved out of you bank and into your bags via the Inventory_Manager.  Finaly if you ever feel the need to reset the counts for a queue simply use the dropdown menu below."] = "O Warehousing apenas restreará os itens que você moveu para fora de seu banco e para dentro das suas bolsas através do Inventory_Manager. Finalmente, se você alguma vez sentir a necessidade de redefinir seus contadores para uma fila, simplesmente utilize o menu de lista abaixo." -- Needs review
L["   Warehousing will simply move all of each of the items in the group from the source to the destination."] = "O Warehousing irá simplesmente mover cada um dos itens no grupo da fonte para o destino." -- Needs review
L["   Warehousing will try to get the right number of items, if there are not enough in the bank to fill out order, it will grab all that there is."] = "O Warehousing tentará pegar o número correto de itens, se não houverem o bastante no banco para preencher o pedido, ele pegará tudo o que houver." -- Needs review
