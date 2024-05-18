-- Backfill the SCD table with the historical data for the actors for one year 
-- up to the latest year in the actors table

INSERT INTO actors_history_scd 
WITH lagged as (
		SELECT actor,
			actor_id,
			is_active,
			quality_class,
			current_year,
			-- Get the actor's n-1 quality class and is_active to compare with the
			-- current year's values
			LAG (quality_class, 1) OVER (
				PARTITION BY actor_id
				ORDER BY current_year ASC
			) AS prev_quality_class,
			LAG (is_active, 1) OVER (
				PARTITION BY actor_id
				ORDER BY current_year ASC
			) AS prev_is_active
		FROM actors
	),
	streak as (
		SELECT *,
			-- Based on whether the values for is_active and quality_class have changed
			-- create a sum number that shows the change points for either value 
			-- further used to group the change data records
			SUM(
				CASE
					WHEN is_active <> prev_is_active
					OR quality_class <> prev_quality_class THEN 1
					ELSE 0
				END
			) OVER (
				PARTITION BY actor_id
				ORDER BY current_year
			) AS streak_identifier
		FROM lagged
	)
-- Group the change data records by the change points and actor to insert into 
-- the SCD table
SELECT actor,
	actor_id,
	MAX(quality_class) as quality_class,
	MAX(is_active) as is_active,
	MIN(current_year) as start_date,
	MAX(current_year) as end_date,
	(SELECT MAX(current_year) FROM actors) AS current_year
FROM streak
GROUP BY actor,
	actor_id,
	streak_identifier