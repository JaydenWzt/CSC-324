# COVID-19 Data App

## Description

Welcome to my project! This GitHub repository contains the following:
* The source code for the implementation of this COVID-19 project, including a Shiny Web App file and an R Markdown file (the Shiny app is more up-to-date).
* The three datasets used (sourced from data.world).
* A description of the three datasets.
* A time log.
* A screenshot of the created world map.
* A chart created in R for the time log.


## About the App

* Accessing the App:
    You can either run the source code locally or access the app via this link: https://zitan-wangj.shinyapps.io/IndividualProject/

* App Description:
    The app consists of three pages: one world map and two scatter plots.
    * Page One: This page features a world map with a sidebar. From the sidebar, users can select whether they wish to view COVID-19 cases or deaths on the world map and specify the desired month, ranging from Jan 2020 to Mar 2023. For example, if a user selects COVID-19 cases for Mar 2021, the aggregated number of COVID-19 cases for March 2021 will be displayed on the map for each country. The intensity of the color (redder) indicates the severity of COVID-19 in that country. 
    * Page Two: This page displays a scatter plot. Each dot represents a country. The x-axis indicates the efficacy of the COVID-19 testing policy implemented by each country, with higher numbers indicating more effective policies. The y-axis represents the total number of COVID-19-related deaths in each country.
    * Page Three: This page is similar to the second but focuses on vaccination policies. The x-axis represents the effectiveness of the COVID-19 vaccination policy in each country, and the y-axis indicates the total number of COVID-19-related deaths.

## Project Documentation

* Project Purpose: 
    The primary goal of this project is to study global COVID-19 data.

* Data Description: 
    The descriptions of the three datasets are provided in the **Data description.pdf** file. All datasets were sourced from data.world.

* Users of This Project: 
    The app targets anyone interested in COVID-19 data, especially those keen on understanding the impact of vaccination and testing policies on COVID-19 outcomes, as well as the geographical and chronological progression of the pandemic.

* Questions Trying to Answer: 
    The project seeks to answer four specific questions:
    * Is there a geographical pattern to the global spread of COVID-19?
    * How have the numbers of COVID-19 cases and deaths changed over time?
    * Overall, have COVID-19 vaccinations been effective in preventing deaths from the virus?
    * Overall, have COVID-19 testing been effective in preventing deaths from the virus?

* Insights
    * There are three peaks of COVID-19 infection: September 2020, May 2021 and March 2022.
    * There are several countries that first started pay attention to COVID-19, including China, India, Canada, Australia, etc. 
    * COVID-19 has impacted almost every country, indicating its status as a global pandemic.
    * There doesn't appear to be a strong correlation between a country's COVID-19 policies and its death rate when comparing different countries.

* Wishlist
    * For the world map, it would be beneficial to have a time axis. This would allow users to manually drag and view data at different times or enable an animation that automatically displays data progression from past to present.
    * The scatter plots currently use generalized data. Given the internal complexities within countries and how that differ between countries, assuming all countries the same might not be as insightful. It might be more beneficial to delve deeper into each country, examining local COVID-19 deaths and local government policies over time.

* Process and Development of the App
    The process of making this app can be summarized into the following steps:
    * Data Loading:
        Three primary datasets are read into the environment:
        * **world_covid_data**(loaded from **full_data.csv**): Contains daily COVID-19 cases and deaths for most countries.
        * **world_pop_data**(loaded from **master_location_pop_table.csv**): Provides population data for each country.
        * **gov_re_data**(loaded from **OxCGRT_latest.csv**): Contains various indicators reflecting actions taken by countries against COVID-19.
        Additionally, helper datasets like ISO3 country codes and geographical coordinates are loaded to aid in visualizations.
    * Data Cleaning and Transformation:
        * Data mismatches are resolved to some extent, especially for country names.
        * The daily data from **world_covid_data** is aggregated to a monthly level to create **monthly_new_covid**.
        * Only relevant columns, "H2_Testing.policy" and "H7_Vaccination.policy", from **gov_re_data** are retained to produce **gov_policies_eval**.
        * Population data in **world_pop_data** is summarized at the national level to form **world_pop_data_clean**.
        * Any countries not present in the **world_pop_data_clean** dataset are filtered out from the other datasets to ensure consistency.
    * Data Combination: 
        * The cleaned datasets are merged to create a comprehensive dataset named **covid_death_with_policy**. This dataset contains information about total deaths, testing policies, vaccination policies, and population size for each country.
    * Visualization Function:
        * A function named**worldMaps** is defined to produce interactive world maps based on user input for data type and time period.
    * R Shiny App Development:
        * The User Interface (ui): A multi-page setup is created using navbarPage. The first page allows users to interact with world maps showing monthly COVID-19 data. The other two pages visualize the relationships between testing/vaccination policies and COVID-19 deaths using scatter plots.
        * The Server Logic (server): Defines how data is processed and visualized based on user input. It renders the interactive world map and the scatter plots based on the selections.
    * App Execution:
        * The app is executed using shinyApp, which combines the user interface and server logic.

