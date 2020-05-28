
/*Table 7 History of renal impairment per ingredient */

select (CASE
            WHEN ingredient = 1 THEN 'Ranitidine'
            WHEN ingredient = 2 THEN 'Cimetidine'
            WHEN ingredient = 3 THEN 'Famotidine'
            WHEN ingredient = 4 THEN 'Nizatidine'
            WHEN ingredient = 5 THEN 'Roxatidine'
            WHEN ingredient = 6 THEN 'Ranitidine bismuth citrate'
            WHEN ingredient = 7 THEN 'Lafutidine' END)   as ingredient,
       count(*)                                          as total,
       COUNT(CASE WHEN indication_365_ri > 0 THEN 1 END) as N_365_ri,
       COUNT(CASE WHEN indication_365_ri > 0 THEN 1 END) * 100.0 /
            count(*)                                     as P_365_ri
    from
       @cohortDatabaseSchema.dus_h2_cohort
    GROUP BY
       ingredient
    order by
       ingredient