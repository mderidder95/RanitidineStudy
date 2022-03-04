CREATE TABLE #COHORT_DDD_XREF (
  cohort_id int NOT NULL,
  ddd INT NOT NULL,
  ingredient_concept_id bigint NOT NULL,
  drug_concept_id bigint NOT NULL
)
;

-- Ranitidine excluding 400MG Ranitidine Bismuth Citrate 
INSERT INTO #COHORT_DDD_XREF (cohort_id, ddd, ingredient_concept_id, drug_concept_id)
SELECT 1 as cohort_id, 300 ddd, 961047 ingredient_concept_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (961047)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (961047)
  and c.invalid_reason is null

) I
LEFT JOIN
(
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (19084587)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (19084587)
  and c.invalid_reason is null

) E ON I.concept_id = E.concept_id
WHERE E.concept_id is null
) C;

-- Cimetidine
INSERT INTO #COHORT_DDD_XREF (cohort_id, ddd, ingredient_concept_id, drug_concept_id)
SELECT 2 as cohort_id, 800 ddd, 997276 ingredient_concept_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (997276)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (997276)
  and c.invalid_reason is null

) I
) C;

-- Famotidin 
INSERT INTO #COHORT_DDD_XREF (cohort_id, ddd, ingredient_concept_id, drug_concept_id)
SELECT 3 as cohort_id, 40 ddd, 953076 ingredient_concept_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (953076)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (953076)
  and c.invalid_reason is null

) I
) C;

-- Nizatidine
INSERT INTO #COHORT_DDD_XREF (cohort_id, ddd, ingredient_concept_id, drug_concept_id)
SELECT 4 as cohort_id, 300 ddd, 950696 ingredient_concept_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (950696)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (950696)
  and c.invalid_reason is null

) I
) C;

-- Roxatidine
INSERT INTO #COHORT_DDD_XREF (cohort_id, ddd, ingredient_concept_id, drug_concept_id)
SELECT 5 as cohort_id, 150 ddd, 19011685 ingredient_concept_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (19011685)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (19011685)
  and c.invalid_reason is null

) I
) C;

-- Ranitidine bismuth citrate
INSERT INTO #COHORT_DDD_XREF (cohort_id, ddd, ingredient_concept_id, drug_concept_id)
SELECT 6 as cohort_id, 800 ddd, 961047 ingredient_concept_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (19084587)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (19084587)
  and c.invalid_reason is null

) I
) C;

-- Lafutidine
INSERT INTO #COHORT_DDD_XREF (cohort_id, ddd, ingredient_concept_id, drug_concept_id)
SELECT 7 as cohort_id, 800 ddd, 43009003 ingredient_concept_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (21600089,43009003)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (21600089,43009003)
  and c.invalid_reason is null

) I
) C;

-- Niperotidine
INSERT INTO #COHORT_DDD_XREF (cohort_id, ddd, ingredient_concept_id, drug_concept_id)
SELECT 8 as cohort_id, 0 ddd, 21600086 ingredient_concept_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (21600086)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (21600086)
  and c.invalid_reason is null

) I
) C;

-- Full class
INSERT INTO #COHORT_DDD_XREF (cohort_id, ddd, ingredient_concept_id, drug_concept_id)
SELECT 9, ddd, ingredient_concept_id, drug_concept_id
FROM #COHORT_DDD_XREF
;

-- Create a temp table with the drug_unit_concept_ids
-- for use later so that we don't hit the entire vocab concept table
--HINT DISTRIBUTE_ON_KEY(concept_id)
WITH drug_unit_concept_ids AS (
  SELECT DISTINCT amount_unit_concept_id unit_concept_id FROM @vocabulary_database_schema.drug_strength
  UNION ALL
  SELECT DISTINCT numerator_unit_concept_id unit_concept_id FROM @vocabulary_database_schema.drug_strength
  UNION ALL
  SELECT DISTINCT denominator_unit_concept_id unit_concept_id FROM @vocabulary_database_schema.drug_strength
)
SELECT c.concept_id, c.concept_name
INTO #UNIT_CONCEPTS
FROM drug_unit_concept_ids duci
INNER JOIN @vocabulary_database_schema.concept c ON duci.unit_concept_id = c.concept_id
;


-- Concepts in this table will be given priority
-- when finding dose formualtion
CREATE TABLE #DOSE_FORM_GROUP (
  dose_form_group_concept_id  BIGINT     NOT NULL
)
;

INSERT INTO #DOSE_FORM_GROUP ( 
  dose_form_group_concept_id
)
SELECT 36217214	-- Oral Product
UNION ALL
SELECT 36217206	-- Topical Product
UNION ALL
SELECT 36217207	-- Inhalant Product
UNION ALL
SELECT 36217215	-- Dental Product
UNION ALL
SELECT 36217209	--Vaginal Product
;

-- Get the dose form and dose form group
WITH all_dose_form as (
  SELECT 
  	ci.drug_concept_id,
  	ISNULL(cr.concept_id_2, 0) dose_form_concept_id,
  	ISNULL(c.concept_id, 0) dose_form_group_concept_id,
  	CASE
  		WHEN dfg.dose_form_group_concept_id IS NOT NULL THEN 2
  		WHEN c.concept_id IS NOT NULL THEN 1
  		ELSE 0
  	END dfg_priority
  FROM (SELECT DISTINCT drug_concept_id FROM #COHORT_DDD_XREF) ci 
  LEFT JOIN @vocabulary_database_schema.concept_relationship cr
      ON cr.concept_id_1 = ci.drug_concept_id
  	AND cr.relationship_id = 'RxNorm has dose form'
  LEFT JOIN @vocabulary_database_schema.concept_relationship cr2
      ON cr.concept_id_2 = cr2.concept_id_1
  	AND cr2.relationship_id = 'RxNorm is a'
  LEFT JOIN @vocabulary_database_schema.concept c 
  	ON c.concept_id = cr2.concept_id_2
      AND c.concept_class_id = 'Dose Form Group'
  LEFT JOIN #DOSE_FORM_GROUP dfg 
    ON c.concept_id = dfg.dose_form_group_concept_id
), dfPrioritized AS (
  SELECT
    drug_concept_id,
    dose_form_concept_id,
    dose_form_group_concept_id,
    row_number() over (PARTITION BY drug_concept_id ORDER BY dfg_priority DESC) ordinal
  FROM all_dose_form
)
SELECT 
    drug_concept_id,
    dose_form_concept_id,
    dose_form_group_concept_id
INTO #DFG_PRIORITIZED
FROM dfPrioritized
WHERE ordinal = 1
;
