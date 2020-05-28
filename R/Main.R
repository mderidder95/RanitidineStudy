# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of DrugUtilization
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Execute the Study
#'
#' @details
#' This function executes the DrugUtilization Study. The \code{createCohorts}, \code{runAnalyses},
#' arguments are intended to be used to run parts of the full study at a time, but none of the parts
#' are considered to be optional.
#'
#' @param connectionDetails      An object of type \code{connectionDetails} as created using the
#'                               \code{\link[DatabaseConnector]{createConnectionDetails}} function in
#'                               the DatabaseConnector package.
#' @param cdmDatabaseSchema      Schema name where your patient-level data in OMOP CDM format resides.
#'                               Note that for SQL Server, this should include both the database and
#'                               schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema   Schema name where intermediate data can be stored. You will need to
#'                               have write priviliges in this schema. Note that for SQL Server, this
#'                               should include both the database and schema name, for example
#'                               'cdm_data.dbo'.
#' @param cohortTable            The name of the table that will be created in the work database
#'                               schema. This table will hold the exposure and outcome cohorts used in
#'                               this study.
#' @param oracleTempSchema       Should be used in Oracle to specify a schema where the user has write
#'                               priviliges for storing temporary tables.
#' @param outputFolder           Name of local folder to place results; make sure to use forward
#'                               slashes (/). Do not use a folder on a network drive since this greatly
#'                               impacts performance.
#' @param databaseId             A short string for identifying the database (e.g. 'Synpuf').
#' @param databaseName           The full name of the database (e.g. 'Medicare Claims Synthetic Public
#'                               Use Files (SynPUFs)').
#' @param databaseDescription    A short description (several sentences) of the database.
#' @param createCohorts          Create the cohortTable table with the exposure and outcome cohorts?
#' @param runAnalyses            Perform the cohort method analyses?
#' @param createTables           Generate all the result tables?
#' @param maxCores               How many parallel cores should be used? If more cores are made
#'                               available this can speed up the analyses.
#' @param minCellCount           The minimum number of subjects contributing to a count before it can
#'                               be included in packaged results.
#'
#' @examples
#' \dontrun{
#' connectionDetails <- createConnectionDetails(dbms = "postgresql",
#'                                              user = "joe",
#'                                              password = "secret",
#'                                              server = "myserver")
#'
#' execute(connectionDetails,
#'         cdmDatabaseSchema = "cdm_data",
#'         cohortDatabaseSchema = "study_results",
#'         cohortTable = "cohort",
#'         oracleTempSchema = NULL,
#'         outputFolder = "c:/temp/study_results",
#'         maxCores = 4)
#' }
#'
#' @export
execute <- function(connection = NULL,
                    connectionDetails,
                    cdmDatabaseSchema,
                    cohortDatabaseSchema = cdmDatabaseSchema,
                    cohortTable = "cohort",
                    oracleTempSchema = cohortDatabaseSchema,
                    outputFolder,
                    databaseId = "Unknown",
                    databaseName = "Unknown",
                    createCohorts = TRUE,
                    runAnalyses = TRUE,
                    createTables = TRUE,
                    exportResults = TRUE,
                    addIndex = FALSE,
                    selfManageTempTables = TRUE,
                    vocabularyDatabaseSchema = cdmDatabaseSchema,
                    cdmDrugExposureSchema = cdmDatabaseSchema,
                    drugExposureTable = "drug_exposure",
                    cdmObservationPeriodSchema = cdmDatabaseSchema,
                    observationPeriodTable = "observation_period",
                    cdmPersonSchema = cdmDatabaseSchema,
                    personTable = "person",
                    minCellCount = 5,
                    debug = FALSE,
                    debugSqlFile = "") {
  if (!file.exists(outputFolder))
    dir.create(outputFolder, recursive = TRUE)
  if (!is.null(getOption("fftempdir")) && !file.exists(getOption("fftempdir"))) {
    warning("fftempdir '", getOption("fftempdir"), "' not found. Attempting to create folder")
    dir.create(getOption("fftempdir"), recursive = TRUE)
  }
  
  if (is.null(connection)) {
    connection <- DatabaseConnector::connect(connectionDetails)
    on.exit(DatabaseConnector::disconnect(connection))
  }

  packageName = "DrugUtilization"
  # Load created cohorts
  pathToCsv <- system.file("settings", "CohortsToCreate.csv", package = packageName)
  cohorts <- readr::read_csv(pathToCsv, col_types = readr::cols())
  cohorts$atlasId <- NULL

  cohortsOfInterest <- cohorts[cohorts$cohortId < 10, ]
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

  
  ParallelLogger::addDefaultFileLogger(file.path(outputFolder, "log.txt"))
  on.exit(ParallelLogger::unregisterLogger("DEFAULT"))

  if (createCohorts) {
    ParallelLogger::logInfo("Creating cohorts")
    createCohorts(connection = connection,
                  connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohortTable,
                  addIndex = addIndex,
                  oracleTempSchema = oracleTempSchema,
                  outputFolder = outputFolder)
  }


  if (runAnalyses) {
    ParallelLogger::logInfo("Running Drug Utilization analyses")
    dusAnalysis(connection = connection,
                connectionDetails = connectionDetails,
                cdmDatabaseSchema = cdmDatabaseSchema,
                cohortDatabaseSchema = cohortDatabaseSchema,
                cohortTable = cohortTable,
                oracleTempSchema = oracleTempSchema,
                debug = debug,
                outputFolder = outputFolder,
                debugSqlFile = debugSqlFile, 
                databaseId = databaseId,
                databaseName = databaseName,
                addIndex = addIndex,
                selfManageTempTables = selfManageTempTables,
                vocabularyDatabaseSchema,
                cdmDrugExposureSchema,
                drugExposureTable,
                cdmObservationPeriodSchema,
                observationPeriodTable,
                cdmPersonSchema,
                personTable)
  }
  
  if (createTables) {
   ParallelLogger::logInfo("Creating All Tables")
   createAllTables(connection = connection,
                   connectionDetails = connectionDetails,
                   cdmDatabaseSchema = cdmDatabaseSchema,
                   cohortDatabaseSchema = cohortDatabaseSchema,
                   oracleTempSchema = oracleTempSchema,
                   debug = debug,
                   outputFolder = outputFolder,
                   debugSqlFile = debugSqlFile, 
                   minCellCount = minCellCount,
                   databaseId,
                   databaseName)
   
   ParallelLogger::logInfo("Gathering prevalence proportion")
   getProportion <- function(row, proportionType) {
     data <- getProportionByType(connection = connection,
                                 connectionDetails = connectionDetails,
                                 cdmDatabaseSchema = cdmDatabaseSchema,
                                 cohortDatabaseSchema = cohortDatabaseSchema,
                                 proportionType = proportionType,
                                 ingredient = row$cohortId)
     if (nrow(data) > 0) {
       data$cohortId <- row$cohortId
     }
     return(data)
   }
   prevalenceData <- lapply(split(cohortsOfInterest, cohortsOfInterest$cohortId), getProportion, proportionType = "prevalence")
   prevalenceData <- do.call(rbind, prevalenceData)
   if (nrow(prevalenceData) > 0) {
     prevalenceData$databaseId <- databaseId
     prevalenceData <- enforceMinCellValue(prevalenceData, "cohortCount", minCellCount)
     prevalenceData <- enforceMinCellValue(prevalenceData, "proportion", minCellCount/prevalenceData$numPersons)
   }
   writeToCsv(prevalenceData, file.path(outputFolder, "prevalence_proportion.csv"))
   
   # Incidence
   ParallelLogger::logInfo("Gathering incidence proportion")
   incidenceData <- lapply(split(cohortsOfInterest, cohortsOfInterest$cohortId), getProportion, proportionType = "incidence")
   incidenceData <- do.call(rbind, incidenceData)
   if (nrow(incidenceData) > 0) {
     incidenceData$databaseId <- databaseId
     incidenceData <- enforceMinCellValue(incidenceData, "cohortCount", minCellCount)
     incidenceData <- enforceMinCellValue(incidenceData, "proportion", minCellCount/incidenceData$numPersons)
   }
   writeToCsv(incidenceData, file.path(outputFolder, "incidence_proportion.csv"))
  }
  
  if (exportResults) {
    exportResults(outputFolder,databaseId)
  }

  invisible(NULL)
}
