-- Determine the formulation for the initial 
-- dosing. There exists the possibility that
-- the initial dose contains > 1 row and in this
-- case we'll use the dosing form alphabetically (descending)
-- to break the tie so that Orals beat out injectables since
-- Orals are far more prevalent. This query will then
-- produce a temp table to use for the remainder of the
-- script.
WITH allExposures AS (
  SELECT
    c.cohort_definition_id,
    c.subject_id,
    cohort_start_date,
    cohort_end_date,
    de.drug_exposure_id,
    de.drug_concept_id,
    dfg.dose_form_group_concept_id,
    con.concept_name formulation,
    row_number() over (PARTITION BY 
      c.cohort_definition_id,
      c.subject_id
      ORDER BY con.concept_name DESC
    ) ordinal
  FROM @cohort_database_schema.@cohort_table c
  INNER JOIN #COHORT_DDD_XREF cXref ON cXref.cohort_id = c.cohort_definition_id
  INNER JOIN @cdm_drug_exposure_schema.@drug_exposure_table de 
    ON de.person_id = c.subject_id
    AND de.drug_exposure_start_date = c.cohort_start_date
  	AND de.drug_concept_id = cXref.drug_concept_id
  INNER JOIN  #DFG_PRIORITIZED dfg
    ON de.drug_concept_id = dfg.drug_concept_id
  INNER JOIN @vocabulary_database_schema.concept con 
    ON con.concept_id = dfg.dose_form_group_concept_id
  WHERE c.cohort_definition_id IN (SELECT cohort_id FROM #COHORT_DDD_XREF) -- Based on the CohortsToCreate.csv, just do the incident cohorts
)
SELECT 
    cohort_definition_id,
    subject_id,
    cohort_start_date,
    cohort_end_date,
    drug_exposure_id,
    drug_concept_id,
    dose_form_group_concept_id,
    formulation
INTO #COHORT_W_FRML
FROM allExposures
WHERE ordinal = 1
;
