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
runCohortDiagnostics <- FALSE
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
# Using total Eunomia: 1. Celecoxib: 1800, 2. Diclofenac: 830, 12 Gastric Or Duodenal Ulcer 802


loadRenderTranslateSql <- function(connection, sqlFileInPackage, oracleTempSchema, ...) {
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = sqlFileInPackage,
                                           packageName = "DrugUtilization",
                                           dbms = attr(connection, "dbms"),
                                           warnOnMissingParameters = TRUE,
                                           #oracleTempSchema = oracleTempSchema,
                                           ...)
  return (sql)
}

dusAnalysis(connection = conn,
            connectionDetails = connectionDetails,
            cdmDatabaseSchema = "main",
            cohortDatabaseSchema = "main",
            cohortTable = cohortTable,
            #oracleTempSchema = oracleTempSchema,
            debug = debug,
            outputFolder = outputFolder,
            debugSqlFile = debugSqlFile, 
            databaseId = databaseId,
            databaseName = databaseName,
            addIndex = addIndex,
            selfManageTempTables = TRUE,
            vocabularyDatabaseSchema= "main",
            cdmDrugExposureSchema= "main",
            drugExposureTable = "drug_exposure",
            cdmObservationPeriodSchema= "main",
            observationPeriodTable = "observation_period",
            cdmPersonSchema= "main",
            personTable = "person")





# ------------------------------------------------------------------------ 
# Run the study
# ------------------------------------------------------------------------

oracleTempSchema <- cohortDatabaseSchema


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
      oracleTempSchema = oracleTempSchema,
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
                                            oracleTempSchema = oracleTempSchema,
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

