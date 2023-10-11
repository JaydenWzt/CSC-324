#   project description:
#   This project aims to visualize the data related to the COVID-19. current, the plan involves creating:
#   
#   1) Two global maps accompanied with adjustable timeline to display the monthly cases of death and new cases for each nation.
#   Learning from: https://rviews.rstudio.com/2019/10/09/building-interactive-world-maps-in-shiny/#:~:text=Creating%20an%20interactive%20world%20map&text=The%20inputs%20to%20this%20function,the%20aesthetics%20of%20the%20plot.
#   
#   2) Two scatter plots exploring the degree of different actions (vaccination/testing policies) taken by each government and the correlated total COVID death for each country 


## Libraries used
library(magrittr)
library(rvest)
library(readxl)
library(plyr)
library(dplyr)
library(maps)
library(ggplot2)
library(reshape2)
library(shiny)
library(ggiraph)
library(RColorBrewer)
library(countrycode)
library(wbstats)
library(tidyr)
library(rsconnect)
library(lubridate)

##Reading in the three data sets containing data I'm interested in

# The data set contains a relatively thorough list of COVID cases and deaths for most countries at a daily basis
world_covid_data <- read.csv('./Dataset/full_data.csv')
# The data set contains population for each country, some are split into regions in the country
world_pop_data <- read.csv('./Dataset/master_location_pop_table.csv')
# The data set contains a variety of indicators for the actions taken by each country to against COVID
# I'm only interested in "H2_Testing.policy" and "H7_Vaccination.policy"
gov_re_data <- read.csv('./Dataset/OxCGRT_latest.csv')



## Reading in two extra data sets to assist the visualization of the world map]

# Import ISO3 to match countries
iso_codes = countrycode::codelist[, c("un.name.en", "iso3c")]
names(iso_codes) = c("Country", "ISO3")


# Get the world data with geograpical coordinates directly from package *ggplot2*
world_data <- ggplot2::map_data('world')
world_data <- fortify(world_data)

# Trying to match with ISO3
world_data$region[world_data$region == 'USA'] <- 'United States of America'
world_data$region[world_data$region == 'UK'] <- 'United Kingdom of Great Britain and Northern Ireland'
world_data$region[world_data$region == 'North Korea'] <- 'Democratic People’s Republic of Korea'
world_data$region[world_data$region == 'South Korea'] <- 'Republic of Korea'
world_data$region[world_data$region == 'Russia'] <- 'Russian Federation'
world_data$region[world_data$region == 'Laos'] <- 'Lao People’s Democratic Republic'
world_data$region[world_data$region == 'Iran'] <- 'Iran (Islamic Republic of)'

# Add ISO3 code to "world_data"
world_data["ISO3"] <- iso_codes$ISO3[match(world_data$region, iso_codes$Country)]
df <- world_data[!duplicated(world_data$region), ]



## Clean all three data sets and make new ones that containing the data I'm interested in, preparing to combine them

#processing world_pop_data
world_pop_data_clean <- world_pop_data %>%
  group_by(country_short_name) %>%
  summarise(geo_region_population_count = sum(geo_region_population_count)) %>%
  rename('country' = 'country_short_name')
# Only kept 'geo_region_population_count', all changed to national level. Other data excluded.

# match with ISO3 code
world_pop_data_clean$country[world_pop_data_clean$country == 'United States'] <- 'United States of America'

# Processing world_covid_data
# This is the data set containing COVID cases and deaths data at a monthly basis
monthly_new_covid <- world_covid_data %>%
  mutate(Period = paste(substr(date, 1, 4), 
                        substr(date, 6, 7), 
                        sep = '')) %>%
  group_by(location, Period) %>%
  reframe('Cases'= sum(new_cases, na.rm = TRUE), 
          'Deaths' = sum(new_deaths, na.rm = TRUE)) %>%
  rename('Country' = 'location')

