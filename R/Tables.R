

#' @export 
createAgeSummaryTable <-function(data,databaseId,minCellCount,outputFolder) {
  # Get Age distribution by ingredient
  age_summary <- data %>%
    group_by(ingredient) %>%
    summarise(
      n = n(),
      avg = mean(age),
      median = median(age),
      p5 = quantile(age,probs=c(0.05)),
      q1 = quantile(age,probs=c(0.25)),
      q3 = quantile(age,probs=c(0.75)),
      p95 = quantile(age,probs=c(0.95)),
      min = min(age),
      max = max(age)
    ) %>%
    tibble::add_column(databaseid=databaseId, .before="ingredient")
  writeToCsvCensoredStats(age_summary, file.path(outputFolder, "agesummary.csv"), minValue=minCellCount, exposureStrata=FALSE)
}

#' @export 
createAgeHistogramTable <-function(data,databaseId,outputFolder) {
  # Age histogram by ingredient
  age_histogram <- data %>%
    group_by(ingredient, agegroup) %>%
    summarise(n = n()) %>%
    tibble::add_column(databaseid=databaseId, .before="ingredient")
  
  writeToCsv(age_histogram, file.path(outputFolder, "ageHistogram.csv"))
}

#' TODO better by database not by ingredient
#' @export 
createObservatioPeriodSummaryTable <-function(data,databaseId,outputFolder) {
  # Observation Period distribution by ingredient
  observationPeriod_summary <- data%>%
    group_by(ingredient) %>%
    summarise(
      n = n(),
      avg = mean(observationPeriodDays),
      median = median(observationPeriodDays),
      p5 = quantile(observationPeriodDays, probs = c(0.05)),
      q1 = quantile(observationPeriodDays, probs = c(0.25)),
      q3 = quantile(observationPeriodDays, probs = c(0.75)),
      p95 = quantile(observationPeriodDays, probs = c(0.95)),
      min = min(observationPeriodDays),
      max = max(observationPeriodDays)
    ) %>%
    tibble::add_column(databaseid=databaseId, .before="ingredient")
  writeToCsv(
    observationPeriod_summary,
    file.path(outputFolder, "observationPeriodSummary.csv")
  )
}

#' TODO better by database not by ingredient
#' @export 
createObservatioPeriodHistogramTable <-function(data,databaseId,outputFolder) {
  # Observation period histogram by ingredient
  data$months <-
    cut(
      data$observationPeriodDays,
      breaks = seq(0, max(data$observationPeriodDays) + 30, by = 30),
      include.lowest = TRUE,
      labels = FALSE,
      right = FALSE
    )
  observationPeriodHistogram <- data %>%
    group_by(ingredient, months) %>%
    summarise(n = n()) %>%
    tibble::add_column(databaseid=databaseId, .before="ingredient")
  
  writeToCsv(
    observationPeriodHistogram,
    file.path(outputFolder, "observationPeriodHistogram.csv")
  )
}

