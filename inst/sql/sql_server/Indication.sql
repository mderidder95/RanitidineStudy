
/* Table 6 Indication of use per ingredient per age strata*/

select (CASE
            WHEN results.ingredient = 1 THEN 'Ranitidine'
            WHEN results.ingredient = 2 THEN 'Cimetidine'
            WHEN results.ingredient = 3 THEN 'Famotidine'
            WHEN results.ingredient = 4 THEN 'Nizatidine'
            WHEN results.ingredient = 5 THEN 'Roxatidine'
            WHEN results.ingredient = 6 THEN 'Ranitidine bismuth citrate'
            WHEN results.ingredient = 7 THEN 'Lafutidine' 
            WHEN results.ingredient = 8 THEN 'Niperotidine'
            WHEN results.ingredient = 9 THEN 'H2 Class' END) as ingredient,
       (CASE
            WHEN STRATUM_ORDER = 1 THEN '0-<18'
            WHEN STRATUM_ORDER = 2 THEN '18-75'
            WHEN STRATUM_ORDER = 3 THEN '>=75' END)            as age_stratum,
       count(*)                                                as total,
       COUNT(CASE WHEN indication_180_gerd > 0 THEN 1 END)     as N_180_gerd,
       COUNT(CASE WHEN indication_180_gerd > 0 THEN 1 END) * 100.0 /
       count(*)                                                as P_180_gerd,
       COUNT(CASE WHEN indication_365_gerd > 0 THEN 1 END)     as N_365_gerd,
       COUNT(CASE WHEN indication_365_gerd > 0 THEN 1 END) * 100.0 /
       count(*)                                                as P_365_gerd,
       COUNT(CASE WHEN indication_180_ulcer > 0 THEN 1 END)    as N_180_ulcer,
       COUNT(CASE WHEN indication_180_ulcer > 0 THEN 1 END) * 100.0 /
       count(*)                                                as P_180_ulcer,
       COUNT(CASE WHEN indication_365_ulcer > 0 THEN 1 END)    as N_365_ulcer,
       COUNT(CASE WHEN indication_365_ulcer > 0 THEN 1 END) * 100.0 /
       count(*)                                                as P_365_ulcer,
       COUNT(CASE WHEN indication_180_zes > 0 THEN 1 END)      as N_180_zes,
       COUNT(CASE WHEN indication_180_zes > 0 THEN 1 END) * 100.0 /
       count(*)                                                as P_180_zes,
       COUNT(CASE WHEN indication_365_zes > 0 THEN 1 END)      as N_365_zes,
       COUNT(CASE WHEN indication_365_zes > 0 THEN 1 END) * 100.0 /
       count(*)                                                as P_365_zes
    FROM
       @cohort_database_schema.dus_h2_cohort a
    LEFT JOIN
    (select person_id, ingredient,
    CASE
        WHEN age < 18 THEN 1
        WHEN age >= 18 and age < 75 THEN 2
        WHEN age >= 75 THEN 3 END as STRATUM_ORDER
    from
       @cohort_database_schema.dus_h2_cohort) as results
    ON results.person_id = a.person_id and results.ingredient = a.ingredient
    GROUP BY
       results.ingredient,
       results.STRATUM_ORDER
    ORDER BY
       results.ingredient,
       results.STRATUM_ORDER
    ;