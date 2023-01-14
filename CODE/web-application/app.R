#### Script Information ####

# Team 105
# app.R

# This is the code for our interactive web application hosted on shinyapps.io.
# We define server-side and client-side logic through the Shiny framework to
# host our web app. While this is R, model development can be in any language.

#### Setup ####

library(dplyr)
library(glue)
library(leaflet)
library(leaflet.extras)
library(magrittr)
library(Rcpp)
library(shiny)
set.seed(123)

# Load C++ functions and model
Rcpp::sourceCpp("model-production/predict_forest.cpp")
model <- readr::read_rds("model-production/model.Rds")

#### Create Data ####

# Some fake images
imgs <- c(
  "https://www.paulland.com/public/images/Retail.jpg",
  "https://tribecacitizen.com/wp-content/uploads/2021/01/378-Greenwich-1.jpg",
  "https://groco.com/wp-content/uploads/2019/07/image-asset.jpeg",
  "https://www.dmcounsel.com/hubfs/Commercial%20Real%20Estate.jpg"
)

# Encode categories
cats <- tibble::tribble(
  ~ name, ~ nicename,
  "0", "Apparel & Accessory Stores",
  "1", "Automotive Dealers & Service Stations",
  "2", "Building Materials & Hardware",
  "3", "Eating & Drinking Places",
  "4", "Electronics, Applicances & Music Stores",
  "5", "Food Stores",
  "6", "General Merchandise",
  "7", "Home Furniture & Furnishing Stores",
  "8", "Miscellaneous Retail",
  "9", "Services"
)

# Create binding dataframe for output app
binder <- purrr::map_dfc(1:9, ~ tibble::tibble("{.x}" := numeric()))

# Read in business data
businesses <-
  readr::read_rds("model-production/data.Rds") %>%
  dplyr::filter(
    latitude > 30,
    latitude < 37,
    longtitude < -75,
    longtitude > -90
  ) %>%
  dplyr::mutate(img = sample(imgs, nrow(.), replace = TRUE))

#### Define User Interface ####

ui <- shiny::navbarPage(
  
  # Setup theme and style
  title = tags$text(tags$i(tags$strong(
    "Stratus", .noWS = "outside"), "Here", .noWS = "outside"), "🌎"),
  theme = shinythemes::shinytheme("flatly"),
  tags$style(
    "@import url('https://fonts.googleapis.com/css?family=Open Sans');

    .table {
      font-size: 12px;
    }

    .navbar {height: 60px;}

    .tipimg {
      width: 250px;
      border: 7px solid white;
    }

    .tblimg {
      width: 80px;
      border-radius: 5px;
    }

    .navbar-brand {
      font-family: 'Open Sans';
      font-size: 22px;
    }

    body {
      background: #ebebeb;
      font-size: 16px;
      font-family: 'Open Sans';
    }

    .well {
      background: white;
      border-radius: 5px;
      box-shadow: 0 0px 50px -30px;
    }"
  ),
  
  shiny::tabPanel(
    title = "Location Engine",
    
    shiny::sidebarLayout(
      
      # Sidebar with inputs and table
      shiny::sidebarPanel(
        
        width = 4,
        shiny::tabsetPanel(
          shiny::tabPanel(
            title = "Filters",
            tags$br(),
            htmltools::HTML(
              "Welcome to StratusHere! Provide an annual sales estimate and ",
              "business category. Our model will fill in the rest and ",
              "categorize available properties into great, good, and okay."
            ),
            tags$hr(),
            shiny::numericInput(
              inputId = "sales",
              label = "Annual Sales ($)",
              min = 0, max = 2e8,
              value = 100000
            ),
            shiny::selectizeInput(
              inputId = "zip",
              label = "Zip Code",
              choices = unique(businesses$ZIP),
              multiple = FALSE,
              selected = "30101"
            ),
            shiny::selectInput(
              inputId = "cat",
              label = "Business Category",
              choices = cats$nicename,
              selected = cats$nicename[1]
            ),
            shiny::radioButtons(
              inputId = "heat_dot", label = "Choose View",
              choices = c("Locations", "Heat Map"),
              selected = "Locations", inline = TRUE
            ),
            htmltools::HTML(
              "🟢 Great location for your business<br>",
              "🟡 Good location for your business<br>",
              "🔴 Okay location for your business<br>"
            )
          ),
          shiny::tabPanel(
            title = "Locations", tags$br(),
            DT::DTOutput("table")
          )
        )
      ),
      
      # Show map
      shiny::mainPanel(
        width = 8,
        shiny::wellPanel(
          leaflet::leafletOutput(
            outputId = "map",
            height = "650px"
          )
        )
      )
    )
  )
)

