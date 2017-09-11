-- ------------------------------------------------------------------------------------- --
-- 					TradeSkillMaster_Accounting - AddOn by Sapu94							 	  	  --
--   http://wow.curse.com/downloads/wow-addons/details/TradeSkillMaster_Accounting.aspx   --
--																													  --
--		This addon is licensed under the CC BY-NC-ND 3.0 license as described at the		  --
--				following url: http://creativecommons.org/licenses/by-nc-nd/3.0/			 	  --
-- 	Please contact the author via email at sapu94@gmail.com with any questions or		  --
--		concerns regarding this license.																	  --
-- ------------------------------------------------------------------------------------- --

-- TradeSkillMaster_Accounting Locale - ruRU
-- Please use the localization app on CurseForge to update this
-- http://wow.curseforge.com/addons/TradeSkillMaster_Accounting/localization/

local L = LibStub("AceLocale-3.0"):NewLocale("TradeSkillMaster_Accounting", "ruRU")
if not L then return end

L["Accounting"] = "Учёт"
L["Activity Log"] = "Журнал активности"
L["Activity Type"] = "Вид активности"
L["Auctions"] = "Лоты"
L["Average Prices:"] = "Средняя цена:"
L["Avg Buy Price"] = "Средн. цена выкупа"
L["Avg Resale Profit"] = "Средн. прибыль от перепродажи"
L["Avg Sell Price"] = "Средн. цена продажи"
L["Back to Previous Page"] = "Назад к пред. странице"
L["Bought"] = "Куплено"
L["Buyer/Seller"] = "Покупатель/продавец"
L["Clear Old Data"] = "Очистить старые данные"
L["Click for a detailed report on this item."] = "Нажмите для вывода подробного отчета об этом товаре"
L["Click this button to permanently remove data older than the number of days selected in the dropdown."] = "Нажмите эту кнопку для безвозвратного удаления данных, которые старше чем выбранное в списке число дней."
L["Common Quality Items"] = "Обычное качество"
L["Data older than this many days will be deleted when you click on the button to the right."] = "Данные, которые старше чем выбранное здесь число дней, будут удалены при клике на кнопке справа."
L["Days:"] = "Дни:"
L["DD/MM/YY HH:MM"] = "ДД/ММ/ГГ ЧЧ:ММ"
L["Earned Per Day:"] = "Заработано в день"
L["Epic Quality Items"] = "Эпическое качество"
L["General Options"] = "Общие настройки"
L["Gold Earned:"] = "Заработано золота:"
L["Gold Spent:"] = "Потрачено золота:"
L["_ Hr _ Min ago"] = "_ Ч _ Мин назад"
L["If checked, the average purchase price that shows in the tooltip will be the average price for the most recent X you have purchased, where X is the number you have in your bags / bank / gbank using data from the ItemTracker module. Otherwise, a simple average of all purchases will be used."] = "Если выбрано, средняя цена в подсказке будет рассчитываться как средняя цена по X последним купленным вами предметам, где X - это количество данных товаров в ваших сумках / банке / банке гильдии, которое берётся из модуля ItemTracker. Иначе, будет использовано среднее арифметическое от всех купленных товаров."
L["If checked, the number you have purchased and the average purchase price will show up in an item's tooltip."] = "Показывать количество и среднюю цену покупки товара в подсказке."
L["If checked, the number you have sold and the average sale price will show up in an item's tooltip."] = "Показывать количество и среднюю цену продажи товара в подсказке."
L["Item Name"] = "Название товара"
L["Items"] = "Товары"
L["Items in an Auctioning Group"] = "Товары в аукционных группах"
L["Items NOT in an Auctioning Group"] = "Товаров НЕТ в аукционных группах"
L["Items/Resale Price Format"] = "Формат цены товаров/перепродажи"
L["Last 30 Days:"] = "Последние 30 дней:"
L["Last 7 Days:"] = "Последние 7 дней:"
L["Last Purchase"] = "Последняя покупка"
L["Last Sold"] = "Последняя продажа"
L["Market Value"] = "Рыночная цена"
L["Market Value Source"] = "Откуда брать рыночную цену"
L["MM/DD/YY HH:MM"] = "ММ/ДД/ГГ ЧЧ:ММ"
L["MySales Import Complete! Imported %s sales. Was unable to import %s sales."] = "Импорт MySales завершён! Импортировано %s продаж. Не получилось импортировать %s продаж."
L["MySales Import Progress"] = " Прогресс импорта MySales"
L["MySales is currently disabled. Would you like Accounting to enable it and reload your UI so it can transfer settings?"] = "На данный момент MySales не активен. Хотите ли вы, чтобы модуль Accounting включил его и перезагрузил интерфейс для переноса настроек?"
L["none"] = "без фильтра"
L["Options"] = "Настройки"
L["Price Per Item"] = "Цена за товар"
L["Purchase"] = "Покупка"
L["Purchase Data"] = "Данные покупки"
L["Purchased (Avg Price): %s (%s)"] = "Куплено (средн. цена): %s (%s)"
L["Purchased (Smart Avg): %s (%s)"] = "Куплено (\"умное\" средн.): %s (%s)"
L["Purchases"] = "Покупки"
L["Quantity"] = "Количество"
L["Quantity Bought:"] = "Число покупок:"
L["Quantity Sold:"] = "Число продаж:"
L["Rare Quality Items"] = "Редкое качество"
L["Removed a total of %s old records and %s items with no remaining records."] = "Всего удалено %s старых записей и %s товаров без оставшихся записей"
L["Remove Old Data (No Confirmation)"] = "Удалить старые данные (БЕЗ подтверждения)"
L["Resale"] = "Перепродажа"
L["%s ago"] = "%s назад"
L["Sale"] = "Продажа"
L["Sale Data"] = "Данные продажи"
L["Sales"] = "Продажи"
L["Search"] = "Поиск"
L["Select how you would like prices to be shown in the \"Items\" and \"Resale\" tabs; either average price per item or total value."] = "Выберите какую цену отображать во вкладках \"Товары\" и \"Перепродажа\" - среднюю цену за товар или общую стоимость."
L["Select what format Accounting should use to display times in applicable screens."] = "Выберите формат отображения времени"
L["Select where you want Accounting to get market value info from to show in applicable screens."] = "Выберите откуда брать информацию о рыночной цене"
L["Show purchase info in item tooltips"] = "Информация о покупках товара в подсказке"
L["Show sale info in item tooltips"] = "Информация о продажах товара в подсказке"
L["Sold"] = "Продано"
L["Sold (Avg Price): %s (%s)"] = "Продано (средн. цена): %s (%s)"
L["Special Filters"] = "Спец. фильтры"
L["Spent Per Day:"] = "Потрачено в день"
L["Stack Size"] = "Размер связки"
L["Starting to import MySales data. This requires building a large cache of item names which will take about 20-30 seconds. Please be patient."] = "Начинается импорт данных MySales. Потребуется построение значительного кеша имён товаров, которое займёт порядка 20-30 секунд. Пожалуйста, проявите терпение."
L["Summary"] = "Итого"
L["There is no purchase data for this item."] = "Нет данных о покупке этого товара."
L["There is no sale data for this item."] = "Нет данных о продаже этого товара."
L["Time"] = "Время"
L["Time Format"] = "Формат времени"
L["Tooltip Options"] = "Настройки подсказки"
L["Top Buyers:"] = "Топ покупателей:"
L["Top Item by Gold:"] = "Топ по золоту:"
L["Top Item by Quantity:"] = "Топ по количеству:"
L["Top Sellers:"] = "Топ продавцов:"
L["Total:"] = "Всего:"
L["Total Buy Price"] = "Общая цена покупки"
L["Total Price"] = "Общая цена"
L["Total Sale Price"] = "Общая цена продажи"
L["Total Spent:"] = "Всего потрачено:"
L["Total Value"] = "Общая стоимость"
L["TradeSkillMaster_Accounting has detected that you have MySales installed. Would you like to transfer your data over to Accounting?"] = "TradeSkillMaster_Accounting обнаружил наличие аддона MySales. Хотите перенести данные в модуль Accounting?"
L["Uncommon Quality Items"] = "Необычное качество"
L["Use smart average for purchase price"] = "Использовать среднее арифметическое для цены покупки"
L[ [=[You can use the options below to clear old data. It is recommened to occasionally clear your old data to keep Accounting running smoothly. Select the minimum number of days old to be removed in the dropdown, then click the button.

NOTE: There is no confirmation.]=] ] = [=[Используйте настройки ниже для очистки устаревших данных. Рекомендуется время от времени очищать старые данные, чтобы модуль Accounting гладко работал. Выберите минимальное число дней, данные старше которого будут удалены в списке, затем нажмите кнопку.

ВНИМАНИЕ: действие без подтверждения]=]
L["YY/MM/DD HH:MM"] = "ГГ/ММ/ДД ЧЧ:ММ"
 