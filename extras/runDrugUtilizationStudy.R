### NEED TO BE LOADED
library(tibble)
library(dplyr)
library(readr)
library(tidyr)


# ------------------------------------------------------------------------
# Get settings and database credentials from .Renviron
# ------------------------------------------------------------------------
user <- if (Sys.getenv("DB_USER") == "") NULL else Sys.getenv("DB_USER")
password <- if (Sys.getenv("DB_PASSWORD") == "") NULL else Sys.getenv("DB_PASSWORD")
cdmDatabaseSchemaList <- as.vector(strsplit(Sys.getenv("CDM_SCHEMA_LIST"), ",")[[1]])
cohortSchemaList <- as.vector(strsplit(Sys.getenv("COHORT_SCHEMA_LIST"), ",")[[1]])
databaseList <- as.vector(strsplit(Sys.getenv("DATABASE_LIST"), ",")[[1]])
fftempdir <- if (Sys.getenv("FFTEMP_DIR") == "") "~/fftemp" else Sys.getenv("FFTEMP_DIR")
dbms = Sys.getenv("DBMS")
server = Sys.getenv("DB_SERVER")
port = Sys.getenv("DB_PORT")
outputFolder <-paste0(getwd(),"/output")
options(fftempdir = fftempdir)

if (length(cdmDatabaseSchemaList) != length(cohortSchemaList) || length(cohortSchemaList) != length(databaseList)) {
  stop("The CDM, results and database lists match in length")
}

# Connect to the server
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = password,
                                                                port = port)

## Uncomment Connect to Azure Server
#connectionString <- paste0("jdbc:sqlserver://",server,":",port,";database=",databaseList,";user=",user,";password=",password,";encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;")
#connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,connectionString = connectionString)

## Uncomment to test the connection
# connection <- DatabaseConnector::connect(dbms = dbms,connectionDetails = connectionDetails)


# ------------------------------------------------------------------------ 
# Hard-coded settings
# ------------------------------------------------------------------------

## Analysis Settings
runAnalysis <- TRUE
debug <- FALSE # Use this when you'd like to emit the SQL for debugging 
debugSqlFile <- "dus.dsql"
createCohorts <- TRUE
cohortTable <- "dus_h2_atlas_cohorts"
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

#

# ------------------------------------------------------------------------ 
# Run the diagnostics APP
# ------------------------------------------------------------------------
#CohortDiagnostics::launchDiagnosticsExplorer(dataFolder=paste0(outputFolder, "/cohortDiagnostics/export"))


# ------------------------------------------------------------------------ 
# Run the shiny APP
# ------------------------------------------------------------------------
## Premerge the diagnostic files in the outputfolder
#DrugUtilization::preMergeDiagnosticsFiles(outputFolder)

## launch the shiny application
#DrugUtilization::launchResultsExplorer(outputFolder)

