library(shinydashboard)
library(leaflet)
library(DT)

header<-dashboardHeader(title="London")
sidebar<-dashboardSidebar()

body<-dashboardBody(
  fluidRow(
    column(width = 9,
           box(width = NULL, solidHeader = TRUE,
               leafletOutput("londonMap", height=300)
               ),
           box(width=NULL,
               dataTableOutput("boroughTable")
           )
    ),
    column(width=3,
           box(width=NULL, 
               uiOutput("yearSelect"),
               radioButtons("meas", "Measure",c("Mean"="Mean", "Median"="Median")),
               checkboxInput("city", "Include City of London?",TRUE)
               
               )
           )
    )
)

dashboardPage(
  header,
  dashboardSidebar(disable = TRUE),
  body
)