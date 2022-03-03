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

#' @export
dusAnalysis <- function(connection = NULL,
                        connectionDetails,
                        cdmDatabaseSchema,
                        cohortDatabaseSchema,
                        cohortTable = "cohort",
                        oracleTempSchema = oracleTempSchema,
                        debug = FALSE,
                        debugSqlFile = "",
                        databaseId = "Unknown",
                        databaseName = "Unknown",
                        outputFolder,
                        addIndex = FALSE,
                        selfManageTempTables = TRUE,
                        vocabularyDatabaseSchema,
                        cdmDrugExposureSchema,
                        drugExposureTable,
                        cdmObservationPeriodSchema,
                        observationPeriodTable,
                        cdmPersonSchema,
                        personTable) {
  
  start <- Sys.time()
  if (!file.exists(outputFolder)) {
    dir.create(outputFolder)
  }
  
  if (debug && debugSqlFile == "") {
    stop("When using the debug feature, you must provide a file name for the rendered and translated SQL.")
  }
  
  if (is.null(connection)) {
    connection <- DatabaseConnector::connect(connectionDetails)
  }

  ParallelLogger::logInfo("Creating Patient-Level data in database")
  
  # Get the SQL used in the analysis
  dfSql <- data.frame(msg = character(), 
                      sqlFile = character(),
                      sql = character())

  # Create the temp tables if specified
  if (selfManageTempTables) {
    tempTableCreate <- dusAnalysisCreateGlobalTempTables(connection = connection,
                                                         vocabularyDatabaseSchema = vocabularyDatabaseSchema,
                                                         oracleTempSchema = oracleTempSchema,
                                                         returnSql = TRUE)
    tempTableCreate <- list(msg = "Create global temp tables",
                            sqlFile = tempTableCreate$sqlFile,
                            sql = tempTableCreate$sql)
    dfSql = rbind(dfSql, tempTableCreate, stringsAsFactors = FALSE)
  }
  
  tempCalendarYears <- .getCalendarYearsSqlForCdm(connection = connection,
                                                 cdmObservationPeriodSchema = cdmObservationPeriodSchema,
                                                 observationPeriodTable = observationPeriodTable,
                                                 oracleTempSchema = oracleTempSchema)
  tempCalendarYears <- list(msg = "Creating calendary year temp table off observation_period",
                            sqlFile = tempCalendarYears$sqlFile,
                            sql = tempCalendarYears$sql)
  dfSql = rbind(dfSql, tempCalendarYears, stringsAsFactors = FALSE)
  
  sqlFile <- "dus_analysis_create_temp_cohort.sql"
  tempCohortTable <-  list(msg = "Creating the temporary cohort table",
                           sqlFile = sqlFile,
                           sql = loadRenderTranslateSql(connection,
                                                   sqlFileInPackage = sqlFile,
                                                   oracleTempSchema = oracleTempSchema,
                                                   vocabulary_database_schema = vocabularyDatabaseSchema,
                                                   cdm_drug_exposure_schema = cdmDrugExposureSchema,
                                                   drug_exposure_table = drugExposureTable,
                                                   cohort_database_schema = cohortDatabaseSchema,
                                                   cohort_table = cohortTable))
  dfSql = rbind(dfSql, tempCohortTable, stringsAsFactors = FALSE)
  
  sqlFile <- "dus_analysis_create_temp_drug_exposures.sql"
  tempDrugExposureTable <- list(msg = "Creating temp table with all drug exposures",
                                sqlFile = sqlFile,
                                sql = loadRenderTranslateSql(connection,
                                                        sqlFileInPackage = sqlFile,
                                                        oracleTempSchema = oracleTempSchema,
                                                        vocabulary_database_schema = vocabularyDatabaseSchema,
                                                        cdm_drug_exposure_schema = cdmDrugExposureSchema,
                                                        drug_exposure_table = drugExposureTable,
                                                        cdm_observation_period_schema = cdmObservationPeriodSchema,
                                                        observation_period_table = observationPeriodTable))
  dfSql = rbind(dfSql, tempDrugExposureTable, stringsAsFactors = FALSE)

  sqlFile <- "dus_analysis_create_perm_drug_exposure.sql"
  permDrugExposureTable <- list(msg = "Creating dus_h2_drug_exposures table",
                                sqlFile = sqlFile,
                                sql = loadRenderTranslateSql(connection = connection,
                                                            sqlFileInPackage = sqlFile,
                                                            oracleTempSchema = oracleTempSchema,
                                                            cohort_database_schema = cohortDatabaseSchema,
                                                            add_index = addIndex))
  dfSql = rbind(dfSql, permDrugExposureTable, stringsAsFactors = FALSE)
  
  sqlFile <- "dus_analysis_create_perm_cohort.sql"
  permCohortTable <- list(msg = "Creating dus_h2_cohort table",
                          sqlFile = sqlFile,
                          sql = loadRenderTranslateSql(connection = connection,
                                                       sqlFileInPackage = sqlFile,
                                                       oracleTempSchema = oracleTempSchema,
                                                       vocabulary_database_schema = vocabularyDatabaseSchema,
                                                       add_index = addIndex,
                                                       cdm_person_schema = cdmPersonSchema,
                                                       person_table = personTable,
                                                       cdm_observation_period_schema = cdmObservationPeriodSchema,
                                                       observation_period_table = observationPeriodTable,                                                       
                                                       cohort_database_schema = cohortDatabaseSchema,
                                                       cohort_table = cohortTable))
  dfSql = rbind(dfSql, permCohortTable, stringsAsFactors = FALSE)
  
  sqlFile <- "dus_analysis_compute_prev_inc.sql"
  computeIncPrev <- list(msg = "Computing incidence and prevalence",
                         sqlFile = sqlFile,
                         sql = loadRenderTranslateSql(connection = connection,
                                                      sqlFileInPackage = sqlFile,
                                                      oracleTempSchema = oracleTempSchema,
                                                      cdm_person_schema = cdmPersonSchema,
                                                      person_table = personTable,
                                                      cdm_observation_period_schema = cdmObservationPeriodSchema,
                                                      observation_period_table = observationPeriodTable,                                                       
                                                      cohort_database_schema = cohortDatabaseSchema,
                                                      cohort_table = cohortTable))
  dfSql = rbind(dfSql, computeIncPrev, stringsAsFactors = FALSE)

  sqlFile <- "dus_analysis_observation_per_month.sql"
  obsPeriodPerMonth <- list(msg = "Computing observation period histogram data",
                            sqlFile = sqlFile,
                            sql = loadRenderTranslateSql(connection = connection,
                                                         sqlFileInPackage = sqlFile,
                                                         oracleTempSchema = oracleTempSchema,
                                                         cdm_observation_period_schema = cdmObservationPeriodSchema,
                                                         observation_period_table = observationPeriodTable,                                                       
                                                         cohort_database_schema = cohortDatabaseSchema))
  dfSql = rbind(dfSql, obsPeriodPerMonth, stringsAsFactors = FALSE)
  
  sqlFile <- "dus_analysis_temp_table_drop_analysis.sql"
  dropAnalysisTempTables <- list(msg = "Drop analysis temp tables",
                                 sqlFile = sqlFile,
                                 sql = loadRenderTranslateSql(connection = connection,
                                                              sqlFileInPackage = sqlFile,
                                                              oracleTempSchema = oracleTempSchema))
  dfSql = rbind(dfSql, dropAnalysisTempTables, stringsAsFactors = FALSE)

  # Create the temp tables if specified
  if (selfManageTempTables) {
    tempTableDrop <- dusAnalysisDropGlobalTempTables(connection = connection,
                                                      oracleTempSchema = oracleTempSchema,
                                                      returnSql = TRUE)
    tempTableDrop <- list(msg = "Drop global temp tables",
                          sqlFile = tempTableDrop$sqlFile,
                          sql = tempTableDrop$sql)
    dfSql = rbind(dfSql, tempTableDrop, stringsAsFactors = FALSE)
  }

  # Run the analysis
  if (debug) {
    sqlFormat <- function(sql, sqlFile) {
      lineBreak <- "\n---------------\n"
      return(paste0(lineBreak,
                    "-- BEGIN FILE: ", sqlFile,
                    lineBreak,
                    sql, 
                    lineBreak,
                    "-- END FILE: ", sqlFile,
                    lineBreak));
    }
    SqlRender::writeSql(apply(dfSql[,c('sql', 'sqlFile')], 1, function(x) sqlFormat(sql = x[1], sqlFile = x[2])), debugSqlFile)
    print(paste0("Debug file written to: ", debugSqlFile))
  } else {
    for (i in 1:nrow(dfSql)) {
      ParallelLogger::logInfo(paste0("  - ", dfSql$msg[i], " (", dfSql$sqlFile[i], ")"))
      DatabaseConnector::executeSql(connection,
                                    dfSql$sql[i],
                                    progressBar = T,
                                    reportOverallTime = T)
      
    }
    delta <- Sys.time() - start
    ParallelLogger::logInfo(paste("Creating Patient-Level data took",
                                  signif(delta, 3),
                                  attr(delta, "units")))
  }

}

