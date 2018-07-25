library(shiny)
library(shinydashboard)
library(leaflet)
library(htmltools)
library(htmlwidgets)
library(dplyr)
library(ggmap)
library(googleVis)
library(tidyr)
library(shinyWidgets)


#Read in long-term trends data
nyctickettrends = read.csv('nyctickets_longterm.csv')
nyctickettrends$month = as.Date(nyctickettrends$month)
nyctickettrends$quarters = quarters(nyctickettrends$month)
nyctickettrends$yearqtr = paste0(format(nyctickettrends$month, '%Y'), '-', quarters(nyctickettrends$month))
nyctickettrends$boro = cut(nyctickettrends$violation_precinct, breaks=c(0, 35, 53, 95, 116, 150),
                           labels=c('Manhattan', 'Bronx', 'Brooklyn', 'Queens', 'Staten Island'))
nyctickettrends = filter(nyctickettrends, nyctickettrends$month < '2018-07-01')
nyctickettrends$weekday = factor(nyctickettrends$weekday, levels=0:6, labels=c('Monday', 'Tuesday', 'Wednesday', 'Thursday',
                                                     'Friday', 'Saturday', 'Sunday'))

#Define possible fields to split by on the first tab
split_by = c('None', 'Borough', 'Plate Type', 'Violation Category', 'Violation', 'Day of Week')

#Choices for the ticket types
plate_type_choices = c('Passenger', 'Commercial', 'Other')
violation_category_choices = levels(nyctickettrends$group)

#Setup for the precincts tab
metric_choices = c('Tickets (q3 2018)', 'Tickets (q3 2018) normalized by area', 'Change since q3 2014', 'Pct change since q3 2014')

#Read in shape file for police precincts
precincts_df = read.csv('precincts_df_warea.csv')

#Function to calculate the user's desired metric
calc_metric = function(data, metric) {
  if(metric == 'Tickets (q3 2018)'){
    
    data %>%
      filter(., between(month, as.Date('2018-04-01'), as.Date('2018-06-30'))) %>%
      group_by(., violation_precinct) %>%
      summarize(., metric=sum(count))
    
  } else if(metric == 'Tickets (q3 2018) normalized by area') {
    
    data %>%
      filter(., between(month, as.Date('2018-04-01'), as.Date('2018-06-30'))) %>%
      group_by(., violation_precinct) %>%
      summarize(., metric=sum(count))
    
  } else if(metric=='Change since q3 2014') {
    
    start = data %>%
      filter(., between(month, as.Date('2015-04-01'), as.Date('2015-06-30'))) %>%
      group_by(., violation_precinct) %>%
      summarize(., start=sum(count))
    
    data %>%
      filter(., between(month, as.Date('2018-04-01'), as.Date('2018-06-30'))) %>%
      group_by(., violation_precinct) %>%
      summarize(., tickets=sum(count)) %>%
      inner_join(., start, by='violation_precinct') %>%
      mutate(., metric=tickets-start)
    
  } else if(metric=='Pct change since q3 2014') {
    
    start = data %>%
      filter(., between(month, as.Date('2015-04-01'), as.Date('2015-06-30'))) %>%
      group_by(., violation_precinct) %>%
      summarize(., start=sum(count))
    
    data %>%
      filter(., between(month, as.Date('2018-04-01'), as.Date('2018-06-30'))) %>%
      group_by(., violation_precinct) %>%
      summarize(., tickets=sum(count)) %>%
      inner_join(., start, by='violation_precinct') %>%
      mutate(., metric=tickets/start - 1)
    
  }
}



#Data input for the heat map
tickets=read.csv('bkparking_wgeo.csv')
tickets$dow = factor(tickets$dow,
                     levels=c('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'), 
                       ordered = T)
tickets = tickets[!is.na(tickets$lat), ]