* What-Why-How Analysis Framework:
    * What (The Nature of the Data):
        * Datasets and Attributes:
            * Three primary datasets: **world_covid_data**, **world_pop_data**, and **gov_re_data**.
            * Derived datasets like **monthly_new_covid** and **covid_death_with_policy**.
            * Attributes include country names, COVID-19 cases, deaths, testing policies, vaccination policies, and population size.
        * Dataset Types:
            * Tables: All datasets are essentially tables with rows (items) and columns (attributes).
            * Geometry: Geospatial data is used for rendering world maps.
        * Data Types:
            * Quantitative: Numerical values like cases, deaths, and population.
            * Ordinal: Policies have levels, which can be considered ordinal.
            * Categorical: Country names and data categories (e.g., "Cases in ten thousands").
    * Why (The User's Intended Tasks):
        * Actions:
            * Consume: Users are primarily looking to view and interpret the data.
            * Present: Display data on world maps and scatter plots.
            * Discover: Identify trends, patterns, and correlations.
        * Targets:
            * Trends: Understand how COVID-19 metrics change over time or with different policies.
            * Outliers: Identify countries that deviate from the norm in cases, deaths, or policy effects.
            * Attributes: Compare and contrast different countries based on selected attributes.
    * How (The Encoding and Interaction Techniques):
        * Encode:
            * Spatial Position: The primary encoding for the world map. Countries are positioned based on geographical coordinates.
            * Color: Used to represent data magnitude. For instance, darker shades indicate higher cases or deaths.
            * Length: In scatter plots, the position on the x and y-axes indicates policy scores and deaths, respectively.
        * Reduce:
            Data is summarized at the monthly level instead of daily, providing a clearer, more digestible overview.
        * Navigate:
            Users can select different attributes (e.g., cases or deaths) and time periods to view different data on the world map.
        * Facet:
            The application provides separate pages for different visualizations, such as world maps and scatter plots.
        * Interact:
            Hovering over countries on the world map provides detailed data for that country.

* References:
    [1] M. D. Marco, March 11, 2020. “Coronavirus daily data,” data.world. [Online]. Available: https://data.world/markmarkoh/coronavirus-data
    [2] Coronarirus (COVID-19) data Hub, May 24, 2020. “COVID-19 Activity - Location & Population Table,” data.world. [Online]. Available: https://data.world/covid-19-data-resource-hub/covid-19-activity-location-population-table
    [3] J. Masuk, Janurary 21, 2020. “CORONAVIRUS GOVERNMENT RESPONSE TRACKER,” data.world. [Online]. Available: https://data.world/jiraphan-masuk/coronavirus-government-response-tracker
    [4] F. Verkroost. “Building Interactive World Maps in Shiny.” rviews.rstudio.com. Accessed: October 9, 2009. [Online]. Available: https://rviews.rstudio.com/2019/10/09/building-interactive-world-maps-in-shiny/#:~:text=Creating%20an%20interactive%20world%20map&text=The%20inputs%20to%20this%20function,the%20aesthetics%20of%20the%20plot
    [5] H. Hadley, M Cetinkaya-Rundel and G Grolemund, R for Data Science (2e), 2th ed. Accessed: Oct. 09, 2023. [Online]. Available: https://r4ds.hadley.nz/
    [6] H. Hadley, Mastering Shiny, Accessed: Oct. 09, 2023. [Online]. Available: https://mastering-shiny.org/index.html