#' @export
dusAnalysisCreateGlobalTempTables <- function(connection,
                                        vocabularyDatabaseSchema,
                                        oracleTempSchema,
                                        returnSql = FALSE) {
  
  sqlFile <- "dus_analysis_temp_table_create_global.sql"
  sql <- loadRenderTranslateSql(connection,
                                sqlFileInPackage = sqlFile,
                                oracleTempSchema = oracleTempSchema,
                                vocabulary_database_schema = vocabularyDatabaseSchema)
  if (!returnSql) {
    ParallelLogger::logInfo("Creating global temp tables")
    DatabaseConnector::executeSql(connection,
                                  sql,
                                  progressBar = T,
                                  reportOverallTime = T)
    
  } else {
    return (list(sqlFile = sqlFile, sql = sql))
  }
}

#' @export
dusAnalysisDropGlobalTempTables <- function(connection,
                                      oracleTempSchema,
                                      returnSql = FALSE) {
  
  sqlFile <- "dus_analysis_temp_table_drop_global.sql"
  sql <- loadRenderTranslateSql(connection,
                                sqlFileInPackage = sqlFile,
                                oracleTempSchema = oracleTempSchema)
  if (!returnSql) {
    ParallelLogger::logInfo("Dropping global temp tables")
    DatabaseConnector::executeSql(connection,
                                  sql,
                                  progressBar = T,
                                  reportOverallTime = T)
  } else {
    return (list(sqlFile = sqlFile, sql = sql))
  }
}

