# Ranitidine Drug Utilization Study
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.4444771.svg)](https://doi.org/10.5281/zenodo.4444771)
## Introduction
This R package contains the resources for performing the drug utilization study of Ranitidine and other H2-receptor antagonists as described in detail in the protocol as registered at ENCePP website under registration number [EUPAS33397](http://www.encepp.eu/encepp/viewResource.htm?id=33398).

*Background*:
Ranitidine and other H2-receptor antagonists are competitive and reversible inhibitors of the action of histamine and indicated for the management of peptic ulceration, Gastro-Esophageal Reflux Disease reflux esophagitis and Zollinger-Ellison syndrome. Preliminary laboratory analyses have shown the presence of N-Nitrosodimethylamine, a human carcinogen, in ranitidine. By means of a drug utilisation study, we wanted to explore exposure characteristics of ranitidine in multiple electronic healthcare databases in Europe.

*Methods*: 
In six European electronic primary healthcare databases (IPCI-Netherlands, SIDIAP-Spain, IMRD-UK, LPD-Belgium, DA-France, DA-Germany), the incidence and prevalence of use of ranitidine and other H2-receptor antagonists over calendar time were investigated. In the cohorts of users the cumulative duration of use, its dosing and the indication were determined. Differences in duration and dosing between age and indication groups were investigated. The presence of chronic renal impairment in users were reported.

*Results*: 
In a population of almost 42 million, 1,006,319 users of ranitidine were identified resulting in an incidence of ranitidine ranging between 0.7 to 11.4/1,000 persons and a prevalence of 1.0 to 28.3/1,000 persons over all databases and over all studied calendar years. The incidence and prevalence increased with age and was higher in females than in males. The proportion of patients using ranitidine for a duration between 1-10 years was low and ranged between 6.5-18.8%. Use of ranitidine for more than 10 years was less than 4%. 

Over the six databases, the median cumulative duration of ranitidine ranged between 28 to 60 days with a median cumulative dose ranging between 8.4 and 16.8 g. Both were the highest in individuals older than 75 years. 
Of the patients with an indication of use, the majority used ranitidine for reflux disease (range over databases 71-94%). 
Results for other members of the drug class were similar.

*Conclusion*: 
The incidence and prevalence of ranitidine was low in the six European countries. Ranitidine use was highest in females and in the elderly. The proportion of patients using ranitidine for more than 10 years was less than 5% and median cumulative duration and median cumulative exposure were low

The results of the Ranitidine Study are available in an interactive [shiny application](https://mi-erasmusmc.shinyapps.io/ResultsExplorer/).

## Installation 
If you like to execute this study against your own OMOP CDM follow these instructions:

1. On Windows, make sure [RTools](http://cran.r-project.org/bin/windows/Rtools/) is installed.
2. The DatabaseConnector and SqlRender packages require Java. Java can be downloaded from
<a href="http://www.java.com" target="_blank">http://www.java.com</a>.
3. Download and open the R package using RStudio. 
4. Create the file `.Renviron` in the root of the package to hold the settings for connecting to the CDM for performing the drug utilization summary.

````
# --------------------------------
# ------ CDM CONNECTION ----------
# --------------------------------
DBMS = "postgresql"
DB_SERVER = "myserver/db"
DB_PORT = 5432
DB_USER = databaseUserName
DB_PASSWORD = superSecretPassword
CDM_SCHEMA_LIST = "CDM_1,CDM_2,CDM_3"
COHORT_SCHEMA_LIST = "CDM_1_results,CDM_2_results,CDM_3_results"
DATABASE_LIST = "CDM 1,CDM 2,CDM 3"
FFTEMP_DIR = "E:/fftemp"
````
The `CDM_SCHEMA_LIST`, `COHORT_SCHEMA_LIST`, `DATABASE_LIST` can be used to specify a list of CDM schemas to use when generating the results if required.

See the section below on Unit Testing for more information on these settings.

5. Build the package.

## Usage

The package provides functions to perform the drug utilization study.

**Refer to the `extras/runDrugUtilizationStudy.R` code in the package to see working examples for each of these.**

1.   Use the `execute` function to create the cohorts and run the study

````
  # Run study
  DrugUtilization::execute(
    connectionDetails,
    cdmDatabaseSchema = cdmDatabaseSchema,
    cohortDatabaseSchema = cohortSchema,
    cohortTable = cohortTable,
    oracleTempSchema = oracleTempSchema,
    outputFolder = outputFolder,
    databaseId = databaseName,
    databaseName = databaseName,
    createCohorts = createCohorts,
    addIndex = addIndex,
    runAnalyses = TRUE,
    createTables= TRUE,
    debug = debug,
    debugSqlFile = debugSqlFile
  )
````

The `debug` setting is used when you'd like to emit the SQL to a file vs. running it directly on your CDM.
The `addIndex` setting can be used for database management systems that allow for index creation, e.g. Postgresql. We recommend to set this to TRUE to speed up the processing considerably. Note by default this is set to FALSE!

2. Run the Shiny App for an interactive vizualisation of the results

````
  launchResultsExplorer(outputFolder)
````

Any questions please use the issue tracker.

## Unit Testing

The package provides functions to perform unit tests against a blank CDM. The unit test framework assumes you have established an empty CDM and have populated the vocabulary tables. Additionally, it is highly recommended to index the vocabulary tables when executing the unit tests.

For more information see the [unitTesting_README.md file](https://github.com/mi-erasmusmc/RanitidineStudy/blob/master/unitTesting_README.md).

## License
The Ranitidine Study packages is licensed under Apache License 2.0