# Deaths is in thousands and cases is in ten thousands
monthly_new_covid <- monthly_new_covid[order(monthly_new_covid$Period), ]
monthly_new_covid[monthly_new_covid == 0] <- NA
monthly_new_covid["Deaths in thousands"] <- monthly_new_covid$Deaths/1000
monthly_new_covid["Cases in ten thousands"] <- monthly_new_covid$Cases/10000

# Matching with ISO3 code
monthly_new_covid$Country[monthly_new_covid$Country == 'USA'] <- 'United States of America'
monthly_new_covid$Country[monthly_new_covid$Country == 'UK'] <- 'United Kingdom of Great Britain and Northern Ireland'
monthly_new_covid$Country[monthly_new_covid$Country == 'North Korea'] <- 'Democratic People’s Republic of Korea'
monthly_new_covid$Country[monthly_new_covid$Country == 'South Korea'] <- 'Republic of Korea'
monthly_new_covid$Country[monthly_new_covid$Country == 'Russia'] <- 'Russian Federation'
monthly_new_covid$Country[monthly_new_covid$Country == 'Laos'] <- 'Lao People’s Democratic Republic'
monthly_new_covid$Country[monthly_new_covid$Country == 'Iran'] <- 'Iran (Islamic Republic of)'

# Format the Period column to "Mon YYYY" from YYYYMM
monthly_new_covid$Period <- ym(monthly_new_covid$Period)
monthly_new_covid$Period <- format(monthly_new_covid$Period, "%b %Y")


# Until noew, new cases and new death are adjusted to monthly level.
# Besides that, "Country" and "Period" are kept and the rest columns excluded.
# this data frame still contain data at levels other than national. 
# These data will keep remain here until I match the 'Country' in in this data frame with 'country_short_name' in world_pop_data_clean. 
# 'Country' not included in 'country_short_name' will be excluded.


#processing gov_re_data
gov_policies_eval <- gov_re_data %>%
  group_by(CountryName) %>%
  reframe(testing_policy = mean(H2_Testing.policy, na.rm = TRUE), 
          vaccination_policy = mean(H7_Vaccination.policy, na.rm = TRUE)) %>%
  rename('country' = 'CountryName')
gov_policies_eval[gov_policies_eval == 0] <- NA
# I choose only to look at the effects of testing policy and vaccination policy for each country.


##'country' not existed in 'world_pop_data_clean' will be excluded

# In 'total_covid_death', exclude observations that has 'country' not in 'world_pop_data_clean'
total_covid_death <- total_covid_death %>%
  filter(country %in% world_pop_data_clean$country)

# In 'monthly_new_covid', exclude observations that has 'country' not in 'world_pop_data_clean'
monthly_new_covid <- monthly_new_covid %>%
  filter(Country %in% world_data$region)

# In 'gov_policies_eval', exclude observations that has 'country' not in 'world_pop_data_clean'
gov_policies_eval <- gov_policies_eval %>%
  filter(country %in% world_pop_data_clean$country)

# Feed back all the three cleaned data sets to 'world_pop_data_clean' so all four data sets have identical 'country' entries
world_pop_data_clean <- world_pop_data_clean %>%
  filter(country %in% gov_policies_eval$country) %>%
  filter(country %in% total_covid_death$country)


## Combine different data sets
# create a new data frame named covid_death_with_policy that have total_covid_death and gov_policies_eval combined
covid_death_with_policy <- total_covid_death %>%
  # Adding in world_pop_data_clean
  merge(world_pop_data_clean, by = 'country') %>%
  # Adding in gov_policies_eval
  merge(gov_policies_eval, by = 'country') %>%
  # Death are adjusted to death per million
  mutate(death_per_m = (total_deaths/geo_region_population_count)*1000000) %>%
  filter(not(death_per_m %in% Inf)) %>%
  # Exclude useless columns
  select(-c(total_deaths, geo_region_population_count)) %>%
  # Rounding decimals to increase readability
  mutate(across(where(is.numeric), ~round(., 2))) %>%
  mutate(death_per_m = round(.$death_per_m, 0)) 

