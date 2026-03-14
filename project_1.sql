/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Денисова Валерия
 * Дата: 10.11.2025
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
SELECT COUNT(id) AS total_users,
(SELECT COUNT(id) 
FROM fantasy.users 
WHERE payer = 1) AS payer_users,
(SELECT COUNT(id) 
FROM fantasy.users 
WHERE payer = 1)::REAL / COUNT(id) AS percent_of_payers
FROM fantasy.users 


-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
WITH total_users AS(
	SELECT race,
	COUNT(id) AS total_users
	FROM fantasy.race 
	LEFT JOIN fantasy.users USING(race_id)
	GROUP BY race),
payer_users AS(
	SELECT race,
	COUNT(id) AS payer_users
	FROM fantasy.race 
	LEFT JOIN fantasy.users USING(race_id)
	WHERE payer = 1
	GROUP BY race)
SELECT race,
payer_users,
total_users,
payer_users/total_users::REAL AS percent_of_payers
FROM total_users
LEFT JOIN payer_users USING(race)


-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
SELECT COUNT(amount) AS number_of_purchase,
SUM(amount) AS total_amount,
MIN(amount) AS min_amount,
MAX(amount) AS max_amount,
AVG(amount) AS avg_amount,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS median,
STDDEV(amount) AS stand_dev
FROM fantasy.events 

-- 2.2: Аномальные нулевые покупки:
WITH total AS(
	SELECT COUNT(amount) AS total
	FROM fantasy.events),
null_purchases AS(
	SELECT COUNT(amount) AS null_purchases
	FROM fantasy.events
	WHERE amount = 0)
SELECT null_purchases,
null_purchases::real / (SELECT total FROM total) AS percent_of_null
FROM null_purchases

-- 2.3: Популярные эпические предметы:
SELECT game_items,
COUNT(transaction_id) AS total_sells,
COUNT(transaction_id)::real / (SELECT COUNT(transaction_id)
	FROM fantasy.events
	WHERE amount>0) AS percent_of_sells,
COUNT(DISTINCT id)::real / (SELECT COUNT(DISTINCT id)
	FROM fantasy.events 
	WHERE amount>0) AS percent_of_users
FROM fantasy.items 
LEFT JOIN fantasy.events USING(item_code)
WHERE amount>0
GROUP BY game_items
ORDER BY percent_of_users DESC 

	
-- Часть 2. Решение ad hoc-задачи
-- Задача: Зависимость активности игроков от расы персонажа:
WITH total_players AS (
	SELECT race,
	COUNT(id) AS number_of_users
	FROM fantasy.race 
	LEFT JOIN fantasy.users USING(race_id)
	GROUP BY race),
buying_players AS (
	SELECT race,
	COUNT(DISTINCT events.id) AS buying_users
	FROM fantasy.race 
	LEFT JOIN fantasy.users USING(race_id)
	LEFT JOIN fantasy.events USING(id)
	WHERE amount>0
	GROUP BY race),
payers AS (
	SELECT race,
	COUNT(DISTINCT events.id) AS payers
	FROM fantasy.race 
	LEFT JOIN fantasy.users USING(race_id)
	LEFT JOIN fantasy.events USING(id)
	WHERE users.payer = 1
	GROUP BY race),
purchases AS (
	SELECT race,
	COUNT(transaction_id) AS number_of_purchases,
	SUM(amount) AS  sum_of_purchases 
	FROM fantasy.race 
	LEFT JOIN fantasy.users USING(race_id)
	LEFT JOIN fantasy.events USING(id)
	WHERE amount>0
	GROUP BY race)
SELECT race, 
number_of_users,
buying_users,
buying_users::REAL/number_of_users AS percent_of_buying,
payers::REAL/buying_users AS percent_of_payers,
number_of_purchases::REAL/buying_users AS avg_purchase_amount,
sum_of_purchases::REAL/number_of_purchases AS purchase_per_user,
sum_of_purchases::REAL/buying_users AS sum_per_user
FROM total_players
LEFT JOIN buying_players USING(race)
LEFT JOIN payers USING(race)
LEFT JOIN purchases USING(race)

