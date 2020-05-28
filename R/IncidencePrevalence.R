#' @export
getProportionByType <- function(connection = NULL,
                                connectionDetails = NULL,
                                cohortDatabaseSchema,
                                cdmDatabaseSchema,
                                oracleTempSchema = oracleTempSchema,
                                proportionType = 'prevalence',
                                ingredient) {
  if (!(proportionType == 'prevalence' || proportionType == 'incidence')) {
    stop("proportionType must be 'prevalence' or 'incidence'")
  }
  
  if (is.null(connection)) {
    connection <- DatabaseConnector::connect(connectionDetails)
  }
  
  sql <- loadRenderTranslateSql(connection = connection,
                                sqlFileInPackage = "getProportionByType.sql",
                                oracleTempSchema = oracleTempSchema,
                                cohort_database_schema = cohortDatabaseSchema,
                                cdm_database_schema = cdmDatabaseSchema,
                                numerator_type = proportionType,
                                denominator_type = 'denominator',
                                ingredient = ingredient)
  
  proportionSummary <- DatabaseConnector::renderTranslateQuerySql(connection = connection,
                                                             sql = sql,
                                                             oracleTempSchema = oracleTempSchema,
                                                             snakeCaseToCamelCase = TRUE)
  
  irYearAgeGender <- recode(proportionSummary)
  irOverall <- data.frame(cohortCount = sum(irYearAgeGender$cohortCount),
                          numPersons = sum(irYearAgeGender$numPersons))
  irAge <- aggregatePp(irYearAgeGender, list(ageGroup = irYearAgeGender$ageGroup))
  irAgeGender <- aggregatePp(irYearAgeGender, list(ageGroup = irYearAgeGender$ageGroup,
                                                   gender = irYearAgeGender$gender))
  irYearAge <- aggregatePp(irYearAgeGender, list(calendarYear = irYearAgeGender$calendarYear,
                                                 ageGroup = irYearAgeGender$ageGroup))
  
  # For year/gender only, make sure we're using the unique numerator/denominator
  sql <- loadRenderTranslateSql(connection = connection,
                                sqlFileInPackage = "getProportionByType.sql",
                                oracleTempSchema = oracleTempSchema,
                                cohort_database_schema = cohortDatabaseSchema,
                                cdm_database_schema = cdmDatabaseSchema,
                                numerator_type = paste0(proportionType, "_unique"),
                                denominator_type = 'denominator_unique',
                                ingredient = ingredient)
  
  proportionSummary <- DatabaseConnector::renderTranslateQuerySql(connection = connection,
                                                                  sql = sql,
                                                                  oracleTempSchema = oracleTempSchema,
                                                                  snakeCaseToCamelCase = TRUE)
  uqByYearGender <- recode(proportionSummary)
  irYear <- aggregatePp(uqByYearGender, list(calendarYear = uqByYearGender$calendarYear))
  irGender <- aggregatePp(uqByYearGender, list(gender = uqByYearGender$gender))
  irYearGender <- aggregatePp(uqByYearGender, list(calendarYear = uqByYearGender$calendarYear,
                                                    gender = uqByYearGender$gender))
  result <- dplyr::bind_rows(irOverall,
                             irGender,
                             irAge,
                             irAgeGender,
                             irYear,
                             irYearAge,
                             irYearGender,
                             irYearAgeGender)
  result$proptionType <- proportionType
  result$proportion <- (result$cohortCount/result$numPersons) * 1000 
  return(result)
}

recode <- function(proportionSummary) {
  proportionSummary$ageGroup <- paste(10 * proportionSummary$ageGroup, 10 * proportionSummary$ageGroup + 9, sep = "-")
  proportionSummary$gender <- tolower(proportionSummary$gender)
  substr(proportionSummary$gender, 1, 1) <- toupper(substr(proportionSummary$gender, 1, 1) ) 
  return(proportionSummary)
}

aggregatePp <- function(proportionSummary, aggregateList) {
  return(aggregate(cbind(cohortCount = proportionSummary$cohortCount,
                         numPersons = proportionSummary$numPersons), 
                   by = aggregateList, 
                   FUN = sum))
}