# Reframe "monthly_new_covid" so death and case forms a new column, with the correspondent number in another column
monthly_new_covid <- monthly_new_covid %>%
  pivot_longer(cols = c('Cases in ten thousands', 'Deaths in thousands'), names_to = 'DataType') %>%
  rename('Value' = 'value') 

# Add ISO3 code to "monthly_new_covid" for ploting world map
monthly_new_covid['ISO3'] <- iso_codes$ISO3[match(monthly_new_covid$Country, iso_codes$Country)]

# Until now, all data processing have ended. All data frames are cleans. 
# The two of them I will be using to draw plots are 'monthly_covid_data' and 'covid_death_with_policy'


## Creating an interactive world map
worldMaps <- function(df, world_data, data_type, period){
  
  # Function for setting the aesthetics of the plot
  my_theme <- function () { 
    theme_bw() + theme(axis.title = element_blank(),
                       axis.text = element_blank(),
                       axis.ticks = element_blank(),
                       panel.grid.major = element_blank(), 
                       panel.grid.minor = element_blank(),
                       panel.background = element_blank(), 
                       legend.position = "bottom",
                       panel.border = element_blank(), 
                       strip.background = element_rect(fill = 'white', colour = 'white'))
  }
  
  # Select only the data that the user has selected to view
  plotdf <- df[df$DataType == data_type & df$Period == period,]
  plotdf <- plotdf[!is.na(plotdf$ISO3), ]
  
  # Add the data the user wants to see to the geographical world data
  world_data['DataType'] <- rep(data_type, nrow(world_data))
  world_data['Period'] <- rep(period, nrow(world_data))
  world_data['Value'] <- plotdf$Value[match(world_data$ISO3, plotdf$ISO3)]
  
  # Create caption with the data source to show underneath the map
  capt <- paste0("Source: data.world")
  
  # Specify the plot for the world map
  library(RColorBrewer)
  library(ggiraph)
  g <- ggplot() + 
    geom_polygon_interactive(data = subset(world_data, lat >= -60 & lat <= 90), color = 'gray70', size = 0.1,
                             aes(x = long, y = lat, fill = Value, group = group, 
                                 tooltip = sprintf("%s<br/>%s", ISO3, Value))) + 
    scale_fill_gradientn(colours = brewer.pal(5, "Reds"), na.value = 'white') + 
    labs(fill = data_type, color = data_type, title = NULL, x = NULL, y = NULL, caption = capt) + 
    my_theme()
  
  return(g)
}


