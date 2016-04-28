library(dplyr)
library(tidyr)
library(leaflet)
library(rgdal)
library(DT)

# data downloaded from http://data.london.gov.uk/dataset/statistical-gis-boundary-files-london
boroughs<-readOGR(dsn="Data/statistical-gis-boundaries-london/ESRI", layer="London_Borough_Excluding_MHW")

# Cut out unnecessary columns
boroughs@data<-boroughs@data[,c(1,2)]

# transform to WGS884 reference system 
boroughs<-spTransform(boroughs, CRS("+init=epsg:4326"))

# Find the edges of our map
bounds<-bbox(boroughs)

# Get the income data 
income_long<-read.csv("Data/income_long.csv")


function(input, output, session){
  
  getDataSet<-reactive({
    
    # Get a subset of the income data which is contingent on the input variables
    dataSet<-income_long[income_long$Year==input$dataYear & income_long$Measure==input$meas,]
    
    # Copy our GIS data
    joinedDataset<-boroughs
    
    # Join the two datasets together
    joinedDataset@data <- suppressWarnings(left_join(joinedDataset@data, dataSet, by="NAME"))
    
    # If input specifies, don't include data for City of London
    if(input$city==FALSE){
      joinedDataset@data[joinedDataset@data$NAME=="City of London",]$Income=NA
    }
    
    joinedDataset
  })
  
  # Due to use of leafletProxy below, this should only be called once
  output$londonMap<-renderLeaflet({
   
      leaflet() %>%
      addTiles() %>%
      
      # Centre the map in the middle of our co-ordinates
      setView(mean(bounds[1,]),
              mean(bounds[2,]),
              zoom=10 # set to 10 as 9 is a bit too zoomed out
      )       
    
  })
  
  
  
  observe({
    theData<-getDataSet() 
    
    # colour palette mapped to data
    pal <- colorQuantile("YlGn", theData$Income, n = 10) 
   
    # set text for the clickable popup labels
    borough_popup <- paste0("<strong>Borough: </strong>", 
                            theData$NAME, 
                            "<br><strong>",
                            input$meas," 
                            income: </strong>£", 
                            formatC(theData$Income, format="d", big.mark=',')
                            )
    
    # If the data changes, the polygons are cleared and redrawn, however, the map (above) is not redrawn
    leafletProxy("londonMap", data = theData) %>%
      clearShapes() %>%
      addPolygons(data = theData,
                  fillColor = pal(theData$Income), 
                  fillOpacity = 0.8, 
                  color = "#BDBDC3", 
                  weight = 2,
                  popup = borough_popup)  
    
  })
  
  # table of results, rendered using data table
  output$boroughTable <- renderDataTable(datatable({
    dataSet<-getDataSet()
    dataSet<-dataSet@data[,c(1,6)] # Just get name and value columns
    names(dataSet)<-c("Borough",paste0(input$meas," income") )
    dataSet
    },
    options = list(lengthMenu = c(5, 10, 33), pageLength = 5))
  )
    
  # year selecter; values based on those present in the dataset
  output$yearSelect<-renderUI({
    yearRange<-sort(unique(as.numeric(income_long$Year)), decreasing=TRUE)
    selectInput("dataYear", "Year", choices=yearRange, selected=yearRange[1])
  })
}