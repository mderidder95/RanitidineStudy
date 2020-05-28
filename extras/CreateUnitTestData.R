# Helper Functions ------------
initTestCase <- function() {
  tableList <- list("PERSON", "DRUG_EXPOSURE", "OBSERVATION_PERIOD", "CONDITION_OCCURRENCE")
  templateSql <- "TRUNCATE TABLE @cdm_database_schema.@table_name;"
  sql <- ""
  for (i in 1:length(tableList)) {
    if (i == 1) {
      sql <- SqlRender::render(sql=templateSql, table_name = tableList[i])
    } else {
      sql <- paste(sql, SqlRender::render(sql=templateSql, table_name = tableList[i]), sep="\n")
    }
  }
  return(paste0(sql, "\n\n"))
}

nullify <- function(val) {
  returnVal <- ifelse(is.null(val), 'NULL', val)
  if (is.character(val)) {
    returnVal = paste0('\'', val, '\'')
  }
  return(returnVal)
}

createCdmPerson <- function(person) {
  templateSql <- "INSERT INTO @cdm_database_schema.PERSON (person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id, person_source_value) 
                  SELECT @person_id, @gender_concept_id, @year_of_birth, @race_concept_id, @ethnicity_concept_id, @person_source_value;"
  
  sql <- SqlRender::render(sql=templateSql, 
                           person_id = person$person_id,
                           gender_concept_id = person$gender_concept_id,
                           year_of_birth = person$year_of_birth,
                           race_concept_id = person$race_concept_id,
                           ethnicity_concept_id = person$ethnicity_concept_id,
                           person_source_value = nullify(person$person_source_value))
  return(sql)
}

createCdmObservationPeriod <- function(op) {
  templateSql <- "INSERT INTO @cdm_database_schema.OBSERVATION_PERIOD (observation_period_id, person_id, observation_period_start_date, observation_period_end_date, period_type_concept_id) 
                  SELECT @observation_period_id, @person_id, '@observation_period_start_date', '@observation_period_end_date', @period_type_concept_id;"
  
  sql <- SqlRender::render(sql=templateSql, 
                           observation_period_id = op$observation_period_id, 
                           person_id = op$person_id, 
                           observation_period_start_date = op$observation_period_start_date, 
                           observation_period_end_date = op$observation_period_end_date, 
                           period_type_concept_id = op$period_type_concept_id)
  return(sql)
}

createCdmDrugExposure <- function(de) {
  templateSql <- "INSERT INTO @cdm_database_schema.DRUG_EXPOSURE (drug_exposure_id, person_id, drug_concept_id, drug_exposure_start_date, drug_exposure_end_date, quantity, drug_type_concept_id) 
                  SELECT @drug_exposure_id, @person_id, @drug_concept_id, '@drug_exposure_start_date', '@drug_exposure_end_date', @quantity, @drug_type_concept_id;"
  
  sql <- SqlRender::render(sql=templateSql, 
                           drug_exposure_id = de$drug_exposure_id, 
                           person_id = de$person_id, 
                           drug_concept_id = de$drug_concept_id, 
                           drug_exposure_start_date = de$drug_exposure_start_date, 
                           drug_exposure_end_date = de$drug_exposure_end_date,
                           quantity = de$quantity,
                           drug_type_concept_id = de$drug_type_concept_id)
  return(sql)
}

createCdmConditionOccurrence <- function (co) {
  templateSql <- "INSERT INTO @cdm_database_schema.CONDITION_OCCURRENCE (condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_type_concept_id, condition_status_concept_id, condition_source_concept_id) 
                  SELECT @condition_occurrence_id, @person_id, @condition_concept_id, '@condition_start_date', @condition_type_concept_id, @condition_status_concept_id, @condition_source_concept_id;"
  
  sql <- SqlRender::render(sql=templateSql, 
                           condition_occurrence_id = co$condition_occurrence_id, 
                           person_id = co$person_id, 
                           condition_concept_id = co$condition_concept_id, 
                           condition_start_date = co$condition_start_date, 
                           condition_type_concept_id = co$condition_type_concept_id,
                           condition_status_concept_id = co$condition_status_concept_id,
                           condition_source_concept_id = co$condition_source_concept_id)
  return(sql)
}


# Create Unit Test SQL Scripts ------------
# Load the test cases from the package
pathToTestCases <- Sys.getenv("UT_TEST_CASES_FILE_LOCATION")
testCaseFiles <- list.files(path = pathToTestCases, pattern=".*.json", include.dirs = FALSE)

# Clear any existing SQL file
pathToSqlFiles <- file.path(pathToTestCases, "sql")
# Initialize the sql path - careful, this will automatically remove prior results!
if (dir.exists(pathToSqlFiles)) {
  unlink(pathToSqlFiles, recursive = TRUE)
}
dir.create(pathToSqlFiles)

# Create SQL for each test case
for (i in 1:length(testCaseFiles)) {
  testCaseFile <- testCaseFiles[i]
  ParallelLogger::logInfo(paste(testCaseFile))
  # Read the JSON structure
  jsonTestCase <- jsonlite::read_json(file.path(pathToTestCases, testCaseFile))
  # Initialze the test case
  sql <- initTestCase()
  # Use the name of the file as a comment in the SQL
  sql <- paste(sql, "-- TEST: ", testCaseFile)
  # Person records
  if (!is.null(jsonTestCase$cdm.person)) {
    for(p in 1:length(jsonTestCase$cdm.person)) {
      sql <- paste(sql, createCdmPerson(jsonTestCase$cdm.person[[p]]), sep="\n")
    }
  }
  # Observation period records
  if (!is.null(jsonTestCase$cdm.observation_period)) {
    for(p in 1:length(jsonTestCase$cdm.observation_period)) {
      sql <- paste(sql, createCdmObservationPeriod(jsonTestCase$cdm.observation_period[[p]]), sep="\n")
    }
  }
  # Drug exposure records
  if (!is.null(jsonTestCase$cdm.drug_exposure)) {
    for(p in 1:length(jsonTestCase$cdm.drug_exposure)) {
      sql <- paste(sql, createCdmDrugExposure(jsonTestCase$cdm.drug_exposure[[p]]), sep="\n")
    }
  }
  
  # Condition occurrence records
  if (!is.null(jsonTestCase$cdm.condition_occurrence)) {
    for(p in 1:length(jsonTestCase$cdm.condition_occurrence)) {
      sql <- paste(sql, createCdmConditionOccurrence(jsonTestCase$cdm.condition_occurrence[[p]]), sep="\n")
    }
  }
  SqlRender::writeSql(sql, targetFile = file.path(pathToTestCases, "sql", paste0(tools::file_path_sans_ext(testCaseFile), ".sql")))
}