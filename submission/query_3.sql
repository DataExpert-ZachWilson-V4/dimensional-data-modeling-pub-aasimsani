-- SCD Table partioned by current_year

CREATE TABLE actors_history_scd (
	actor VARCHAR,
	-- Included since it is specified as the primary key and I use for joins
	actor_id VARCHAR,
	quality_class VARCHAR,
	is_active BOOLEAN,
	start_date INTEGER,
	end_date INTEGER,
	current_year INTEGER
)
WITH (
	format = 'PARQUET',
	partitioning = ARRAY['current_year']
)