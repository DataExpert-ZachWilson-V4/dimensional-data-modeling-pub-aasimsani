INSERT INTO actors_history_scd 
	-- Assuming that I've inserted a few years of data into the actors table.
	-- Get the last year's data
	
	WITH last_year_scd AS (
		SELECT *
		FROM actors_history_scd
		WHERE end_date = 1914
	),
	-- Get the current year's data
	current_year_scd AS (
		SELECT *
		FROM actors
		WHERE current_year = 1915
	),
	-- Check if the current year's data has changed from the last year's data
	changed_check AS (
		-- Choose values that are not null from the last year's data 
		-- and the current year's data
		-- Covers cases of new actors, actors that have changed 
		-- and actors that have stayed the same where it'll pick the first 
		-- non-null value
		SELECT COALESCE(l.actor, t.actor) AS actor,
			COALESCE(l.actor_id, t.actor_id) AS actor_id,
			COALESCE(l.end_date, t.current_year) AS end_date,
			COALESCE(l.start_date, t.current_year) AS start_date,
			-- If the quality class or is_active has changed from the last year's data
			CASE
				WHEN t.quality_class <> l.quality_class
				OR t.is_active <> l.is_active THEN 1
				WHEN t.quality_class = l.quality_class
				AND t.is_active = l.is_active THEN 0
			END AS is_changed,
			-- Hardcoded value for the current year since we perform the 
			-- insert incrementally
			1915 AS current_year,
			l.is_active AS is_active_last_year,
			t.is_active AS is_active_current_year,
			l.quality_class AS quality_class_last_year,
			t.quality_class AS quality_class_current_year
		FROM last_year_scd AS l
			FULL OUTER JOIN current_year_scd AS t ON l.actor_id = t.actor_id
			AND l.end_date + 1 = t.current_year
	),
	-- Query to determine if a change has occurred and if so what the change is
	changes AS (
		SELECT actor,
			actor_id,
			current_year,
			CASE
				-- When a change hasn't occured but the actor is in the current year's data
				WHEN is_changed = 0 THEN ARRAY [
					CAST(
							ROW(quality_class_last_year, is_active_last_year, start_date, end_date + 1)
							AS ROW(quality_class VARCHAR, is_active BOOLEAN, start_date INTEGER, end_date INTEGER)
						)
				] -- When a change has occured
				WHEN is_changed = 1 THEN ARRAY [
					CAST(
						ROW(quality_class_last_year, is_active_last_year, start_date, end_date)
						AS ROW(quality_class VARCHAR, is_active BOOLEAN, start_date INTEGER, end_date INTEGER)
					),
					CAST(
						ROW(quality_class_current_year, is_active_current_year, current_year, current_year)
						AS ROW(quality_class VARCHAR, is_active BOOLEAN, start_date INTEGER, end_date INTEGER)
					)
				]
				-- When no change has occured and the actor is not in the current 
				-- year's data
				WHEN is_changed IS NULL THEN ARRAY [
					CAST(
						ROW(
								COALESCE(quality_class_last_year, quality_class_current_year),
								COALESCE(is_active_last_year, is_active_current_year),
								start_date,
								end_date
							)
						AS ROW(quality_class VARCHAR, is_active BOOLEAN, start_date INTEGER, end_date INTEGER)
					)
				]
			END AS change_array
		FROM changed_check
	)
SELECT actor,
	actor_id,
	arr.quality_class,
	arr.is_active,
	arr.start_date,
	arr.end_date,
	current_year
FROM changes
	CROSS JOIN UNNEST(change_array) AS arr