library(dplyr)
library(tidyr)
library(leaflet)
library(rgdal)
library(DT)

# data from http://data.london.gov.uk/dataset/statistical-gis-boundary-files-london
boroughs<-readOGR(dsn="Data/statistical-gis-boundaries-london/ESRI", layer="London_Borough_Excluding_MHW")

# Cut out unnecessary columns
boroughs@data<-boroughs@data[,c(1,2)]
# transform to correct format
boroughs<-spTransform(boroughs, CRS("+init=epsg:4326"))
bounds<-bbox(boroughs)

income_long<-read.csv("Data/income_long.csv")


function(input, output, session){
  
  getDataSet<-reactive({
    dataSet<-income_long[income_long$Year==input$dataYear & income_long$Measure==input$meas,]
    joinedDataset<-boroughs
    joinedDataset@data <- suppressWarnings(left_join(joinedDataset@data, dataSet, by="NAME"))
    if(input$city==FALSE){
      joinedDataset@data[joinedDataset@data$NAME=="City of London",]$Income=NA
    }
    
    joinedDataset
  })
  
  
  output$londonMap<-renderLeaflet({
   
  
    leaflet() %>%
      addTiles() %>%
      
      setView(mean(bounds[1,]),
              mean(bounds[2,]),
              zoom=10 # set to 10 as 9 is a bit too zoomed out
      )       
    
  })
  
  
  
  observe({
    theData<-getDataSet()   
    
    pal <- colorQuantile("YlGn", theData$Income, n = 10) # colour palette using ColorBrewer
   
    borough_popup <- paste0("<strong>Borough: </strong>", 
                            theData$NAME, 
                            "<br><strong>",input$meas," income: </strong>£", 
                            formatC(theData$Income, format="d", big.mark=','))
    
    
    
    
    leafletProxy("londonMap", data = theData) %>%
      clearShapes() %>%
      addPolygons(data = theData,
                  fillColor = pal(theData$Income), 
                  fillOpacity = 0.8, 
                  color = "#BDBDC3", 
                  weight = 2,
                  popup = borough_popup)  
    
  })
  
  
  
  
 
    output$boroughTable <- renderDataTable(datatable({
      dataSet<-getDataSet()
      dataSet<-dataSet@data[,c(1,6)]
      names(dataSet)<-c("Borough",paste0(input$meas," income") )
      dataSet
    })options = list(lengthMenu = c(5, 30, 50), pageLength = 5))
    )
  
  
  output$yearSelect<-renderUI({
    yearRange<-sort(unique(as.numeric(income_long$Year)), decreasing=TRUE)
   
    selectInput("dataYear", "Year", choices=yearRange, selected=yearRange[1])
  })
}