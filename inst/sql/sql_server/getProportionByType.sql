SELECT 
  denominator.calendar_year,
  denominator.age_group,
  c.concept_name AS gender,
	CASE 
		WHEN numerator.num_persons IS NOT NULL THEN numerator.num_persons
		ELSE CAST(0 AS INT)
	END AS cohort_count,
	denominator.num_persons
FROM @cohort_database_schema.dus_h2_denominator denominator --FROM #denominator denominator
INNER JOIN @cdm_database_schema.concept c
	ON denominator.gender_concept_id = c.concept_id
LEFT JOIN (
  SELECT *
  FROM @cohort_database_schema.dus_h2_numerator
  WHERE numerator_type = '@numerator_type'
    AND ingredient = @ingredient
) numerator
	ON denominator.calendar_year = numerator.calendar_year
	AND denominator.gender_concept_id = numerator.gender_concept_id
	AND denominator.age_group = numerator.age_group
WHERE denominator.denominator_type = '@denominator_type'
order by 
  denominator.age_group,
  denominator.calendar_year,
  c.concept_name 
;