.getCalendarYearsSqlForCdm <- function(connection,
                                       cdmObservationPeriodSchema,
                                       observationPeriodTable,
                                       oracleTempSchema) {
  sqlFile <- "GetCalendarYearRange.sql"
  sql <- loadRenderTranslateSql(connection = connection,
                                sqlFileInPackage = sqlFile,
                                cdm_observation_period_schema = cdmObservationPeriodSchema,
                                observation_period_table = observationPeriodTable)
  yearRange <- DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE)
  calendarYears <- data.frame(calendarYear = seq(yearRange$startYear, yearRange$endYear, by = 1))
  sql <- "WITH data AS (
            @unions
          ) 
          SELECT calendar_year
          INTO #CALENDAR_YEARS 
          FROM data;"
  unions <- "";
  for(i in 1:nrow(calendarYears)) {
    stmt <- paste0("SELECT ", calendarYears$calendarYear[i], " calendar_year")
    unions <- paste(unions, stmt, sep="\n")
    if (i < nrow(calendarYears)) {
      unions <- paste(unions, "UNION ALL", sep="\n")
    }
  }
  
  sql <- SqlRender::render(sql, unions = unions)
  sql <- SqlRender::translate(sql = sql, 
                              targetDialect = attr(connection, "dbms"),
                              oracleTempSchema = oracleTempSchema)
  return(list(sqlFile = sqlFile, sql = sql))  
}

