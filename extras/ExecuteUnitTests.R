library(tibble)
library(dplyr)
library(readr)
library(tidyr)

pathToTestCaseSql <- file.path(Sys.getenv("UT_TEST_CASES_FILE_LOCATION"), "sql")
unitTestOutputFolder <- Sys.getenv("UT_TEST_CASES_RESULTS_LOCATION")
# Initialize the output path - careful, this will automatically remove prior results!
if (dir.exists(unitTestOutputFolder)) {
  unlink(unitTestOutputFolder, recursive = TRUE)
}
dir.create(unitTestOutputFolder)

# ------------------------------------------------------------------------
# Get settings from .Renviron
# ------------------------------------------------------------------------
user <- if (Sys.getenv("UT_DB_USER") == "") NULL else Sys.getenv("UT_DB_USER")
password <- if (Sys.getenv("UT_DB_PASSWORD") == "") NULL else Sys.getenv("UT_DB_PASSWORD")
cdmDatabaseSchema <- Sys.getenv("UT_CDM_SCHEMA")
cohortDatabaseSchema <- Sys.getenv("UT_COHORT_SCHEMA")
dbms = Sys.getenv("UT_DBMS")
server = Sys.getenv("UT_DB_SERVER")
port = Sys.getenv("UT_DB_PORT")

# Use this when you'd like to emit the SQL for debugging 
debug <- FALSE
cohortTable <- "dus_h2_atlas_cohorts_ut"
oracleTempSchema <- NULL
createSchemaPerTest <- TRUE
addIndex <- TRUE # Use this for PostgreSQL and other dialects that support creating indicies

# This is a hardcoded list of tables that are used in the DUS analysis as
# defined in inst/sql/sql_server/dus_analysis*.sql
tablesToCleanup <- list(cohortTable, 
                        "dus_h2_drug_exposure", 
                        "dus_h2_cohort",
                        "dus_h2_numerator",
                        "dus_h2_denominator")

# Connect to the server
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = dbms,
                                                                server = server,
                                                                user = user,
                                                                password = password,
                                                                port = port)
connection <- DatabaseConnector::connect(connectionDetails)


# Helper Functions ------------------
testCleanup <- function(tableList) {
  templateSql <- "TRUNCATE TABLE @cohort_database_schema.@table_name;\nDROP TABLE @cohort_database_schema.@table_name;\n"
  sql <- ""
  for (i in 1:length(tableList)) {
    sql <- paste(sql, SqlRender::render(sql=templateSql, table_name = tableList[i]), sep="\n")
  }
  return(sql)
}


# Execute Tests ---------------------

#testCaseSql <- list.files(path = pathToTestCaseSql, pattern=".*.sql", include.dirs = FALSE)
testCaseSql <- list("prevalenceTest.sql")

# Create the temp tables used in each analysis once to save
# some DB work
DrugUtilization::dusAnalysisCreateGlobalTempTables(connection = connection,
                                             vocabularyDatabaseSchema = cdmDatabaseSchema,
                                             oracleTempSchema = oracleTempSchema)

for (i in 1:length(testCaseSql)) {
  # Create the data by running the SQL
  sql <- SqlRender::readSql(file.path(pathToTestCaseSql, testCaseSql[i]))
  sql <- SqlRender::render(sql = sql, cdm_database_schema = cdmDatabaseSchema)
  ParallelLogger::logInfo(testCaseSql[i])
  DatabaseConnector::executeSql(connection,
                                sql,
                                progressBar = T)
  
  # Set the databaseName == the test case name
  databaseName <- tools::file_path_sans_ext(testCaseSql[i])
  
  if (createSchemaPerTest) {
    resultsSchema <- paste0(cohortDatabaseSchema, i)
    
    # Drop any existing schemas that might interfere with running
    # these tests. For now check if the DB is PostgreSQL and drop the
    # results schemas
    if (tolower(attr(connection, "dbms")) == tolower("postgresql")) {
      sql <- paste0("drop schema if exists ", resultsSchema, " cascade;")
      DatabaseConnector::executeSql(connection,
                                    sql,
                                    progressBar = F)
    }
    
    # Create a schema for the results
    DatabaseConnector::executeSql(connection,
                                  paste0("CREATE SCHEMA ", resultsSchema, ";"),
                                  progressBar = T)
  } else {
    resultsSchema = cohortDatabaseSchema
  }

  # Execute the study and export the results
  DrugUtilization::execute(connection,
                            connectionDetails,
                            cdmDatabaseSchema = cdmDatabaseSchema,
                            cohortDatabaseSchema = resultsSchema,
                            cohortTable = cohortTable,
                            oracleTempSchema = oracleTempSchema,
                            outputFolder = unitTestOutputFolder,
                            databaseId = databaseName,
                            databaseName = databaseName,
                            createCohorts = TRUE,
                            runAnalyses = TRUE,
                            createTables= TRUE,
                            addIndex = addIndex,
                            debug = FALSE,
                            debugSqlFile = "ut.sql",
                            selfManageTempTables = FALSE,
                            minCellCount = 0)
  
  # Cleanup on exit
  if (!createSchemaPerTest) {
    cleanupSql <- testCleanup(tablesToCleanup)
    cleanupSql <- SqlRender::render(sql = cleanupSql, cohort_database_schema = resultsSchema)
    DatabaseConnector::executeSql(connection, cleanupSql)
  }
}

# Clean up the temp tables
DrugUtilization::dusAnalysisDropGlobalTempTables(connection = connection,
                                           oracleTempSchema = oracleTempSchema)

if (createSchemaPerTest) {
  warning(paste0("There were ", i, " results schemas created as part of running these tests. You are responsible for manually dropping them before running another set of tests"))
}

on.exit(DatabaseConnector::disconnect(connection))

DrugUtilization::preMergeDiagnosticsFiles(unitTestOutputFolder)
DrugUtilization::launchResultsExplorer(unitTestOutputFolder)

