{DEFAULT @add_index = FALSE}

IF OBJECT_ID('@cohort_database_schema.dus_h2_drug_exposure', 'U') IS NOT NULL DROP TABLE @cohort_database_schema.dus_h2_drug_exposure;

CREATE TABLE @cohort_database_schema.dus_h2_drug_exposure (
  ingredient INT NOT NULL,
  drug_exposure_id BIGINT NOT NULL,
  person_id BIGINT NOT NULL,
  drug_concept_id INT NOT NULL,
  drug_name VARCHAR(255) NOT NULL, 
  dose_form_group_concept_id INT NOT NULL,
  formulation VARCHAR(255) NOT NULL,
  ingredient_concept_id INT NOT NULL,
  ingredient_name VARCHAR(255) NOT NULL, 
  ddd FLOAT NOT NULL,
  drug_exposure_start_date DATETIME NOT NULL,
  drug_exposure_end_date DATETIME NOT NULL, 
  duration INT NOT NULL,
  quantity INT NULL,
  days_supply INT NULL,
  sig VARCHAR(MAX) NULL,
  pdd FLOAT NULL,
  full_dose FLOAT NULL,
  cumulative_num_ddd FLOAT NULL,
  amount_value FLOAT NULL,
  amount_unit_concept_id INT NULL,
  amount_unit VARCHAR(255) NULL,
  numerator_value FLOAT NULL,
  numerator_unit_concept_id INT NULL,
  numerator_unit VARCHAR(255) NULL,
  denominator_value FLOAT NULL,
  denominator_unit_concept_id INT NULL,
  denominator_unit VARCHAR(255) NULL,
  box_size INT NULL,
  valid_start_date DATETIME NULL,
  valid_end_date DATETIME NULL,
  invalid_reason VARCHAR(1) NULL
);

INSERT INTO @cohort_database_schema.dus_h2_drug_exposure (
  ingredient,
  drug_exposure_id,
  person_id,
  drug_concept_id,
  drug_name,
  dose_form_group_concept_id,
  formulation,
  ingredient_concept_id,
  ingredient_name,
  ddd,
  drug_exposure_start_date,
  drug_exposure_end_date,
  duration,
  quantity,
  days_supply,
  sig,
  pdd,
  full_dose,
  cumulative_num_ddd,
  amount_value,
  amount_unit_concept_id,
  amount_unit,
  numerator_value,
  numerator_unit_concept_id,
  numerator_unit,
  denominator_value,
  denominator_unit_concept_id,
  denominator_unit,
  box_size,
  valid_start_date,
  valid_end_date,
  invalid_reason
)
SELECT
  ingredient,
  drug_exposure_id,
  person_id,
  drug_concept_id,
  drug_name,
  dose_form_group_concept_id,
  formulation,
  ingredient_concept_id,
  ingredient_name,
  ddd,
  drug_exposure_start_date,
  drug_exposure_end_date,
  DATEDIFF(dd, drug_exposure_start_date, drug_exposure_end_date) + 1 duration,
  quantity,
  days_supply,
  sig,
	CASE 
		WHEN amount_value > 0 AND DATEDIFF(dd, drug_exposure_start_date, drug_exposure_end_date) + 1 <> 0 
		  THEN (quantity * amount_value) / (DATEDIFF(dd, drug_exposure_start_date, drug_exposure_end_date) + 1)
		WHEN numerator_value > 0 AND DATEDIFF(dd, drug_exposure_start_date, drug_exposure_end_date) <> 0 
		  THEN (quantity * numerator_value) / (DATEDIFF(dd, drug_exposure_start_date, drug_exposure_end_date) + 1)
		ELSE 0
	END pdd,
	CASE 
		WHEN amount_value > 0 THEN quantity * amount_value
		WHEN numerator_value > 0 THEN quantity * numerator_value
		ELSE 0
	END full_dose,
	CASE 
		WHEN amount_value > 0 AND ddd <> 0
		  THEN (quantity * amount_value) / ddd
		WHEN numerator_value > 0 AND ddd <> 0
		  THEN (quantity * numerator_value) / ddd
		ELSE 0
	END cumulative_num_ddd,
  amount_value,
  amount_unit_concept_id,
  amount_unit,
  numerator_value,
  numerator_unit_concept_id,
  numerator_unit,
  denominator_value,
  denominator_unit_concept_id,
  denominator_unit,
  box_size,
  valid_start_date,
  valid_end_date,
  invalid_reason
FROM #DRUG_EXPOSURES
;

{@add_index} ? {
  -- Add an index to the drug exposure table to help with performance in the next step
  CREATE INDEX idx_dus_de_person ON @cohort_database_schema.dus_h2_drug_exposure (person_id);
  CREATE INDEX idx_dus_de_ingredient ON @cohort_database_schema.dus_h2_drug_exposure (ingredient);
  CREATE INDEX idx_dus_de_dfg ON @cohort_database_schema.dus_h2_drug_exposure (dose_form_group_concept_id);
  CREATE INDEX idx_dus_de_deid ON @cohort_database_schema.dus_h2_drug_exposure (drug_exposure_id);
  CREATE INDEX idx_dus_de_qty ON @cohort_database_schema.dus_h2_drug_exposure (quantity);
  CREATE INDEX idx_dus_de_amt ON @cohort_database_schema.dus_h2_drug_exposure (amount_unit_concept_id);
  CREATE INDEX idx_dus_de_num ON @cohort_database_schema.dus_h2_drug_exposure (numerator_unit_concept_id);
} : {}
