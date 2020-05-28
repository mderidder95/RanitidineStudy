SELECT obs_year_month, num_persons
FROM @cohort_database_schema.dus_h2_obs_per_month
ORDER BY obs_year_month asc
;