### NEED TO BE LOADED
library(tibble)
library(dplyr)
library(readr)
library(tidyr)
library(ggiraph) #needed for shiny application?
library(DatabaseConnector)
library(DrugUtilization)

#install.packages('ggiraph')

# Test on Eunomia data

connectionDetails<-Eunomia::getEunomiaConnectionDetails()
conn<-connect(connectionDetails)
# Eunomia has already a table cohort, but 0 records.

Eunomia::createCohorts(connectionDetails = connectionDetails,cdmDatabaseSchema = 'main',cohortDatabaseSchema = 'main',cohortTable = 'cohort')
# Celecoxib 1844 Diclofenac 850 GiBleed 479 NSAIDs 2694
# sql created for 
# Celecoxib: 1844 Diclofenac 850

# To work with Eunomia:

cdmDatabaseSchemaList <- 'main'
cohortSchemaList <- 'main'
databaseList <- 'Eunomia'
outputFolder <-paste0(getwd(),"/output1")

# ------------------------------------------------------------------------ 
# Hard-coded settings
# ------------------------------------------------------------------------

## Analysis Settings
runAnalysis <- TRUE
debug <- FALSE # Use this when you'd like to emit the SQL for debugging 
debugSqlFile <- "dus.dsql"
createCohorts <- TRUE
cohortTable <- "MR_spec"
oracleTempSchema <- NULL
addIndex <- FALSE  # Use this for PostgreSQL and other dialects that support creating indicies
minCellCount <- 5

## Run Cohort diagnostics? Default is False
runCohortDiagnostics <- TRUE
cohortDiagnosticsInclusionStatsFolder <- file.path(outputFolder, "cohortDiagnostics/inclusionStats")
cohortDiagnosticsExportFolder <- file.path(outputFolder, "cohortDiagnostics/export")

if (!file.exists(cohortDiagnosticsInclusionStatsFolder))
  dir.create(cohortDiagnosticsInclusionStatsFolder, recursive = TRUE)

if (!file.exists(cohortDiagnosticsExportFolder))
  dir.create(cohortDiagnosticsExportFolder, recursive = TRUE)

# ------------------------------------------------------------------------ 
# Trying to run the study step by step
# ------------------------------------------------------------------------
# Run DUSAnalysis  - this contains severla function definitions.

# From DUSAnalusis, line 381

writeToCsv <- function(data, fileName) {
  colnames(data) <- SqlRender::camelCaseToSnakeCase(colnames(data))
  # write.csv(data, fileName, row.names = FALSE)
  readr::write_csv(data, fileName)
}

# From Main.R, line 108-133

packageName = "DrugUtilization"
# ---------------------------------------------------------------------
# Load created cohorts from package
pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = packageName)
cohorts <- readr::read_csv(pathToCsv, col_types = readr::cols())
cohorts$atlasId <- NULL

cohortsOfInterest <- cohorts[cohorts$cohortId < 15, ]
if ("atlasName" %in% colnames(cohorts)) {
  cohorts <- dplyr::rename(cohorts, cohortName = "name", cohortFullName = "atlasName")
} else {
  cohorts <- dplyr::rename(cohorts, cohortName = "name", cohortFullName = "fullName")
}
writeToCsv(cohorts, file.path(outputFolder, "cohort.csv"))

getSql <- function(name) {
  pathToSql <- system.file("sql", "sql_server", paste0(name, ".sql"), package = packageName)
  sql <- readChar(pathToSql, file.info(pathToSql)$size)
  return(sql)
}
cohorts$sql <- sapply(cohorts$cohortName, getSql)
getJson <- function(name) {
  pathToJson <- system.file("cohorts", paste0(name, ".json"), package = packageName)
  json <- readChar(pathToJson, file.info(pathToJson)$size)
  return(json)
}
cohorts$json <- sapply(cohorts$cohortName, getJson)

# Running createCohorts on Eunomia, without any changes from the original package:

DrugUtilization::createCohorts(connection = conn,
                               connectionDetails = connectionDetails,
                               cdmDatabaseSchema = "main",
                               cohortDatabaseSchema = "main",
                               cohortTable = cohortTable,
                               addIndex = addIndex,
                               oracleTempSchema = oracleTempSchema,
                               outputFolder = outputFolder)

