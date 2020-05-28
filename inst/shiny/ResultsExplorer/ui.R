library(shinydashboard)
library(shiny)
library(DT)
library(plotly)

addInfo <- function(item, infoId) {
  infoTag <- tags$small(
    class = "badge pull-right action-button",
    style = "padding: 1px 6px 2px 6px; background-color: steelblue;",
    type = "button",
    id = infoId,
    "i"
  )
  item$children[[1]]$children <-
    append(item$children[[1]]$children, list(infoTag))
  return(item)
}

dashboardPage(
  dashboardHeader(title = "DUS Results"),
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      ## Tabs
      addInfo(menuItem("About", tabName = "about"), "aboutInfo"),
      addInfo(menuItem("Databases", tabName = "databases"), "databaseInfo"),
      addInfo(menuItem("Incidence Proportion", tabName = "incidenceProportion"), "incidenceProportionInfo"),
      addInfo(menuItem("Prevalence Proportion", tabName = "prevalenceProportion"), "prevalenceProportionInfo"),
      addInfo(menuItem("Analyses", tabName = "results"), "resultsInfo"),
      
      ## Option panel
      conditionalPanel(
        condition = "input.tabs=='results'",
        hr(),
        selectInput("analysis", "Analysis", analyses$analysisName, selected = "Drug Exposure (days)")
      ),
      
      conditionalPanel(
        condition = "input.tabs=='results' && input.resultTabsetPanel != 'Figures'",
        selectInput("database", "Database", databases$databaseId)
      ),
      conditionalPanel(condition = "input.tabs=='incidenceProportion' || input.tabs=='prevalenceProportion'",
                       sliderInput("plotRange", label="Zoom X-axis", min=1990,max=2020,value = c(2010,2020), round = TRUE, dragRange = TRUE)
                       ),
      conditionalPanel(
        condition = "(input.tabs=='results' && input.analysis != 'Renal Impairment' && input.analysis != 'Observation Period') || input.tabs=='incidenceProportion' || input.tabs=='prevalenceProportion'",
        selectInput("ingredient",
                    "Ingredient",
                    ingredients,
                    selected = "Ranitidine")
      ),
      
      conditionalPanel(condition = "input.tabs=='incidenceProportion' || input.tabs=='prevalenceProportion' || (input.tabs == 'results' && input.resultTabsetPanel == 'Figures')",
                       hr(),
                       checkboxGroupInput("databases", "Database", database$databaseId, selected = database$databaseId[1])
      ),
      conditionalPanel(
        condition = "input.tabs=='results' && input.analysis != 'Indications' && input.analysis != 'Renal Impairment' && input.analysis != 'Incidence' && input.analysis != 'Prevalence' && input.analysis != 'Observation Period'",
        hr(),
        p("Additional selectors for second table") 
      ),
      conditionalPanel(
        condition = "input.tabs=='results' && input.analysis != 'Indications' && input.analysis != 'Renal Impairment' && input.analysis != 'Incidence' && input.analysis != 'Prevalence' && input.analysis != 'Observation Period'",
        selectInput("indication",
                    "Indication",
                    indications,
                    selected = "GERD")
      ),
      conditionalPanel(
        condition = "input.tabs=='results' && input.analysis != 'Renal Impairment' && input.analysis != 'Incidence' && input.analysis != 'Prevalence' && input.analysis != 'Observation Period'",
        selectInput("formulation",
                    "Formulation",
                    formulations,
                    selected = "Oral")
      )
    )
  ),
  dashboardBody(
    
    tags$body(tags$div(id="ppitest", style="width:1in;visible:hidden;padding:0px")),
    tags$script('$(document).on("shiny:connected", function(e) {
                                    var w = window.innerWidth;
                                    var h = window.innerHeight;
                                    var d =  document.getElementById("ppitest").offsetWidth;
                                    var obj = {width: w, height: h, dpi: d};
                                    Shiny.onInputChange("pltChange", obj);
                                });
                                $(window).resize(function(e) {
                                    var w = $(this).width();
                                    var h = $(this).height();
                                    var d =  document.getElementById("ppitest").offsetWidth;
                                    var obj = {width: w, height: h, dpi: d};
                                    Shiny.onInputChange("pltChange", obj);
                                });
                            '),
    
    tabItems(
    tabItem(
      tabName = "about",
      br(),
      p(
        "This web-based application provides an interactive platform to explore results of a Drug Utilization Study."
      ),
      h3("Rationale and background"),
      p(
        " Ranitidine is a competitive and reversible inhibitor of the action of histamine and indicated for the
            management of peptic ulceration, Gastro-Esophageal Reflux Disease (GERD), reflux oesophagitis
            and Zollinger-Ellison syndrome."
      ),
      p(
        "Results of a preliminary laboratory analysis have shown the presence of N-Nitrosodimethylamine
            (NDMA), a human carcinogen, in ranitidine. At the request of the European Commission, the EMA’s
            Committee for Medicinal Products for Human Use (CHMP) is evaluating all available data to assess
            whether patients using ranitidine are at any risk from NDMA and whether regulatory action is
            warranted at EU level to protect patients and public health."
      ),
      p(
        " Data about prescribing and use patterns of ranitidine-containing medicines in EU Member States will
            inform on the population at risk of exposure to NDMA (or other nitrosamines) through use of
            ranitidine. It will also provide information on usage patterns for different substances of the class
            informing on usage of substances alternative to ranitidine."
      ),
      p(
        " With this DUS, we aim to determine drug utilisation and prescription patterns of medicinal products
            containing H2-receptor antagonists."
      ),
      h3("Study Limitations"),
      p("First, for this study we will use real world data from electronic health care records. There might exist
        differences between the databases with regard to availability of certain data.
        For this study, we are interested in the indication of use of H2-receptor antagonists (including
        ranitidine) as well as underlying comorbidity in particular with respect to underlying kidney disease.
        Both the indication of use as well as underlying comorbidity might be underreported in the source
        databases.
        Second, as low dose ranitidine is also available as an over the counter (OTC) drug, there is the
        potential of underreporting of ranitidine use. In contrast, as we use prescription and dispensing data,
        we might overestimate the use of ranitidine (and other H2-receptor antagonists) as the actual drug
        intake might be lower.
        Third, as we are using primary care databases, use of H2-receptor antagonists in the Hospital setting
        is lacking.
        Finally, the databases are a subsample of the full population and results should be used with caution
        when attempting to infer the results nation-wide."),
      h3("External links"),
      HTML("<p>Below are links for study-related artifacts that have been made available as part of this study:</p>"),
      HTML("<ul>"),
      HTML("<li>The study is registered: <a href=\"http://www.encepp.eu/encepp/viewResource.htm?id=33398\">EU PASS Register</a></li>"),
      HTML("<li>The full source code for the study will be made available once the study is finalized"),
      HTML("</ul>"),
      h3("Development Status"),
      p(
        " The results in this application are currently under review and should be treated as preliminary at this moment."
      )
    )
    ,
    tabItem(tabName = "databases",
            includeHTML("./html/databasesInfo.html")),
    tabItem(
      tabName = "databases",
      includeHTML("./html/databasesInfo.html")
    ),
    tabItem(tabName = "incidenceProportion",
            box(
              title = "Incidence Proportion", width = NULL, status = "primary",
              checkboxGroupInput(inputId = "ipStratification", 
                                 label = "Stratify by", 
                                 choices = c("Age", "Gender", "Calendar Year"), 
                                 selected = c("Age", "Gender", "Calendar Year"),
                                 inline = TRUE),
              selectInput("yAxisChoiceIp", "Y-Axis scale", c("Auto" = "free_y", "Fixed" = "fixed")),
              htmlOutput("hoverInfoIp"),
              plotOutput("incidenceProportionPlot", height = 700, hover = hoverOpts("plotHoverIp", delay = 100, delayType = "debounce"))
            )
    ),
    tabItem(tabName = "prevalenceProportion",
            box(
              title = "Prevalence Proportion", width = NULL, status = "primary",
              checkboxGroupInput(inputId = "ppStratification", 
                                 label = "Stratify by", 
                                 choices = c("Age", "Gender", "Calendar Year"), 
                                 selected = c("Age", "Gender", "Calendar Year"),
                                 inline = TRUE),
              selectInput("yAxisChoicePp", "Y-Axis scale", c("Fixed" = "fixed", "Auto" = "free_y")),
              htmlOutput("hoverInfoPp"),
              plotOutput("prevalenceProportionPlot", height = 700, hover = hoverOpts("plotHoverPp", delay = 100, delayType = "debounce"))
            )
    ),
    
    tabItem(
      tabName = "results",
      
      tabsetPanel(
        id = "resultTabsetPanel",
        
        tabPanel(
          "Tables",
          br(),
          textOutput("tableATitle"),
          br(),
          
          conditionalPanel(condition = "input.analysis != 'Indications' && input.analysis != 'Renal Impairment'",
                           dataTableOutput("TableA")),
          conditionalPanel(condition = "input.analysis == 'Indications'",
                           dataTableOutput("Table6A")),
          conditionalPanel(condition = "input.analysis == 'Renal Impairment'",
                           dataTableOutput("Table7A")),
          hr(),
          textOutput("tableBTitle"),
          br(),
          dataTableOutput("TableB")
        ),
        
        tabPanel(
          "Figures",
          br(),
          conditionalPanel(condition = "input.analysis == 'Observation Period'",
                           p("Figure 7: Observation Period per database"),
                           br(),
                           girafeOutput("observationPeriodHistogram", height = "100%")),
          
          
          conditionalPanel(
            condition = "input.analysis != 'Observation Period'",
            
            textOutput("FigureTitle"),
            br(),
            plotOutput("BoxplotBxp", height = 700),
            plotlyOutput("BoxplotPlotly")
          )
          
        )
      )
    )
  )
  )
)