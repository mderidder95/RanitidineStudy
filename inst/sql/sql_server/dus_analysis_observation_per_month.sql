-- Taken from: https://github.com/OHDSI/Achilles/blob/master/inst/sql/sql_server/analyses/110.sql
-- and adapted for this study
-----------------------------------------------------------------------------------------------------------
-- 110	Number of persons with continuous observation in each month

IF OBJECT_ID('@cohort_database_schema.dus_h2_obs_per_month', 'U') IS NOT NULL DROP TABLE @cohort_database_schema.dus_h2_obs_per_month;

CREATE TABLE @cohort_database_schema.dus_h2_obs_per_month (
  obs_year_month INT NOT NULL,
  num_persons BIGINT NOT NULL
);

INSERT INTO @cohort_database_schema.dus_h2_obs_per_month (
  obs_year_month,
  num_persons
)
SELECT
	t1.obs_month obs_month_year,
	COUNT_BIG(distinct op1.PERSON_ID) as num_persons
FROM @cdm_observation_period_schema.@observation_period_table op1
join 
(
  SELECT DISTINCT 
    YEAR(observation_period_start_date)*100 + MONTH(observation_period_start_date) AS obs_month,
    DATEFROMPARTS(YEAR(observation_period_start_date), MONTH(observation_period_start_date), 1)
    AS obs_month_start,
    EOMONTH(observation_period_start_date) AS obs_month_end
  FROM @cdm_observation_period_schema.@observation_period_table
) t1 on	op1.observation_period_start_date <= t1.obs_month_start
	and	op1.observation_period_end_date >= t1.obs_month_end
group by t1.obs_month
;