querySql(conn,"select cohort_definition_id, count(*) from mr_spec group by cohort_definition_id;")
# This results in cases only in cohort 12 Gastric Or Duodenal Ulcer: 802
# Try to make the same cohort, but with different name, getting cohort settings from the local file.
# In my RanitidineStudyGitHub folder, changed:
# In inst/sql/sql_server: add MR Gastric.sql
# In inst/cohorts: add MR Gastric.json
# In inst/settings: add line in CohortsToCreate.csv: cohortId = 14, name = MR Gastric.

# Load created cohorts
# Now the cohorts to create must be read from the study folder, not the package folder
pathLocal<- "D:/Users/mderidder/Documents/R packages/RanitidineStudyGitHubDataFolder/"
pathToCsv<- paste0(pathLocal, "inst/settings/CohortsToCreate.csv")
cohorts <- readr::read_csv(pathToCsv, col_types = readr::cols())
cohorts$atlasId <- NULL

cohortsOfInterest <- cohorts[cohorts$cohortId < 15, ]
if ("atlasName" %in% colnames(cohorts)) {
  cohorts <- dplyr::rename(cohorts, cohortName = "name", cohortFullName = "atlasName")
} else {
  cohorts <- dplyr::rename(cohorts, cohortName = "name", cohortFullName = "fullName")
}
writeToCsv(cohorts, file.path(outputFolder, "cohort.csv"))

getSql <- function(name) {
  pathToSql <-  paste0(pathLocal,"inst/sql/sql_server/", paste0(name, ".sql"))
  sql <- readChar(pathToSql, file.info(pathToSql)$size)
  return(sql)
}
cohorts$sql <- sapply(cohorts$cohortName, getSql)
getJson <- function(name) {
  pathToJson <- paste0(pathLocal,"inst/cohorts/", paste0(name, ".json"))
  json <- readChar(pathToJson, file.info(pathToJson)$size)
  return(json)
}
cohorts$json <- sapply(cohorts$cohortName, getJson)

cohortTable <- "MR_spec_local"

DrugUtilization::createCohorts(connection = conn,
                               connectionDetails = connectionDetails,
                               cdmDatabaseSchema = "main",
                               cohortDatabaseSchema = "main",
                               cohortTable = cohortTable,
                               addIndex = addIndex,
                               oracleTempSchema = oracleTempSchema,
                               outputFolder = outputFolder)

querySql(conn,"select cohort_definition_id, count(*) from mr_spec_local group by cohort_definition_id;")

# Werkt! Maar: omdat ik wijzigingen had aangebracht in CreateCohorts.R, daarna opnieuw gebuild.
# De MR Gastric files maken nu ook deel uit van het pakket.
# Een poging zonder:

# MR Gastric.sql en .json weggehaald uit pakket.
# Regel in CohortsToCreate.csv daar er wer uitgehaald.
# De inst folder van RantidineStudyGitHub gekopieerd naar RantidineStudyGitHubDataFolder
# In RantidineStudyGitHub inst folder de MR Gastric specifieke zaken weer weggehaald








############################################


# Error in readChar(pathToJson, file.info(pathToJson)$size) : 
#   invalid 'nchars' argument
# In addition: Warning messages:
#   1: In file(con, "rb") :
#   file("") only supports open = "w+" and open = "w+b": using the former
# 2: In readChar(pathToJson, file.info(pathToJson)$size) :
#   text connection used with readChar(), results may be incorrect

# This seems to be related to non-existing Celecoxib.json/ Diclofenac.json. The 'json files' fro Ranitidine etc. are created Feb 15 2022.

# # Create a table with GI bleed patients, start at start GI bleed, end at observation_period_end_date.

