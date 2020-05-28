-- Get all of the individual drug exposure for each cohort member based on the start date + 
-- the ingredient mapped
SELECT DISTINCT
	ci.cohort_id ingredient,
	de.drug_exposure_id,
	de.person_id, 
	de.drug_concept_id, 
	c.concept_name drug_name, 
	dfg.dose_form_group_concept_id,
	dfgc.concept_name formulation,
	ci.ingredient_concept_id, 
	ingc.concept_name ingredient_name,
	ci.ddd,
	de.drug_exposure_start_date,
	/* HACK - infer the end date for now */
	CASE 
	  WHEN de.drug_exposure_end_date IS NOT NULL THEN de.drug_exposure_end_date
	  WHEN ISNULL(de.days_supply, 0) = 0 THEN de.drug_exposure_start_date
	  ELSE DATEADD(dd, ISNULL(de.days_supply, 1) - 1, de.drug_exposure_start_date) 
	END drug_exposure_end_date,
	ISNULL(de.quantity, 0) quantity,
	de.days_supply,
	de.sig,
	ISNULL(ds.amount_value, 0) amount_value,
	ISNULL(ds.amount_unit_concept_id, 0) amount_unit_concept_id,
	ISNULL(u1.concept_name, '') amount_unit,
	ISNULL(ds.numerator_value, 0) numerator_value,
	ISNULL(ds.numerator_unit_concept_id, 0) numerator_unit_concept_id,
	ISNULL(u2.concept_name, '') numerator_unit,
	ISNULL(ds.denominator_value, 1) denominator_value,
	ISNULL(ds.denominator_unit_concept_id, 0) denominator_unit_concept_id,
	ISNULL(u3.concept_name, '') denominator_unit,
	ISNULL(ds.box_size, 0) box_size,
	ds.valid_start_date,
	ds.valid_end_date,
	ds.invalid_reason
INTO #DRUG_EXPOSURES
FROM (
	select distinct subject_id
	from #COHORT_W_FRML
) subj
INNER JOIN @cdm_drug_exposure_schema.@drug_exposure_table de ON de.person_id = subj.subject_id
INNER JOIN @cdm_observation_period_schema.@observation_period_table op ON de.person_id = op.person_id
  AND de.drug_exposure_start_date >= op.observation_period_start_date
  AND de.drug_exposure_start_date <= op.observation_period_end_date
INNER JOIN #COHORT_DDD_XREF ci ON ci.drug_concept_id = de.drug_concept_id
INNER JOIN @vocabulary_database_schema.concept ingc ON ingc.concept_id = ci.ingredient_concept_id
INNER JOIN @vocabulary_database_schema.concept c ON c.concept_id = de.drug_concept_id
INNER JOIN #DFG_PRIORITIZED dfg ON dfg.drug_concept_id = de.drug_concept_id
INNER JOIN @vocabulary_database_schema.concept dfgc ON dfgc.concept_id = dfg.dose_form_group_concept_id
LEFT JOIN @vocabulary_database_schema.drug_strength ds 
  ON ci.drug_concept_id = ds.drug_concept_id 
  AND ci.ingredient_concept_id = ds.ingredient_concept_id
LEFT JOIN #UNIT_CONCEPTS u1 ON u1.concept_id = ds.amount_unit_concept_id
LEFT JOIN #UNIT_CONCEPTS u2 ON u2.concept_id = ds.numerator_unit_concept_id
LEFT JOIN #UNIT_CONCEPTS u3 ON u3.concept_id = ds.denominator_unit_concept_id
;