#### Define Server ####

server <- function(input, output) {
  
  # Filter data to user inputs
  df_filter <- shiny::reactive({

    # Filter to zip code
    filtered <-
      businesses %>%
      dplyr::filter(ZIP == input$zip) %>%
      dplyr::mutate(sales = input$sales)
    
    # Pivot data for prediction
    filtered_pivot <- purrr::map(1:nrow(filtered), ~ filtered[.x, ])
    
    # Predict forest and determine status
    if (nrow(filtered) > 0) {
      predict_forest(model, filtered_pivot) %>%
        dplyr::bind_rows(binder) %>%
        dplyr::mutate(id = dplyr::row_number()) %>%
        tidyr::pivot_longer(cols = -id) %>%
        dplyr::left_join(y = cats,  by = "name") %>%
        dplyr::filter(nicename == input$cat) %>%
        dplyr::select(id, value) %>%
        tidyr::replace_na(list(value = 0)) %>%
        dplyr::mutate(
          med_val = median(value),
          status = dplyr::case_when(
            value < med_val ~ "Okay",
            value == med_val ~ "Good",
            value > med_val ~ "Great"
          )
        ) %>%
        dplyr::select(status) %>%
        dplyr::bind_cols(filtered)
    } else {
      data.frame(
        status = "",
        latitude = NA,
        longtitude = NA
      )
    }
      
  })
  
  # Render map
  output$map <- leaflet::renderLeaflet({
    
    # Get filtered data
    df <- df_filter()
    gg <- dplyr::filter(df, status != "Okay")

    # Create base map
    prop_map <-
      leaflet::leaflet() %>%
      leaflet::addProviderTiles(
        provider = leaflet::providers$Stamen.Terrain
      ) %>%
      leaflet::setView(
        lat = dplyr::coalesce(mean(df$latitude), 33.8),
        lng = dplyr::coalesce(mean(df$longtitude), -84.4),
        zoom = 11.5
      )
    
    # Add markers if rows exist
    if (nrow(df) > 0 & input$zip != "" & input$heat_dot == "Locations") {
      prop_map <-
        prop_map %>%
        leaflet::addCircleMarkers(
          lat = df$latitude,
          lng = df$longtitude,
          opacity = 1,
          fillColor = dplyr::case_when(
            df$status == "Great" ~ "#00D26A",
            df$status == "Good" ~ "#FCD53F",
            df$status == "Okay" ~ "#F8312F"
          ),
          fillOpacity = 1,
          color = "white",
          weight = 2,
          radius = 8,
          label = lapply(glue::glue(
            "<img src='{df$img}' class='tipimg'><br>",
            "<strong>Zip:</strong> {df$ZIP}<br>",
            "<strong>Lat:</strong> {round(df$latitude, 2)}<br>",
            "<strong>Long:</strong> {round(df$longtitude, 2)}<br>",
            "<strong>{df$status} location for your business.</strong>"
          ), htmltools::HTML),
          labelOptions = leaflet::labelOptions(
            style = list(
              "padding" = "-5px",
              "font-face" = "bold",
              "font-family" = "Open Sans",
              "border-radius" = "5px",
              "font-size" = "16px"
            )
          )
        )
    } else if (nrow(gg) > 0 & input$zip != "" & input$heat_dot == "Heat Map") {
      prop_map <-
        prop_map %>%
        leaflet.extras::addHeatmap(
          lat = gg$latitude,
          lng = gg$longtitude,
          blur = 20, radius = 15
        )
    }
    
    # Construct message for no records
    msg_0 <- dplyr::if_else(nrow(df) == 0, ", try editing filters", "")
    print_row <- dplyr::if_else(df$status == "", 0L, nrow(df))[1]
    
    # Post final map
    prop_map %>%
      leaflet::addControl(
        html = tags$strong(glue::glue("{print_row} locations found{msg_0}")),
        position = "topright"
      )
    
  })
  
  # Build a table of properties
  output$table <- DT::renderDT({
    df_filter() %>%
      dplyr::transmute(
        Image = glue::glue("<img src='{img}' class='tblimg'>"),
        Lat = round(latitude, 2),
        Long = round(longtitude, 2),
        Zip = ZIP, Status = dplyr::case_when(
          status == "Great" ~ "🟢",
          status == "Good"  ~ "🟡",
          status == "Okay"  ~ "🔴"
        )
      ) %>%
      DT::datatable(
        escape = FALSE,
        class = "table",
        options = list(dom = "ftp", pageLength = 5),
        rownames = FALSE
      )
  })
  
}

# Run the application
shiny::shinyApp(ui = ui, server = server)