#' @export 
createIndicationsTable <- function(data,databaseId,minCellCount,outputFolder) {
  byAgeStrata <- data %>%
    mutate(variable=case_when(
      age < 18 ~ "0-<18",
      (age >= 18 & age <75) ~ "18-75",
      age >= 75 ~ ">=75"
    )) %>%
    group_by(ingredient,formulation,variable)%>%
    summarise(
      total=n(),
      N180_gerd=sum(indication180Gerd>0),
      P180_gerd=N180_gerd*100/total,
      N365_gerd=sum(indication365Gerd>0),
      P365_gerd=N365_gerd*100/total,
      N180_ulcer=sum(indication180Ulcer>0),
      P180_ulcer=N180_ulcer*100/total,
      N365_ulcer=sum(indication365Ulcer>0),
      P365_ulcer=N365_ulcer*100/total,
      N180_zes=sum(indication180Zes>0),
      P180_zes=N180_zes*100/total,
      N365_zes=sum(indication365Zes>0),
      P365_zes=N365_zes*100/total,
      N_unknown=sum(indication180Gerd==0 & 
                      indication365Gerd==0 &
                      indication180Ulcer==0 &
                      indication365Ulcer==0 &
                      indication180Zes==0 &
                      indication365Zes==0),
      P_unknown=N_unknown*100/total
    )
  
  byTotal <- data %>%
    group_by(ingredient,formulation)%>%
    summarise(
      total=n(),
      N180_gerd=sum(indication180Gerd>0),
      P180_gerd=N180_gerd*100/total,
      N365_gerd=sum(indication365Gerd>0),
      P365_gerd=N365_gerd*100/total,
      N180_ulcer=sum(indication180Ulcer>0),
      P180_ulcer=N180_ulcer*100/total,
      N365_ulcer=sum(indication365Ulcer>0),
      P365_ulcer=N365_ulcer*100/total,
      N180_zes=sum(indication180Zes>0),
      P180_zes=N180_zes*100/total,
      N365_zes=sum(indication365Zes>0),
      P365_zes=N365_zes*100/total,
      N_unknown=sum(indication180Gerd==0 & 
                      indication365Gerd==0 &
                      indication180Ulcer==0 &
                      indication365Ulcer==0 &
                      indication180Zes==0 &
                      indication365Zes==0),
      P_unknown=N_unknown*100/total
    ) %>%
    tibble::add_column(variable = "Total", .after = "formulation")
  
  byGender <- data %>%
    rename(variable=gender)%>%
    group_by(ingredient,formulation,variable)%>%
    summarise(
      total=n(),
      N180_gerd=sum(indication180Gerd>0),
      P180_gerd=N180_gerd*100/total,
      N365_gerd=sum(indication365Gerd>0),
      P365_gerd=N365_gerd*100/total,
      N180_ulcer=sum(indication180Ulcer>0),
      P180_ulcer=N180_ulcer*100/total,
      N365_ulcer=sum(indication365Ulcer>0),
      P365_ulcer=N365_ulcer*100/total,
      N180_zes=sum(indication180Zes>0),
      P180_zes=N180_zes*100/total,
      N365_zes=sum(indication365Zes>0),
      P365_zes=N365_zes*100/total,
      N_unknown=sum(indication180Gerd==0 & 
                      indication365Gerd==0 &
                      indication180Ulcer==0 &
                      indication365Ulcer==0 &
                      indication180Zes==0 &
                      indication365Zes==0),
      P_unknown=N_unknown*100/total
    )
  
  table <- bind_rows(byAgeStrata, byTotal,byGender) %>%
    ungroup()%>%
    mutate(formulation=case_when(
      formulation=='No matching concept' ~ 'Unknown',
      TRUE ~ formulation
    ))%>%
    arrange(ingredient, formulation, variable)%>%
    tibble::add_column(databaseid=databaseId, .before="ingredient")
  writeToCsvCensoredStats(table, file.path(outputFolder,"indication.csv"), minValue=minCellCount,indications=TRUE)
}

#' @export 
createHistoryTable <-function(data, databaseId, varName,outputFolder, fileName) {
  myVar <- sym(varName)
  resultTable <- data %>%
    rename(hist={{ myVar }}) %>% 
    mutate(hist=replace(hist,hist>0,1)) %>%
    group_by(ingredient, hist) %>%
    summarise(n = n()) %>%
    mutate(total=sum(n)) %>%
    mutate(freq = n *100 / sum(n)) %>% #note summarise peals of the last grouping variable
    filter(hist==1) %>%
    select(-hist) %>%
    tibble::add_column(databaseid=databaseId, .before="ingredient") 
  
  writeToCsv(
    resultTable,
    file.path(outputFolder, fileName)
  )
}


