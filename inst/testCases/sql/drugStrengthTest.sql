TRUNCATE TABLE @cdm_database_schema.PERSON;
TRUNCATE TABLE @cdm_database_schema.DRUG_EXPOSURE;
TRUNCATE TABLE @cdm_database_schema.OBSERVATION_PERIOD;
TRUNCATE TABLE @cdm_database_schema.CONDITION_OCCURRENCE;

 -- TEST:  drugStrengthTest.json
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 1, 8532, 1980, 0, 0, NULL;
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 2, 8507, 1995, 0, 0, NULL;
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 3, 8532, 1965, 0, 0, 'Patient 1 - 2 Oral Rad/1 Rad Unspc';
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 4, 8507, 1955, 0, 0, 'Patient B - 2 Rad/1 Cim';
INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT 5, 8532, 1965, 0, 0, 'Patient A - 3 Oral Rad';
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 1, 1, '2000-01-01', '2002-01-01', 0;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 2, 2, '1995-01-01', '2002-01-01', 0;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 3, 3, '2010-01-01', '2019-12-31', 0;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 4, 4, '2010-01-01', '2014-12-31', 0;
INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT 5, 5, '2010-01-01', '2019-12-31', 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 1, 1, 19126405, '2000-01-01', '2000-02-29', 60, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 2, 2, 40852223, '1995-01-01', '1995-01-30', 30, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 3, 3, 40852223, '2010-07-01', '2010-08-29', 60, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 4, 3, 40852223, '2010-08-31', '2010-09-29', 30, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 5, 3, 41046317, '2015-02-01', '2015-04-01', 60, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 6, 4, 40852223, '2010-07-01', '2010-08-29', 60, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 7, 4, 40852223, '2010-09-15', '2010-10-14', 30, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 8, 4, 40918311, '2011-01-01', '2011-03-31', 90, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 9, 5, 40852223, '2010-07-01', '2010-08-29', 60, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 10, 5, 40852223, '2010-08-31', '2010-09-29', 30, 0;
INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT 11, 5, 35748636, '2015-02-01', '2015-04-01', 60, 0;