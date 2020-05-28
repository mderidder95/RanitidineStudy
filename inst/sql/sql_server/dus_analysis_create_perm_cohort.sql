{DEFAULT @add_index = FALSE}

IF OBJECT_ID('@cohort_database_schema.dus_h2_temp_cohort', 'U') IS NOT NULL DROP TABLE @cohort_database_schema.dus_h2_temp_cohort;

CREATE TABLE @cohort_database_schema.dus_h2_temp_cohort (
  cohort_definition_id INT NOT NULL,
  subject_id BIGINT NOT NULL,
  cohort_start_date DATETIME NOT NULL,
  cohort_end_date DATETIME NOT NULL,
  drug_exposure_id BIGINT NOT NULL,
  drug_concept_id BIGINT NOT NULL,
  dose_form_group_concept_id BIGINT NOT NULL,
	formulation VARCHAR(500) NOT NULL
)
;

INSERT INTO  @cohort_database_schema.dus_h2_temp_cohort (
  cohort_definition_id,
  subject_id,
  cohort_start_date,
  cohort_end_date,
  drug_exposure_id,
  drug_concept_id,
  dose_form_group_concept_id,
	formulation
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
FROM #COHORT_W_FRML
;

{@add_index} ? {
-- Add an index to the drug exposure table to help with performance in the next step
CREATE INDEX idx_tmp_c_id ON @cohort_database_schema.dus_h2_temp_cohort (cohort_definition_id);
CREATE INDEX idx_tmp_c_subj ON @cohort_database_schema.dus_h2_temp_cohort (subject_id);
CREATE INDEX idx_tmp_c_csd ON @cohort_database_schema.dus_h2_temp_cohort (cohort_start_date);
CREATE INDEX idx_tmp_c_ced ON @cohort_database_schema.dus_h2_temp_cohort (cohort_end_date);
CREATE INDEX idx_tmp_c_deid ON @cohort_database_schema.dus_h2_temp_cohort (drug_exposure_id);
CREATE INDEX idx_tmp_c_dcid ON @cohort_database_schema.dus_h2_temp_cohort (drug_concept_id);
CREATE INDEX idx_tmp_c_dfg ON @cohort_database_schema.dus_h2_temp_cohort (dose_form_group_concept_id);
CREATE INDEX idx_tmp_c_f ON @cohort_database_schema.dus_h2_temp_cohort (formulation);
} : {}

IF OBJECT_ID('@cohort_database_schema.dus_h2_cohort', 'U') IS NOT NULL DROP TABLE @cohort_database_schema.dus_h2_cohort;

CREATE TABLE @cohort_database_schema.dus_h2_cohort (
  person_id BIGINT NOT NULL,
  cohort_start_date DATETIME NOT NULL,
  drug_exposure_id BIGINT NOT NULL,
	gender VARCHAR(255) NOT NULL, 
	age INT NOT NULL,
	formulation VARCHAR(500) NOT NULL,
  ingredient	INT NOT NULL,
  indication_180_gerd	INT NOT NULL,
  indication_180_ulcer	INT NOT NULL,
  indication_180_zes	INT NOT NULL,
  indication_365_gerd	INT NOT NULL,
  indication_365_ulcer	INT NOT NULL,
  indication_365_zes	INT NOT NULL,
  indication_365_ri	INT NOT NULL,
  total_exposures INT NOT NULL,
  total_exposures_with_strength INT NOT NULL,
  cumulative_duration INT NOT NULL,
  pdd FLOAT NOT NULL,
  pdd_ratio FLOAT NOT NULL,
  cumulative_dose FLOAT NOT NULL,
  cumulative_DDD FLOAT NOT NULL,
  cumulative_annual_dose FLOAT NOT NULL,
  observation_period_days INT NOT NULL
);

INSERT INTO @cohort_database_schema.dus_h2_cohort (
  person_id,
  cohort_start_date,
  drug_exposure_id,
	gender,
	age,
	formulation,
  ingredient,
  indication_180_gerd,
  indication_180_zes,
  indication_180_ulcer,
  indication_365_gerd,
  indication_365_zes,
  indication_365_ulcer,
  indication_365_ri,
  total_exposures,
  total_exposures_with_strength,
  cumulative_duration,
  pdd,
  pdd_ratio,
  cumulative_dose,
  cumulative_DDD,
  cumulative_annual_dose,
  observation_period_days
)
select
	c.subject_id person_id, 
	c.cohort_start_date,
	c.drug_exposure_id,
	cg.concept_name gender,
	(YEAR(c.cohort_start_date) - p.year_of_birth) age,
	c.formulation,
	c.cohort_definition_id ingredient,
	CASE 
		WHEN
			SUM(CASE 
				WHEN COALESCE(ind.cohort_definition_id, 0) = 10 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) >= -180 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) <= 0
				THEN 1
				ELSE 0
			END) >= 1 
		THEN 1
		ELSE 0
	END indication_180_gerd,
	CASE 
		WHEN
			SUM(CASE 
				WHEN COALESCE(ind.cohort_definition_id, 0) = 11 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) >= -180 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) <= 0
				THEN 1
				ELSE 0
			END) >= 1 
		THEN 1
		ELSE 0
	END indication_180_zes,
	CASE 
		WHEN
			SUM(CASE 
				WHEN COALESCE(ind.cohort_definition_id, 0) = 12 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) >= -180 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) <= 0
				THEN 1
				ELSE 0
			END) >= 1 
		THEN 1
		ELSE 0
	END indication_180_ulcer,
	CASE 
		WHEN
			SUM(CASE 
				WHEN COALESCE(ind.cohort_definition_id, 0) = 10 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) >= -365 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) <= 0
				THEN 1
				ELSE 0
			END) >= 1 
		THEN 1
		ELSE 0
	END indication_365_gerd,
	CASE 
		WHEN
			SUM(CASE 
				WHEN COALESCE(ind.cohort_definition_id, 0) = 11 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) >= -365
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) <= 0
				THEN 1
				ELSE 0
			END) >= 1 
		THEN 1
		ELSE 0
	END indication_365_zes,
	CASE 
		WHEN
			SUM(CASE 
				WHEN COALESCE(ind.cohort_definition_id, 0) = 12 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) >= -365 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) <= 0
				THEN 1
				ELSE 0
			END) >= 1  
		THEN 1
		ELSE 0
	END indication_365_ulcer,
	CASE 
		WHEN
			SUM(CASE 
				WHEN COALESCE(ind.cohort_definition_id, 0) = 13 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) >= -365 
				 AND DATEDIFF(dd, c.cohort_start_date, ind.cohort_start_date) <= 0
				THEN 1
				ELSE 0
			END) >= 1 
		THEN 1
		ELSE 0
	END indication_365_ri,
	te.total_exposures,
	ISNULL(tews.total_exposures_with_strength, 0),
	te.cumulative_duration,
	de.pdd,
	CASE 
		WHEN de.pdd IS NOT NULL AND de.ddd <> 0 THEN de.pdd / de.ddd
		ELSE 0
	END pdd_ratio,
	te.cumulative_dose,
	te.cumulative_DDD,
	CASE 
		WHEN DATEDIFF(dd, op.observation_period_start_date, op.observation_period_end_date) <> 0
		  THEN te.cumulative_dose / (DATEDIFF(dd, op.observation_period_start_date, op.observation_period_end_date) / 365.25)
		ELSE 0
	END cumulative_annual_dose,
	DATEDIFF(dd, op.observation_period_start_date, op.observation_period_end_date) observation_period_days