summariseSet <- function(data, varName, addCumulativeDurationGroup = FALSE, addRatioGroup = FALSE) {
  myVar <- sym(varName)
  if (addCumulativeDurationGroup) {
    result <- data %>% plotly::summarise(
      n = n(),
      excluded = sum(zeros),
      avg = mean({{ myVar }}[{{ myVar }}>0]),
      median=median({{ myVar }}[{{ myVar }}>0]),
      p5 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.05)),
      q1 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.25)),
      q3 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.75)),
      p95 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.95)),
      min = min({{ myVar }}[{{ myVar }}>0]),
      max = max({{ myVar }}[{{ myVar }}>0]),
      n1 = sum(cumulativeDurationGroup[{{ myVar }}>0]=="0-1 Month"),
      n2 = sum(cumulativeDurationGroup[{{ myVar }}>0]=="1-12 Months"),
      n3 = sum(cumulativeDurationGroup[{{ myVar }}>0]=="1-10 Year"),
      n4 = sum(cumulativeDurationGroup[{{ myVar }}>0]=="1>10 Years")
    )
    return(result)
  } 
  if (addRatioGroup) {
    result <- data %>% plotly::summarise(
      n = n(),
      excluded = sum(zeros),
      avg = mean({{ myVar }}[{{ myVar }}>0]),
      median=median({{ myVar }}[{{ myVar }}>0]),
      p5 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.05)),
      q1 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.25)),
      q3 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.75)),
      p95 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.95)),
      min = min({{ myVar }}[{{ myVar }}>0]),
      max = max({{ myVar }}[{{ myVar }}>0]),
      n1 = sum(ratioGroup=="<1",na.rm=TRUE),
      n2 = sum(ratioGroup=="1",na.rm=TRUE),
      n3 = sum(ratioGroup==">1",na.rm=TRUE)
    )
    return(result)
  }
  else {
    result <- data %>% plotly::summarise(
      n = n(),
      excluded = sum(zeros),
      avg = mean({{ myVar }}[{{ myVar }}>0]),
      median=median({{ myVar }}[{{ myVar }}>0]),
      p5 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.05)),
      q1 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.25)),
      q3 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.75)),
      p95 = quantile({{ myVar }}[{{ myVar }}>0],probs=c(0.95)),
      min = min({{ myVar }}[{{ myVar }}>0]),
      max = max({{ myVar }}[{{ myVar }}>0])
    )  
    return(result)
  }
}

