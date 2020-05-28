
#' @export  
updateData <- function(data) {
  
  # Set variables
  agebreaks <- c(0,2,12,18,30,40,50,60,70,80,150)
  agelabels <- c("0-2","2-12","12-18","18-30","30-40","40-50","50-60","60-70","70-80","80+")
  
  additional_agebreaks <- c(0,18,75,150)
  additional_agelabels <- c("0-18","18-75","75+")
  
  cumulativeDrugExposureBreaks <- c(0,30,365,3650,9999999)
  cumulativeDrugExposureLabels <- c("0-1 Month","1-12 Months","1-10 Year","1>10 Years")
  
  ratioBreaks <- c(0.000001,0.95,1.05,999)
  ratioLabels <- c("<1","1",">1")
  
  data = as_tibble(data)
  # read the cohortd
  options(readr.num_columns = 0)
  cohortsToCreate <- read_csv("inst/settings/CohortsToCreate.csv",col_names = TRUE)
  cohortNames <- as_tibble(cohortsToCreate) %>%
    select('cohortId', "name")
  
  # Replace Ingrdient with names
  result  <-
    left_join(data,
              cohortNames,
              by = c("ingredient" = "cohortId")) %>%
    mutate(ingredient = name) %>%
    select(-one_of('name'))
  
  # add some dummy date
  result <- dplyr::mutate(result,
                          agegroup=cut(age, 
                                       breaks = agebreaks, 
                                       right = FALSE, 
                                       labels = agelabels),
                          additional_agegroup=cut(age, 
                                                  breaks = additional_agebreaks, 
                                                  right = FALSE, 
                                                  labels = additional_agelabels),
                          ratioGroup=cut(pddRatio, 
                                         breaks = ratioBreaks, 
                                         right = FALSE, 
                                         labels = ratioLabels)) %>%
    mutate_if(is.factor, as.character)  
  
  result <- dplyr::mutate(
    result,
    cumulativeDurationGroup = cut(
      cumulativeDuration,
      breaks = cumulativeDrugExposureBreaks,
      right = FALSE,
      labels = cumulativeDrugExposureLabels
    )
  )
  return(result)
}

enforceMinCellValue <- function(data, fieldName, minValues, silent = FALSE) {
  toCensor <- !is.na(data[, fieldName]) & data[, fieldName] < minValues & data[, fieldName] != 0
  if (!silent) {
    percent <- round(100 * sum(toCensor)/nrow(data), 1)
    ParallelLogger::logInfo("   censoring ",
                            sum(toCensor),
                            " values (",
                            percent,
                            "%) from ",
                            fieldName,
                            " because value below minimum")
  }
  if (length(minValues) == 1) {
    data[toCensor, fieldName] <- -minValues
  } else {
    data[toCensor, fieldName] <- -minValues[toCensor]
  }
  return(data)
}

#' @export  

enforceMinCellValueRow <- function(data, minValue=5, silent = FALSE, exposureStrata=FALSE, ratioStrata=FALSE, indications=FALSE) {
  data<-data.frame(data) ## fix for Tibble package update to 3.0.0
  if (exposureStrata){
    censorFieldNames<-c("avg","median","p5","q1","q3","p95","min","max","n1","n2","n3","n4")
    toCensor <- (!is.na(data[, "n"]) & (data[, "n"] - data[, "excluded"]) < minValue) 
  } else if (indications){
    censorFieldNames<-c("N180_gerd","P180_gerd","N365_gerd","P365_gerd","N180_ulcer","P180_ulcer","N365_ulcer","P365_ulcer","N180_zes","P180_zes","N365_zes","P365_zes","N_unknown","P_unknown")
    toCensor <- !is.na(data[, "total"]) & data[, "total"] < minValue
  } else {
    if (ratioStrata){
      censorFieldNames<-c("avg","median","p5","q1","q3","p95","min","max","n1","n2","n3")
      toCensor <- (!is.na(data[, "n"]) & (data[, "n"] - data[, "excluded"]) < minValue)    
    } else {
      censorFieldNames<-c("avg","median","p5","q1","q3","p95","min","max")
      toCensor <- !is.na(data[, "n"]) & data[, "n"] < minValue      
    }
  }
  
  
  if (!silent) {
    percent <- round(100 * sum(toCensor)/nrow(data), 1)
    ParallelLogger::logInfo("   censoring ",
                            sum(toCensor),
                            " rows (",
                            percent,
                            "%) because remaining number of cases is <",
                            minValue)
  }

  if (indications){
    data[toCensor, "total"] <- paste0("<",minValue)
  } else {
    data[toCensor, "n"] <- paste0("<",minValue)
  }
  data[toCensor, censorFieldNames] <- " "
  data<-tibble(data) ## fix for Tibble package update to 3.0.0
  return(data)
}

pad_left <- function(x, len = 1 + max(nchar(x)), char = '0'){
  unlist(lapply(x, function(x) {
    paste0(
      paste(rep(char, len - nchar(x)), collapse = ''),
      x
    )
  }))
}

#' @export
loadRenderTranslateSql <- function(connection, sqlFileInPackage, oracleTempSchema, ...) {
  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = sqlFileInPackage,
                                           packageName = "DrugUtilization",
                                           dbms = attr(connection, "dbms"),
                                           warnOnMissingParameters = TRUE,
                                           oracleTempSchema = oracleTempSchema,
                                           ...)
  return (sql)
}


writeToCsvCensoredStats<- function(data, filename, minValue, exposureStrata=FALSE, ratioStrata=FALSE,indications=FALSE){
  data <- enforceMinCellValueRow(data, minValue=minValue, exposureStrata=exposureStrata, ratioStrata=ratioStrata, indications=indications)
  writeToCsv(data,filename)
}