from @cohort_database_schema.dus_h2_temp_cohort c
inner join @cdm_person_schema.@person_table p ON c.subject_id = p.person_id
inner join @vocabulary_database_schema.concept cg ON cg.concept_id = p.gender_concept_id
left join (
	SELECT *
	FROM @cohort_database_schema.@cohort_table
	WHERE cohort_definition_id >= 10 AND cohort_definition_id <= 13 -- Based on the CohortsToCreate.csv
) ind ON ind.subject_id = c.subject_id and ind.cohort_start_date <= c.cohort_start_date -- Only consider those indications on or prior to index
INNER JOIN @cdm_observation_period_schema.@observation_period_table op
  ON c.subject_id = op.person_id
  AND c.cohort_start_date >= op.observation_period_start_date
  AND c.cohort_start_date <= op.observation_period_end_date
INNER JOIN @cohort_database_schema.dus_h2_drug_exposure de
  ON de.person_id = c.subject_id
  AND de.drug_exposure_id = c.drug_exposure_id
INNER JOIN (
  SELECT 
    ingredient, 
    person_id,
    dose_form_group_concept_id,
    COUNT(DISTINCT drug_exposure_id) total_exposures,
    SUM(duration) cumulative_duration,
    SUM(full_dose) cumulative_dose,
    SUM(cumulative_num_ddd) cumulative_DDD
  FROM @cohort_database_schema.dus_h2_drug_exposure
  GROUP BY ingredient, person_id, dose_form_group_concept_id
) te ON 
  te.ingredient = c.cohort_definition_id 
  AND te.person_id = c.subject_id 
  AND te.dose_form_group_concept_id = c.dose_form_group_concept_id
LEFT JOIN (
  SELECT ingredient, person_id, dose_form_group_concept_id, COUNT(DISTINCT drug_exposure_id) total_exposures_with_strength
  FROM @cohort_database_schema.dus_h2_drug_exposure
  WHERE quantity > 0 AND (amount_unit_concept_id > 0 OR numerator_unit_concept_id > 0)
  GROUP BY ingredient, person_id, dose_form_group_concept_id
) tews ON 
  tews.ingredient = c.cohort_definition_id 
  AND tews.person_id = c.subject_id
  AND tews.dose_form_group_concept_id = c.dose_form_group_concept_id
GROUP BY
	c.subject_id, 
	c.cohort_start_date,
	c.drug_exposure_id,
	cg.concept_name,
	c.cohort_start_date,
	p.year_of_birth,
	c.formulation,
	c.cohort_definition_id,
	te.total_exposures,
	tews.total_exposures_with_strength,
	te.cumulative_duration,
	de.pdd,
	de.ddd,
  te.cumulative_dose,
  te.cumulative_ddd,
	op.observation_period_start_date, 
	op.observation_period_end_date
;