#' @export 
createSummaryTable <-function(data,databaseId,varName,minCellCount,outputFolder,fileName, addCumulativeDurationGroup=FALSE,  addRatioGroup=FALSE){
  myVar <- sym(varName)
  
  resultGender <-data %>% mutate(zeros = case_when({{myVar}}<=0 ~ 1,
                                                   {{myVar}}>0 ~ 0 )) 
  resultGender <- resultGender %>% group_by(ingredient,gender)
  
  resultGender <- summariseSet(resultGender,varName,addCumulativeDurationGroup,addRatioGroup) %>%
    rename(value=gender) %>%
    tibble::add_column(variable='gender', .after="ingredient") %>%
    tibble::add_column(order='1')
  
  # Add Total for all gender
  resultAllGender <- data %>% mutate(zeros = case_when({{myVar}}<=0 ~ 1,
                                                       {{myVar}}>0 ~ 0 )) %>%
    group_by_("ingredient")
  resultAllGender <- summariseSet(resultAllGender,varName,addCumulativeDurationGroup,addRatioGroup) %>%
    tibble::add_column(value='Total', .after="ingredient") %>%
    tibble::add_column(variable='gender', .after="ingredient") %>%
    tibble::add_column(order='1')
  
  byGender <- bind_rows(resultGender, resultAllGender) %>% arrange(ingredient,variable)
  
  
  byAgegroup <- data %>% mutate(zeros = case_when({{myVar}}<=0 ~ 1,
                                                  {{myVar}}>0 ~ 0 )) %>%
    group_by(ingredient,agegroup) 
  byAgegroup <- summariseSet(byAgegroup,varName,addCumulativeDurationGroup,addRatioGroup) %>%
    rename(value=agegroup) %>%
    tibble::add_column(variable='agegroup', .after="ingredient") %>%
    tibble::add_column(order='2')
  
  # ensure the agegroups are ordered nunerically
  byAgegroup <- 
    separate(byAgegroup,value,c("startAge",NA),remove=FALSE)
  byAgegroup <- 
    arrange(byAgegroup,ingredient,pad_left(as.character(byAgegroup$startAge))) %>% 
    select(-startAge)
  
  byAdditionalAgegroup <- data %>% mutate(zeros = case_when({{myVar}}<=0 ~ 1,
                                                            {{myVar}}>0 ~ 0 )) %>%
    group_by(ingredient,additional_agegroup)
  byAdditionalAgegroup <- summariseSet(byAdditionalAgegroup,varName,addCumulativeDurationGroup,addRatioGroup) %>%
    rename(value=additional_agegroup) %>%
    tibble::add_column(variable='additional_agegroup', .after="ingredient") %>%
    tibble::add_column(order='3')
  
  ### ADDED
  byICH <- data %>% mutate(zeros = case_when({{myVar}}==0 ~ 1,
                                            {{myVar}}>0 ~ 0 )) %>%
    group_by(ingredient,cumulativeDurationGroup)
  byICH <-summariseSet(byICH,varName,addCumulativeDurationGroup,addRatioGroup)%>%
    rename(value=cumulativeDurationGroup) %>%
    tibble::add_column(variable='ICH_group', .after="ingredient")%>%
    tibble::add_column(order='4')
  
  byFormulation <- data %>% mutate(zeros = case_when({{myVar}}<=0 ~ 1,
                                                     {{myVar}}>0 ~ 0 )) %>%
    group_by(ingredient,formulation) 
  byFormulation <- summariseSet(byFormulation,varName,addCumulativeDurationGroup,addRatioGroup) %>%
    rename(value=formulation) %>%
    mutate(value=replace(value, value=="No matching concept", "Unknown")) %>%
    arrange(value) %>%
    tibble::add_column(variable='formulation', .after="ingredient") %>%
    tibble::add_column(order='5')
  
  
  indicationRow <-function(data, varName,indicationVarName,indicationString) {
    
    indicationVarName <- paste0(indicationVarName, ">0")
    data <- data %>% mutate(zeros = case_when({{myVar}}<=0 ~ 1,
                                              {{myVar}}>0 ~ 0 )) %>%
      group_by_("ingredient", "value"=indicationVarName) 
    data <- summariseSet(data,varName,addCumulativeDurationGroup,addRatioGroup) %>%
      filter(value == TRUE) %>%
      mutate(value=indicationString) %>%
      tibble::add_column(variable='indication', .after="ingredient") %>%
      tibble::add_column(order='6')
    return(data)
  }
  
  # Unknown indication
  unknownIndicationRow <-function(data, varName) {
    data <- data %>% mutate(zeros = case_when({{myVar}}<=0 ~ 1,
                                              {{myVar}}>0 ~ 0 )) %>%
      filter(indication365Gerd==0,indication365Ulcer==0,indication365Zes==0) %>%
      group_by_("ingredient") 
    data <- summariseSet(data,varName,addCumulativeDurationGroup,addRatioGroup) %>%
      mutate(value="Unknown") %>%
      tibble::add_column(variable='indication', .after="ingredient") %>%
      tibble::add_column(order='7')
    return(data)
  }
  byIndication <- bind_rows(indicationRow(data,varName,'indication180Gerd','GERD180'),
                            indicationRow(data,varName,'indication365Gerd','GERD365'),
                            indicationRow(data,varName,'indication180Ulcer','ULCER180'),
                            indicationRow(data,varName,'indication365Ulcer','ULCER365'),
                            indicationRow(data,varName,'indication180Zes','ZEL180'),
                            indicationRow(data,varName,'indication365Zes','ZEL365'),
                            unknownIndicationRow(data,varName)
  )
  
  
  table <- bind_rows(byGender,byAgegroup,byAdditionalAgegroup,byICH,byFormulation,byIndication) %>%
    tibble::add_column(databaseid=databaseId, .before="ingredient")
  
  writeToCsvCensoredStats(table, file.path(outputFolder,fileName), minValue=minCellCount, exposureStrata=addCumulativeDurationGroup,ratioStrata=addRatioGroup)
}

