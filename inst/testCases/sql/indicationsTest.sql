TRUNCATE TABLE @cdm_database_schema.PERSON;
TRUNCATE TABLE @cdm_database_schema.DRUG_EXPOSURE;
TRUNCATE TABLE @cdm_database_schema.OBSERVATION_PERIOD;
TRUNCATE TABLE @cdm_database_schema.CONDITION_OCCURRENCE;

 -- TEST:  indicationsTest.json
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 1, 8532, 1980, 0, 0, NULL;
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 2, 8507, 1980, 0, 0, NULL;
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 3, 8532, 1975, 0, 0, NULL;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 1, 1, '2000-01-01', '2002-01-01', 0;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 2, 2, '2000-01-01', '2002-01-01', 0;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 3, 3, '2000-01-01', '2002-01-01', 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 1, 1, 40852223, '2001-01-01', '2001-01-31', 30, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 2, 2, 40852223, '2000-01-01', '2000-01-31', 30, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 3, 3, 40852223, '2000-01-01', '2000-01-31', 30, 0;
INSERT INTO @cdm_database_schema.CONDITION_OCCURRENCE (condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_type_concept_id, condition_status_concept_id, condition_source_concept_id) 
                  SELECT 1, 1, 443919, '2000-06-01', 0, 0, 0;
INSERT INTO @cdm_database_schema.CONDITION_OCCURRENCE (condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_type_concept_id, condition_status_concept_id, condition_source_concept_id) 
                  SELECT 2, 2, 443919, '1999-06-01', 0, 0, 0;
INSERT INTO @cdm_database_schema.CONDITION_OCCURRENCE (condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_type_concept_id, condition_status_concept_id, condition_source_concept_id) 
                  SELECT 3, 3, 4200399, '1999-07-05', 0, 0, 0;
INSERT INTO @cdm_database_schema.CONDITION_OCCURRENCE (condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_type_concept_id, condition_status_concept_id, condition_source_concept_id) 
                  SELECT 4, 3, 4200399, '1999-03-01', 0, 0, 0;
INSERT INTO @cdm_database_schema.CONDITION_OCCURRENCE (condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_type_concept_id, condition_status_concept_id, condition_source_concept_id) 
                  SELECT 5, 3, 4200399, '1995-06-01', 0, 0, 0;