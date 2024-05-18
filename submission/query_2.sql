-- Incremental insertion query
-- Insertion for the first year of the actors change data capture table knowing that:
-- Min year 1914
-- Max year 2021

INSERT INTO actors WITH last_year as (
		SELECT *
		FROM actors
		WHERE current_year = 1913
	),
	-- Aggregate data since unlike the NBA dataset which is on seasons
	-- This dataset is by films not by years so this CTE turns it into by years for
	-- each actor
	this_year as (
		SELECT actor,
			actor_id,
			ARRAY_AGG(ROW (film, votes, rating, film_id, year)) as films,
			-- Average the rating of all the movies for the actor for that year
			avg(rating) as av_rating,
			year
		FROM bootcamp.actor_films
		WHERE year = 1914
		GROUP BY actor,
			actor_id,
			year
	)
-- The main query
SELECT COALESCE(l.actor, t.actor) AS actor,
	COALESCE(l.actor_id, t.actor_id) AS actor_id,
	-- Aggregating the films for the actor
	CASE
		-- If the actor is not in films this year persist the films from last year
		WHEN t.films IS NULL THEN l.films
		-- If the actor is in films for the first time this year and 
		-- therefore not in actors table last year then set this year's films 
		WHEN t.films IS NOT NULL
		AND l.films IS NULL THEN t.films
		-- If the actor is in films this year and last year persist the films 
		-- from both years
		WHEN t.films IS NOT NULL
		AND l.films IS NOT NULL THEN t.films || l.films
	END AS films,
	-- Set the quality class based on the average rating of the actor
	CASE
		WHEN t.av_rating IS NULL then l.quality_class
		WHEN t.av_rating IS NOT NULL
		AND t.av_rating > 8 THEN 'star'
		WHEN t.av_rating IS NOT NULL
		AND t.av_rating > 7
		AND t.av_rating <= 8 THEN 'good'
		WHEN t.av_rating IS NOT NULL
		AND t.av_rating > 6
		AND t.av_rating <= 7 THEN 'average'
		WHEN t.av_rating IS NOT NULL
		AND t.av_rating <= 6 THEN 'bad'
	END AS quality_class,
	-- Determine if the actor is active based on if they are in films this year
	t.year IS NOT NULL as is_active,
	-- Set current year to the correct year based on if the actor is in films this year
	COALESCE(t.year, l.current_year + 1) AS current_year
FROM last_year AS l
	FULL OUTER JOIN this_year AS t ON l.actor_id = t.actor_id