createStrataTable <- function(data,databaseId,varName,minCellCount,outputFolder,fileName){
  
  indicationRow <- function(data, varName, indicationVariable, indicationValue, indicationAgg) {
    getResultTable <- function(data, varName, indicationVariable, indicationValue,indicationAgg,formulationAgg,exposureAgg,ageAgg,genderAgg){
      myVar <- sym(varName)
      grouplist<-c("ingredient","value","formulation","cumulativeDurationGroup","additional_agegroup","gender")
      grouplistBool<-c(TRUE,TRUE,TRUE,TRUE,TRUE,TRUE)
      if(indicationAgg!="none"){grouplistBool[2]<-FALSE}
      if(formulationAgg){grouplistBool[3]<-FALSE}
      if(exposureAgg){grouplistBool[4]<-FALSE}
      if(ageAgg){grouplistBool[5]<-FALSE}
      if(genderAgg){grouplistBool[6]<-FALSE}
      grouplist<-grouplist[grouplistBool]
      result <- data %>% mutate(zeros = case_when({{myVar}}<=0 ~ 1,
                                                  {{myVar}}>0 ~ 0 ))
      if (indicationAgg=="unknown") {result<-result%>%filter(indication365Gerd==0,indication365Ulcer==0,indication365Zes==0)}
      if (indicationAgg=="none") {result<-result%>%mutate(value=get(indicationVariable)>0)}
      result <- result %>%
        group_by_at(grouplist)%>%
        summarise(
          n = n(),
          excluded = sum(zeros),
          avg = mean({{ myVar }}[{{ myVar }}!=0]),
          median=median({{ myVar }}[{{ myVar }}!=0]),
          p5 = quantile({{ myVar }}[{{ myVar }}!=0],probs=c(0.05)),
          q1 = quantile({{ myVar }}[{{ myVar }}!=0],probs=c(0.25)),
          q3 = quantile({{ myVar }}[{{ myVar }}!=0],probs=c(0.75)),
          p95 = quantile({{ myVar }}[{{ myVar }}!=0],probs=c(0.95)),
          min = min({{ myVar }}[{{ myVar }}!=0]),
          max = max({{ myVar }}[{{ myVar }}!=0])
        )
      if (indicationAgg=="none") {
        result <- result %>%
          filter(value == TRUE) %>% ungroup(value) %>% select(-value)
      }
      result <- result %>%
        tibble::add_column(databaseid=databaseId, .before="ingredient")
      if (indicationAgg=="none"){result<-result%>%tibble::add_column(indication = indicationValue, .after = "ingredient")}
      if (indicationAgg=="all"){result<-result%>%tibble::add_column(indication = "All", .after = "ingredient")}
      if (indicationAgg=="unknown"){result<-result%>%tibble::add_column(indication = "Unknown", .after = "ingredient")}
      if (formulationAgg){result<-result%>%tibble::add_column(formulation="All", .after = "indication")}
      if (exposureAgg){result<-result%>%tibble::add_column(cumulativeDurationGroup="Overal exposure", .after = "formulation")}
      if (ageAgg){result<-result%>%tibble::add_column(additional_agegroup="Overal age group", .after = "cumulativeDurationGroup")}
      if (genderAgg){result<-result%>%tibble::add_column(gender="Total", .after = "additional_agegroup")}
      
      return(result)
    }
    
    result<-NULL
    for (formulationAgg in c(TRUE,FALSE)){
      for (exposureAgg in c(TRUE,FALSE)){
        for (ageAgg in c(TRUE,FALSE)){
          for (genderAgg in c(TRUE,FALSE)){
            resTemp<-getResultTable(data, varName,indicationVariable,indicationValue,
                                    indicationAgg,formulationAgg,exposureAgg,ageAgg,genderAgg)
            if(is.null(result)){result<-resTemp}
            else{result=bind_rows(result,resTemp)}
          }
        }
      }
    }
    
    return(result)
  }
  
  tableB <-
    bind_rows(
      indicationRow(data,varName,'indication180Gerd', 'GERD180', indicationAgg = "none"),
      indicationRow(data,varName,'indication365Gerd', 'GERD365', indicationAgg = "none"),
      indicationRow(data,varName,'indication180Ulcer', 'ULCER180', indicationAgg = "none"),
      indicationRow(data,varName,'indication365Ulcer', 'ULCER365', indicationAgg = "none"),
      indicationRow(data,varName,'indication180Zes', 'ZEL180', indicationAgg = "none"),
      indicationRow(data,varName,'indication365Zes', 'ZEL365', indicationAgg = "none"),
      indicationRow(data,varName,'', '', indicationAgg = "unknown"),
      indicationRow(data,varName,'', '', indicationAgg = "all")
    ) 
  
  # sort for display
  
  tableB <-
    tableB %>% mutate(formulation=replace(formulation, formulation=="No matching concept", "Unknown")) %>%
    arrange(
      ingredient,
      indication,
      formulation,
      match(cumulativeDurationGroup, c("0-1 Month","1-12 Months","1-10 Year","1>10 Years","Overal exposure")),
      additional_agegroup,
      gender
    )
  
  writeToCsvCensoredStats(tableB, file.path(outputFolder, fileName),minValue=minCellCount, exposureStrata=FALSE)
}