dbExecute(conn,"create table test as
  select  o.observation_period_id, o.person_id, c.cohort_start_date as observation_period_start_date, o.observation_period_end_date, o.period_type_concept_id 
  from (select * from cohort where cohort_definition_id = 3) as c
  left join
  (select * from observation_period) as o
  where c.subject_id = o.person_id;")

# Celecoxib users should be selected from this test table only

DrugUtilization::createCohorts(connection = conn,
              connectionDetails = connectionDetails,
              cdmDatabaseSchema = "main",
              cohortDatabaseSchema = "main",
              cohortTable = cohortTable,
              addIndex = addIndex,
              oracleTempSchema = oracleTempSchema,
              outputFolder = outputFolder)

querySql(conn,"select cohort_definition_id, count(*) from mr_spec group by cohort_definition_id;")
# Using total Eunomia: 1. Celecoxib: 1800, 2. Diclofenac: 830, 12 Gastric Or Duodenal Ulcer 802
# Using for Celecoxib only 'test': Celecoxib empty 

querySql(conn,"select min(subject_id) from mr_spec where cohort_definition_id = 12 ;")

querySql(conn,"select * from mr_spec where cohort_definition_id = 1 and subject_id < 30;")

querySql(conn,"select cohort_definition_id, count(*) as Nrecords, count(distinct subject_id) as Nsubj from mr_spec group by cohort_definition_id;")
# Every subject only once.

querySql(conn,"select count(*) as EqualDates from mr_spec where cohort_definition_id = 12 and cohort_start_date=cohort_end_date ;")
#  In this Gastric Or Duodenal Ulcer cohort, all cohort_start_date=cohort_end_date

# Create a table with Gastric Or Duodenal Ulcer patients, start at start Gastric, end at observation_period_end_date.

dbExecute(conn,"DROP TABLE main.test");

dbExecute(conn,"create table test as
  select  o.observation_period_id, o.person_id, c.cohort_start_date as observation_period_start_date, o.observation_period_end_date, o.period_type_concept_id 
  from (select * from mr_spec where cohort_definition_id = 12) as c
  left join
  (select * from observation_period) as o
  where c.subject_id = o.person_id;")

# select o.observation_period_id, o.person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id



# ------------------------------------------------------------------------ 
# Run the study
# ------------------------------------------------------------------------

for (sourceId in 1:length(cdmDatabaseSchemaList)) {
  cdmDatabaseSchema <- cdmDatabaseSchemaList[sourceId]
  cohortDatabaseSchema <- cohortSchemaList[sourceId]
  databaseName <- databaseList[sourceId]
  databaseId <- databaseName
  databaseDescription <- databaseName
  
  print(paste("Executing against", databaseName))
  
  if (runAnalysis) {
    # Run analysis
    DrugUtilization::execute(
      connectionDetails = connectionDetails,
      cdmDatabaseSchema = cdmDatabaseSchema,
      cohortDatabaseSchema = cohortDatabaseSchema,
      cohortTable = cohortTable,
      #oracleTempSchema = oracleTempSchema,
      outputFolder = outputFolder,
      databaseId = databaseId,
      databaseName = databaseName,
      createCohorts = createCohorts,
      addIndex = addIndex,
      runAnalyses = TRUE,
      createTables= TRUE,
      debug = debug,
      debugSqlFile = debugSqlFile
    )
  }
  
  if (runCohortDiagnostics) {
    CohortDiagnostics::runCohortDiagnostics(packageName = "DrugUtilization",
                                            cohortToCreateFile = "settings/CohortsToDiagnose.csv",
                                            connectionDetails = connectionDetails,
                                            cdmDatabaseSchema = cdmDatabaseSchema,
                                            #oracleTempSchema = oracleTempSchema,
                                            cohortDatabaseSchema = cohortDatabaseSchema,
                                            cohortTable = cohortTable,
                                            inclusionStatisticsFolder = cohortDiagnosticsInclusionStatsFolder,
                                            exportFolder = cohortDiagnosticsExportFolder,
                                            databaseId = databaseId,
                                            databaseName = databaseName,
                                            databaseDescription = databaseDescription,
                                            runInclusionStatistics = FALSE,
                                            runIncludedSourceConcepts = TRUE,
                                            runOrphanConcepts = TRUE,
                                            runTimeDistributions = TRUE,
                                            runBreakdownIndexEvents = TRUE,
                                            runIncidenceRate = TRUE,
                                            runCohortOverlap = TRUE,
                                            runCohortCharacterization = TRUE,
                                            minCellCount = minCellCount)
    
  }
}

# Only cohort 12 is created: gastric ulcer ..... N = 802
# The drugs are not present in Eunomia?
DrugUtilization::createCohorts(outputFolder = outputFolder,
                               connectionDetails = connectionDetails,
                               cdmDatabaseSchema = cdmDatabaseSchema,
                               cohortDatabaseSchema = cohortDatabaseSchema,
                               cohortTable = cohortTable)




# ------------------------------------------------------------------------ 
# Run the diagnostics APP
# ------------------------------------------------------------------------
# CohortDiagnostics::launchDiagnosticsExplorer(dataFolder=paste0(outputFolder, "/cohortDiagnostics/export"))


# ------------------------------------------------------------------------ 
# Run the shiny APP
# ------------------------------------------------------------------------
## Premerge the diagnostic files in the outputfolder
#DrugUtilization::preMergeDiagnosticsFiles(outputFolder)

#install.packages('ggiraph')

## launch the shiny application
DrugUtilization::launchResultsExplorer(outputFolder)

