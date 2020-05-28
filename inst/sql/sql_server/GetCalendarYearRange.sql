SELECT YEAR(MIN(observation_period_start_date)) AS start_year,
	YEAR(MAX(observation_period_end_date)) AS end_year
FROM @cdm_observation_period_schema.@observation_period_table;