## Building an R Shiny app
shinyApp(
  
  ## The ui of the app, with three pages
  ui = navbarPage("COVID-19 Data",
                  # The first page is the world map showing monthly COVID data
                  tabPanel("World Map",
                           fluidPage(
                             
                             # App title
                             titlePanel("Monthly COVID-19 Cases and Deaths Data"),
                             
                             # Sidebar layout with input and output definitions
                             sidebarLayout(
                               
                               # Sidebar panel for inputs 
                               sidebarPanel(
                                 
                                 # First input: Type of data
                                 selectInput(inputId = "data_type",
                                             label = "Choose the type of COVID-19 data you want to see:",
                                             choices = list("Cases in ten thousands" = "Cases in ten thousands", "Deaths in thousands" = "Deaths in thousands")),
                                 
                                 # Second input (choices depend on the choice for the first input)
                                 uiOutput("secondSelection"),
                                 
                               ),
                               
                               
                               # Main panel for displaying the world map
                               mainPanel(
                                 # Hide errors
                                 tags$style(type = "text/css",
                                            ".shiny-output-error { visibility: hidden; }",
                                            ".shiny-output-error:before { visibility: hidden; }"),
                                 # make the world map
                                 girafeOutput("distPlot")
                               )
                             )
                           )
                  ),
                  
                  # The second page on the relationship between testing policies and COVID deaths
                  tabPanel("Testing vs. COVID-19 Deaths",
                           fluidPage(
                             
                             titlePanel("Correlation Between Testing Indicator and COVID-19 Death"),
                           
                             sidebarLayout(position = "right",
                                           sidebarPanel(
                                             tags$p("Description:"),
                                             tags$p("Each dot in the plot represents a country."),
                                             tags$p("The x-axis indicates the efficacy of the COVID-19 testing policy implemented by each country, with higher numbers indicating more effective policies."),
                                             tags$p("The y-axis represents the total number of COVID-19-related deaths in each country.")),
                                           
                                           # Main panel for displaying outputs
                                           mainPanel(
                                                    # Hide errors
                                                    tags$style(type = "text/css",
                                                        ".shiny-output-error { visibility: hidden; }",
                                                        ".shiny-output-error:before { visibility: hidden; }"),
                                                    # Make the scatter plot
                                                    plotOutput("scatterPlotTesting")
                                           ))

                           )
                  ),
                  
                  # The third page on the relationship between vaccination policies and COVID deaths
                  tabPanel("Vaccination vs. COVID-19 Deaths",
                           fluidPage(
                             
                             titlePanel("Correlation Between Vaccination Indicator and COVID-19 Death"),
                             
                             sidebarLayout(position = "right",
                                           sidebarPanel(
                                             tags$p("Description:"),
                                             tags$p("Each dot in the plot represents a country."),
                                             tags$p("The x-axis indicates the efficacy of the COVID-19 vaccination policy implemented by each country, with higher numbers indicating more effective policies."),
                                             tags$p("The y-axis represents the total number of COVID-19-related deaths in each country.")),
                                           
                                           # Main panel for displaying outputs
                                           mainPanel(
                                             # Hide errors
                                             tags$style(type = "text/css",
                                                        ".shiny-output-error { visibility: hidden; }",
                                                        ".shiny-output-error:before { visibility: hidden; }"),
                                             # Make the scatter plot
                                             plotOutput("scatterPlotVaccine")
                                           ))
                           )
                  ),
  ),
  
  # Define the server
  server = function(input, output) {
    
    # Create the interactive world map
    output$distPlot <- renderGirafe({
      ggiraph(code = print(worldMaps(monthly_new_covid, world_data, input$data_type, input$period)))
    })
    
    # Change the choices for the second selection on the basis of the input to the first selection
    output$secondSelection <- renderUI({
      choice_second <- as.list(unique(monthly_new_covid$Period[which(monthly_new_covid$DataType == input$data_type)]))
      selectInput(inputId = "period", choices = choice_second,
                  label = "Choose the period for which you want to see the data:")
    })
    
    comments1 <- c("Each dot represents a country",
                   "The x-axis indicates the efficacy of the COVID-19 testing policy implemented by each country, with higher numbers indicating more effective policies.",
                   "The y-axis represents the total number of COVID-19-related deaths in each country")
    # Create the scatter plot of testing vs death
    output$scatterPlotTesting <- renderPlot({
      ggplot(covid_death_with_policy, aes(x = testing_policy, 
                                          y = death_per_m)) + 
        geom_point() + 
        theme_minimal() +
        # Regression line
        geom_smooth(method = "lm", se = FALSE, color = "red") +
        xlab("Testing Policy In Each Country") +
        ylab("Total Deaths per Million") +
        labs(caption = "Source: data.world") +
        theme(axis.title.x = element_text(size = 14)) +
        theme(axis.title.y = element_text(size = 14)) +
        theme(plot.caption = element_text(size = 12)) 
        
    })
    
    # Craeting the scatter plot of vaccine vs death
    output$scatterPlotVaccine <- renderPlot({
      ggplot(covid_death_with_policy, aes(x = vaccination_policy,
                                          y = death_per_m)) + 
        geom_point() + 
        theme_minimal() +
        # Regression line
        geom_smooth(method = "lm", se = FALSE, color = "red") +
        xlab("Vaccination Policy In Each Country") +
        ylab("Total Deaths per Million") +
        labs(caption = "Source: data.world") +
        theme(axis.title.x = element_text(size = 14)) +
        theme(axis.title.y = element_text(size = 14)) +
        theme(plot.caption = element_text(size = 12))
    })
    
  },
  
  options = list(height = 600)
  
)