#' @export
createAllTables <- function(connection = NULL,
                            connectionDetails,
                            cdmDatabaseSchema,
                            cohortDatabaseSchema,
                            oracleTempSchema,
                            debug = FALSE,
                            debugSqlFile = "",
                            databaseId = "Unknown",
                            databaseName = "Unknown",
                            minCellCount = 5,
                            outputFolder) {
  
  options(digits = 10)

  start <- Sys.time()
  if (!file.exists(outputFolder)) {
    dir.create(outputFolder)
  }
  
  if (debug && debugSqlFile == "") {
    stop("When using the debug feature, you must provide a file name for the rendered and translated SQL.")
  }
  
  if (is.null(connection)) {
    connection <- DatabaseConnector::connect(connectionDetails)
  }
  
  # Generate Tables
  ParallelLogger::logInfo("Read Patient-Level Data")
  sql <- loadRenderTranslateSql(connection = connection,
                                sqlFileInPackage = "PatientLevelData.sql",
                                oracleTempSchema = oracleTempSchema,
                                cohort_database_schema = cohortDatabaseSchema)
  
  if (debug) {
    SqlRender::writeSql(sql, debugSqlFile)
    print(paste0("Debug file written to: ", debugSqlFile))
  } else {
    data <-
      DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE)
  }
  
  if (!is.null(data)) {
    ParallelLogger::logInfo("Updating Patient-Level Data")
    
    data <- updateData(data)  #fix columns
    
    ParallelLogger::logInfo("Saving database metadata")
    database <- data.frame(databaseId = databaseId,
                           databaseName = databaseName)
    writeToCsv(database, file.path(outputFolder, "database.csv"))
    
    ParallelLogger::logInfo("Gathering observation period histogram")
    sql <- loadRenderTranslateSql(connection = connection,
                                  sqlFileInPackage = "ObservationPeriod.sql",
                                  oracleTempSchema = oracleTempSchema,
                                  cohort_database_schema = cohortDatabaseSchema)
    dataObsPeriod <-
      DatabaseConnector::querySql(connection, sql, snakeCaseToCamelCase = TRUE)
    dataObsPeriod <- tibble::add_column(dataObsPeriod, databaseid=databaseId, .before="obsYearMonth")
    writeToCsv(dataObsPeriod, file.path(outputFolder, "observationPeriodHistogramFullDatabase.csv"))
    
    ParallelLogger::logInfo("Generating all output tables")
    createAgeHistogramTable(data,databaseId,outputFolder)
    createAgeSummaryTable(data,databaseId,minCellCount=minCellCount,outputFolder)
    createObservatioPeriodHistogramTable(data,databaseId,outputFolder)
    createObservatioPeriodSummaryTable(data,databaseId,outputFolder)
    createIndicationsTable(data, databaseId, minCellCount, outputFolder)
    suppressWarnings(createSummaryTable(data,databaseId,"cumulativeDuration",minCellCount,outputFolder,"table1a.csv",addCumulativeDurationGroup=TRUE))
    suppressWarnings(createSummaryTable(data,databaseId,"pddRatio",minCellCount,outputFolder,"table2a.csv",addRatioGroup=TRUE))
    suppressWarnings(createSummaryTable(data,databaseId,"cumulativeDdd",minCellCount,outputFolder,"table3a.csv"))
    suppressWarnings(createSummaryTable(data,databaseId,"cumulativeDose",minCellCount,outputFolder,"table4a.csv"))
    suppressWarnings(createSummaryTable(data,databaseId,"cumulativeAnnualDose",minCellCount,outputFolder,"table5a.csv"))
    suppressWarnings(createHistoryTable(data,databaseId,"indication365Ri",outputFolder,"table7.csv"))
    suppressWarnings(createStrataTable(data,databaseId,"cumulativeDuration",minCellCount,outputFolder, "table1b.csv"))
    suppressWarnings(createStrataTable(data,databaseId,"pddRatio",minCellCount,outputFolder,"table2b.csv"))
    suppressWarnings(createStrataTable(data,databaseId,"cumulativeDdd",minCellCount,outputFolder,"table3b.csv"))
    suppressWarnings(createStrataTable(data,databaseId,"cumulativeDose",minCellCount,outputFolder,"table4b.csv"))
    suppressWarnings(createStrataTable(data,databaseId,"cumulativeAnnualDose",minCellCount,outputFolder,"table5b.csv"))
  } else {
    ParallelLogger::logInfo("No Patient-Level Data found in database")
  }
}

#' @export
exportResults <- function(outputFolder,databaseId) {
  # Add all to zip file 
  ParallelLogger::logInfo("Adding results to zip file")
  zipName <- file.path(outputFolder, paste0("Results_", databaseId, ".zip"))
  files <- list.files(outputFolder, pattern = ".*\\.csv$")
  oldWd <- setwd(outputFolder)
  on.exit(setwd(oldWd))
  DatabaseConnector::createZipFile(zipFile = zipName, files = files)
  ParallelLogger::logInfo("Results are ready for sharing at:", zipName)
}


writeToCsv <- function(data, fileName) {
  colnames(data) <- SqlRender::camelCaseToSnakeCase(colnames(data))
  # write.csv(data, fileName, row.names = FALSE)
  readr::write_csv(data, fileName)
}