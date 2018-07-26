shinyUI(dashboardPage(
  dashboardHeader(title="NYC Parking Tickets"),
  
  dashboardSidebar(sidebarMenu(
    menuItem("Introduction", tabName = "intro", icon = icon("star")),
    menuItem("Trends Over Time", tabName = "trends", icon = icon("signal")),
    menuItem("By Neighborhood", tabName = "precincts", icon = icon("map")),
    menuItem("By Street Address (Brooklyn)", tabName = "heatmap", icon = icon("fire")))
  ),
  
  dashboardBody(
    tabItems(
      tabItem(tabName = 'intro',
              sidebarLayout(
                sidebarPanel(h2('Motivation'),
                             "Parking in NYC is hard. New Yorkers waste hours 
                             searching for spots on the street. For the city, that adds
                            up to lost productivity, increased congestion, and unnecessary
                            emissions.",
                             br(),
                             br(),
                             "Part of the problem is overcrowding, but 
                             it's also an issue of efficiency. Usually the parking spot being sought
                             exists, but its location is unknown. What if drivers had 
                             better information?",
                             br(),
                             br(),
                             "Perfect data, like a live sensor on every parking spot, could tell drivers 
                            exactly where to go park. In the absence of that, other data sources 
                             may be able to tell us where an open spot is likely to be.",
                             br(),
                             br(),
                             "This dashboard explores one potentially useful data source for this problem
                             -- the Parking Violations dataset from NYC Open Data. If parking tickets result
                             from a shortage of legal spaces, this data could indicate where it may be easier to 
                             find a valid spot.", 
                             br(),
                             br(),
                            "The dashboard first explores the makeup of the dataset and high-level 
                             trends over time before looking at differences by neighborhood and finally
                             street address (Brooklyn only)."),
                
                mainPanel(
                  br(),
                  img(src='IMG_5345.JPG', width='100%'),
                  'An elusive Brooklyn parking spot spotted in the wild',
                  br(),
                  br(),
                  a('Data set', 
                    href='https://data.cityofnewyork.us/City-Government/Parking-Violations-Issued-Fiscal-Year-2018/pvqr-7yc4/data',
                    target='_blank'),
                  br(),
                  a('Github', 
                    href='https://github.com/jrmcglynn/nyc_parking_shiny',
                    target='_blank')
                )
                
              )),
      
      tabItem(tabName='trends',
              sidebarLayout(
                mainPanel( h3(tags$b('NYC Parking Tickets Since 2014'), align='center'),
                           htmlOutput('trends')),
                sidebarPanel(selectizeInput('splitby', label='Choose field to split by',
                                            choices=split_by, selected='None'),
                             checkboxInput('stacked', 'Show 100% area chart'))
              )
                ),
      
      tabItem(tabName='precincts',
              sidebarLayout(
                sidebarPanel(
                  selectizeInput('boro', label='Choose Borough',
                                 choices=levels(nyctickettrends$boro)),
                  selectizeInput('metric', label='Choose Metric',
                                             choices=metric_choices, selected='Tickets (q2 2018)'),
                  checkboxGroupInput('plate_types', 'Vehicle Types',
                                                choices=plate_type_choices, selected = plate_type_choices),
                  checkboxGroupInput('violation_categories', 'Violation Category',
                                     choices=violation_category_choices, selected = violation_category_choices)),
                mainPanel(
                  h3(tags$b('Parking Tickets by Police Precinct'), align='center'),
                  plotOutput('precinctmap')
                ))),
      
      tabItem(tabName = 'heatmap',
    sidebarLayout(
      mainPanel(h3(tags$b('Localized Parking Ticket Density in Brooklyn'), tags$i('(q2 2018)'), align='center'),
                leafletOutput("heatmap", height = 550),
                'Data points geocoded courtesy of the Open Steet Maps API and the Data Scientist Toolkit'),
      sidebarPanel(
        selectizeInput("dow", label = 'Day of the Week',
                       choices=c('All', levels(tickets$dow)),
                       selected = 'All'),
        checkboxGroupInput('plate_types2', 'Vehicle Types',
                           choices=plate_type_choices, selected = plate_type_choices),
        checkboxGroupInput('violation_categories2', 'Violation Category',
                           choices=violation_category_choices, selected = violation_category_choices)
        )))
      
    
    ))
      ))