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

#' Create the exposure and outcome cohorts
#'
#' @details
#' This function will create the exposure and outcome cohorts following the definitions included in
#' this package.
#'
#' @param connectionDetails      An object of type \code{connectionDetails} as created using the
#'                               \code{\link[DatabaseConnector]{createConnectionDetails}} function in
#'                               the DatabaseConnector package.
#' @param cdmDatabaseSchema      Schema name where your patient-level data in OMOP CDM format resides.
#'                               Note that for SQL Server, this should include both the database and
#'                               schema name, for example 'cdm_data.dbo'.
#' @param cohortDatabaseSchema   Schema name where intermediate data can be stored. You will need to
#'                               have write privileges in this schema. Note that for SQL Server, this
#'                               should include both the database and schema name, for example
#'                               'cdm_data.dbo'.
#' @param cohortTable            The name of the table that will be created in the work database
#'                               schema. This table will hold the exposure and outcome cohorts used in
#'                               this study.
#' @param oracleTempSchema       Should be used in Oracle to specify a schema where the user has write
#'                               privileges for storing temporary tables.
#' @param outputFolder           Name of local folder to place results; make sure to use forward
#'                               slashes (/)
#'
#' @export
createCohorts <- function(connection = NULL,
                          connectionDetails,
                          cdmDatabaseSchema,
                          cohortDatabaseSchema,
                          cohortTable = "cohort",
                          addIndex = FALSE,
                          oracleTempSchema,
                          outputFolder) {
  if (!file.exists(outputFolder))
    dir.create(outputFolder)

  if (is.null(connection)) {
    connection <- DatabaseConnector::connect(connectionDetails)
  }
  
  .createCohorts(connection = connection,
                 cdmDatabaseSchema = cdmDatabaseSchema,
                 cohortDatabaseSchema = cohortDatabaseSchema,
                 cohortTable = cohortTable,
                 addIndex = addIndex,
                 oracleTempSchema = oracleTempSchema,
                 outputFolder = outputFolder)

  # Check number of subjects per cohort:
  ParallelLogger::logInfo("Counting cohorts")
  sql <- loadRenderTranslateSql(connection = connection,
                                sqlFileInPackage = "GetCounts.sql",
                                oracleTempSchema = oracleTempSchema,
                                cdm_database_schema = cdmDatabaseSchema,
                                work_database_schema = cohortDatabaseSchema,
                                study_cohort_table = cohortTable)
  counts <- DatabaseConnector::querySql(connection, sql)
  colnames(counts) <- SqlRender::snakeCaseToCamelCase(colnames(counts))
  counts <- addCohortNames(counts)
  write.csv(counts, file.path(outputFolder, "CohortCounts.csv"), row.names = FALSE)
}

addCohortNames <- function(data,
                           IdColumnName = "cohortDefinitionId",
                           nameColumnName = "cohortName") {
  pathToCsv <- system.file("settings",
                           "CohortsToCreate.csv",
                           package = "DrugUtilization")
  cohortsToCreate <- read.csv(pathToCsv)
  idToName <- data.frame(cohortId = cohortsToCreate$cohortId,
                         cohortName = as.character(cohortsToCreate$atlasName))
  idToName <- idToName[order(idToName$cohortId), ]
  idToName <- idToName[!duplicated(idToName$cohortId), ]
  names(idToName)[1] <- IdColumnName
  names(idToName)[2] <- nameColumnName
  data <- merge(data, idToName, all.x = TRUE)
  # Change order of columns:
  idCol <- which(colnames(data) == IdColumnName)
  if (idCol < ncol(data) - 1) {
    data <- data[, c(1:idCol, ncol(data), (idCol + 1):(ncol(data) - 1))]
  }
  return(data)
}

checkIfCohortInstantiated <- function(connection, cohortDatabaseSchema, cohortTable, cohortId) {
  sql <- "SELECT COUNT(*) FROM @cohort_database_schema.@cohort_table WHERE cohort_definition_id = @cohort_id;"
  count <- DatabaseConnector::renderTranslateQuerySql(connection = connection,
                                                      sql,
                                                      cohort_database_schema = cohortDatabaseSchema,
                                                      cohort_table = cohortTable,
                                                      cohort_id = cohortId)
  return(count > 0)
}
