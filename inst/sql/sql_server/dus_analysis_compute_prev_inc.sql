
---------------------------------------------------------
-- Compute prevalence and incidence numerator/denominator
---------------------------------------------------------

-- Prevalence numerator - all exposures
SELECT 
	cy.calendar_year,
	eoi1.ingredient,
	CASE WHEN eoi1.ingredient < 9 THEN eoi1.ingredient_name ELSE 'H2 inhibitors' END ingredient_name,
	p.gender_concept_id,
	FLOOR((cy.calendar_year - p.year_of_birth)/10) AS age_group,
	COUNT(DISTINCT eoi1.person_id) as num_persons
INTO #NUMERATOR_PREV
FROM @cohort_database_schema.dus_h2_drug_exposure eoi1
INNER JOIN @cdm_person_schema.@person_table p ON eoi1.person_id = p.person_id
INNER JOIN #CALENDAR_YEARS cy ON YEAR(eoi1.drug_exposure_start_date) <= cy.calendar_year
  AND YEAR(eoi1.drug_exposure_end_date) >= cy.calendar_year
GROUP BY 
	cy.calendar_year,
	eoi1.ingredient,
	CASE WHEN eoi1.ingredient < 9 THEN eoi1.ingredient_name ELSE 'H2 inhibitors' END,
	p.gender_concept_id,
	FLOOR((cy.calendar_year - p.year_of_birth)/10)
;

-- Prevalence numerator - all exposures without age group
SELECT 
	cy.calendar_year,
	eoi1.ingredient,
	CASE WHEN eoi1.ingredient < 9 THEN eoi1.ingredient_name ELSE 'H2 inhibitors' END ingredient_name,
	p.gender_concept_id,
	COUNT(DISTINCT eoi1.person_id) as num_persons
INTO #NUMERATOR_PREV_UNIQ
FROM @cohort_database_schema.dus_h2_drug_exposure eoi1
INNER JOIN @cdm_person_schema.@person_table p ON eoi1.person_id = p.person_id
INNER JOIN #CALENDAR_YEARS cy ON YEAR(eoi1.drug_exposure_start_date) <= cy.calendar_year
  AND YEAR(eoi1.drug_exposure_end_date) >= cy.calendar_year
GROUP BY 
	cy.calendar_year,
	eoi1.ingredient,
	CASE WHEN eoi1.ingredient < 9 THEN eoi1.ingredient_name ELSE 'H2 inhibitors' END,
	p.gender_concept_id
;

-- Incidence numerator - 365d washout exposures
SELECT 
	cy.calendar_year,
	eoi1.ingredient,
	CASE WHEN eoi1.ingredient < 9 THEN eoi1.ingredient_name ELSE 'H2 inhibitors' END ingredient_name,
	p.gender_concept_id,
	FLOOR((cy.calendar_year - p.year_of_birth)/10) AS age_group,
	COUNT(DISTINCT eoi1.person_id) as num_persons
INTO #NUMERATOR_INC
FROM @cohort_database_schema.@cohort_table c
INNER JOIN @cdm_person_schema.@person_table p ON c.subject_id = p.person_id
INNER JOIN @cohort_database_schema.dus_h2_drug_exposure eoi1 ON c.subject_id = eoi1.person_id
  -- The ingredient ID is the cohort ID and c.cohort_definition_id - 20 
  -- allows us to map between the 365d cohort.
  AND (c.cohort_definition_id - 20) = eoi1.ingredient 
  AND c.cohort_start_date = eoi1.drug_exposure_start_date
INNER JOIN #CALENDAR_YEARS cy ON YEAR(eoi1.drug_exposure_start_date) <= cy.calendar_year
  AND YEAR(eoi1.drug_exposure_end_date) >= cy.calendar_year
WHERE c.cohort_definition_id >= 21 and c.cohort_definition_id <= 29 -- Based on the CohortsToCreate.csv
GROUP BY 
	cy.calendar_year,
	eoi1.ingredient,
	CASE WHEN eoi1.ingredient < 9 THEN eoi1.ingredient_name ELSE 'H2 inhibitors' END,
	p.gender_concept_id,
	FLOOR((cy.calendar_year - p.year_of_birth)/10)
;

-- Incidence numerator - 365d washout exposures without age group
SELECT 
	cy.calendar_year,
	eoi1.ingredient,
	CASE WHEN eoi1.ingredient < 9 THEN eoi1.ingredient_name ELSE 'H2 inhibitors' END ingredient_name,
	p.gender_concept_id,
	COUNT(DISTINCT eoi1.person_id) as num_persons
INTO #NUMERATOR_INC_UNIQ
FROM @cohort_database_schema.@cohort_table c
INNER JOIN @cdm_person_schema.@person_table p ON c.subject_id = p.person_id
INNER JOIN @cohort_database_schema.dus_h2_drug_exposure eoi1 ON c.subject_id = eoi1.person_id
  -- The ingredient ID is the cohort ID and c.cohort_definition_id - 20 
  -- allows us to map between the 365d cohort.
  AND (c.cohort_definition_id - 20) = eoi1.ingredient 
  AND c.cohort_start_date = eoi1.drug_exposure_start_date
INNER JOIN #CALENDAR_YEARS cy ON YEAR(eoi1.drug_exposure_start_date) <= cy.calendar_year
  AND YEAR(eoi1.drug_exposure_end_date) >= cy.calendar_year
