# Ranitidine Drug Utilization Study

## Introduction
This R package contains the resources for performing the drug utilization study of Ranitidine.

## Results
The results of the Ranitidine report for the European Medicine Agency are presented in the interactive shiny application  [HERE](https://mi-erasmusmc.shinyapps.io/ResultsExplorer/).

## Installation 
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

## Unit Testing

The package provides functions to perform unit tests against a blank CDM. The unit test framework assumes you have established an empty CDM and have populated the vocabulary tables. Additionally, it is highly recommended to index the vocabulary tables when executing the unit tests.

For more information see the [unitTesting_README.md file](https://github.com/mi-erasmusmc/RanitidineStudy/unitTesting_README.md).

