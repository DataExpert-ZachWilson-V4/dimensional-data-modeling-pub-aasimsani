-- Table as per the requirements of the question

CREATE TABLE actors (
	actor VARCHAR,
	-- Added actor ID since it's specified as a primary key and so I'm persisting this
	-- key
	actor_id VARCHAR,
	films ARRAY(
		ROW(
			film VARCHAR,
			votes INTEGER,
			rating DOUBLE,
			film_id VARCHAR,
			-- Added year since it made sense even if not specified in the question
			-- Plus LLM feedback + Discord discussion
			year INTEGER
		)
	),
	quality_class VARCHAR,
	is_active BOOLEAN,
	current_year INTEGER
) WITH (
	format = 'PARQUET',
	partitioning = ARRAY ['current_year']
)