WHERE c.cohort_definition_id >= 21 and c.cohort_definition_id <= 29 -- Based on the CohortsToCreate.csv
GROUP BY 
	cy.calendar_year,
	eoi1.ingredient,
	CASE WHEN eoi1.ingredient < 9 THEN eoi1.ingredient_name ELSE 'H2 inhibitors' END,
	p.gender_concept_id
;

IF OBJECT_ID('@cohort_database_schema.dus_h2_numerator', 'U') IS NOT NULL DROP TABLE @cohort_database_schema.dus_h2_numerator;

CREATE TABLE @cohort_database_schema.dus_h2_numerator (
  numerator_type VARCHAR(50) NOT NULL,
  calendar_year INT NOT NULL,
  ingredient INT NOT NULL,
  ingredient_name VARCHAR(255) NOT NULL,
  gender_concept_id INT NOT NULL,
  age_group INT NOT NULL,
  num_persons BIGINT NOT NULL
);

-- Save the numerators
INSERT INTO @cohort_database_schema.dus_h2_numerator (
  numerator_type,
  calendar_year,
  ingredient,
  ingredient_name,
  gender_concept_id,
  age_group,
  num_persons
)
SELECT 
  'prevalence',
	noi1.calendar_year,
	noi1.ingredient,
	noi1.ingredient_name,
	noi1.gender_concept_id,
	noi1.age_group,
	num_persons
FROM #NUMERATOR_PREV noi1
UNION ALL
SELECT 
  'prevalence_unique',
	npu.calendar_year,
	npu.ingredient,
	npu.ingredient_name,
	npu.gender_concept_id,
	CAST(0 as int) age_group,
	num_persons
FROM #NUMERATOR_PREV_UNIQ npu
UNION ALL
SELECT 
  'incidence',
	noi1.calendar_year,
	noi1.ingredient,
	noi1.ingredient_name,
	noi1.gender_concept_id,
	noi1.age_group,
	num_persons
FROM #NUMERATOR_INC noi1
UNION ALL
SELECT 
  'incidence_unique',
	calendar_year,
	ingredient,
	ingredient_name,
	gender_concept_id,
	CAST(0 as int) age_group,
	num_persons
FROM #NUMERATOR_INC_UNIQ
;

-- Taken from: https://github.com/OHDSI/Achilles/blob/master/inst/sql/sql_server/analyses/116.sql
-- and adapted for this study
-----------------------------------------------------------------------------------------------------------
-- 116	Number of persons with at least one day of observation in each year by gender and age decile
-- Note: using temp table instead of nested query because this gives vastly improved performance in Oracle

--HINT DISTRIBUTE_ON_KEY(stratum_1)
WITH rawData AS (
  select
    t1.calendar_year as stratum_1,
    p1.gender_concept_id as stratum_2,
    floor((t1.calendar_year - p1.year_of_birth)/10) as stratum_3,
    COUNT_BIG(distinct p1.PERSON_ID) as count_value
  from
    @cdm_person_schema.@person_table p1
    inner join
    @cdm_observation_period_schema.@observation_period_table op1
    on p1.person_id = op1.person_id
    ,
    #CALENDAR_YEARS t1
  where year(op1.OBSERVATION_PERIOD_START_DATE) <= t1.calendar_year
    and year(op1.OBSERVATION_PERIOD_END_DATE) >= t1.calendar_year
  group by t1.calendar_year,
    p1.gender_concept_id,
    floor((t1.calendar_year - p1.year_of_birth)/10)
)
SELECT
  116 as analysis_id,
  stratum_1,
  stratum_2,
  stratum_3,
  count_value
into #ach_analysis_116
FROM rawData;

-- Get the denominator without the age groups
--HINT DISTRIBUTE_ON_KEY(stratum_1)
WITH rawData AS (
  select
    t1.calendar_year as stratum_1,
    p1.gender_concept_id as stratum_2,
    COUNT_BIG(distinct p1.PERSON_ID) as count_value
  from
    @cdm_person_schema.@person_table p1
    inner join
    @cdm_observation_period_schema.@observation_period_table op1
    on p1.person_id = op1.person_id
    ,
    #CALENDAR_YEARS t1
  where year(op1.OBSERVATION_PERIOD_START_DATE) <= t1.calendar_year
    and year(op1.OBSERVATION_PERIOD_END_DATE) >= t1.calendar_year
  group by t1.calendar_year,
    p1.gender_concept_id
)
SELECT
  stratum_1,
  stratum_2,
  count_value
into #denom_unique
FROM rawData;

IF OBJECT_ID('@cohort_database_schema.dus_h2_denominator', 'U') IS NOT NULL DROP TABLE @cohort_database_schema.dus_h2_denominator;

CREATE TABLE @cohort_database_schema.dus_h2_denominator (
  denominator_type VARCHAR(50) NOT NULL,
  calendar_year INT NOT NULL,
  gender_concept_id INT NOT NULL,
  age_group INT NOT NULL,
  num_persons BIGINT NOT NULL
);

INSERT INTO @cohort_database_schema.dus_h2_denominator (
  denominator_type,
  calendar_year,
  gender_concept_id,
  age_group,
  num_persons
)
SELECT
  'denominator',
  stratum_1 calendar_year,
  stratum_2 gender_concept_id,
	stratum_3 age_group,
  count_value denom_persons
FROM #ach_analysis_116
UNION ALL
SELECT
  'denominator_unique',
  stratum_1,
  stratum_2,
  CAST(0 as int) stratum_3,
  count_value
FROM #denom_unique
;

-----------------------------------------------------------------------------------------------------------