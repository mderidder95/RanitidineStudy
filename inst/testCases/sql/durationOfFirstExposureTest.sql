TRUNCATE TABLE @cdm_database_schema.PERSON;
TRUNCATE TABLE @cdm_database_schema.DRUG_EXPOSURE;
TRUNCATE TABLE @cdm_database_schema.OBSERVATION_PERIOD;
TRUNCATE TABLE @cdm_database_schema.CONDITION_OCCURRENCE;

 -- TEST:  durationOfFirstExposureTest.json
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 1, 8532, 1999, 0, 0, NULL;
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 2, 8507, 1995, 0, 0, NULL;
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 3, 8532, 1986, 0, 0, NULL;
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 4, 8507, 1978, 0, 0, NULL;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 1, 1, '2000-01-01', '2001-01-01', 0;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 2, 2, '2000-01-01', '2001-01-01', 0;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 3, 3, '2000-01-01', '2006-01-01', 0;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 4, 4, '2000-01-01', '2011-01-01', 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 1, 1, 40852223, '2000-01-01', '2000-01-01', 30, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 2, 2, 40852223, '2000-01-01', '2000-01-31', 30, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 3, 3, 40852223, '2000-01-01', '2001-01-31', 30, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 4, 4, 40852223, '2000-01-01', '2010-01-31', 30, 0;