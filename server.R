shinyServer(function(input, output) {
  
  ####TRENDS OVER TIME####
  
  #Get column name to split by
  split_col = reactive(switch(input$splitby, 'Borough'='boro', 'Plate Type' = 'plate_type',
                              'Violation Category' = 'group', 'Violation' = 'violation', 'Day of Week' = 'weekday'))
  
  trends_data = reactive(
    if(input$splitby=='None'){
    nyctickettrends %>%
      group_by(yearqtr) %>%
      summarize(., Tickets = sum(count))} else (
    nyctickettrends %>%
        select(yearqtr, count, split_col = split_col()) %>%
        group_by(., yearqtr, split_col) %>%
        summarize(., tickets=sum(count)) %>%
        spread(., key = split_col, value=tickets)))
  
  output$trends = renderGvis(
    gvisAreaChart(trends_data(), xvar='yearqtr', yvar=, 
                  options=list(isStacked = ifelse(input$stacked, 'percent', 'false'),
                               areaOpacity = ifelse(input$stacked, 0.3, 0),
                               vAxis='{minValue: 0}', chartArea="{'width':'60%', 'height': '80%'}",
                               height=550, backgroundColor='transparent')))
  
  
  #####PRECINCT####
  
  nyctickettrends_r = reactive(
    nyctickettrends %>%
      filter(., plate_type %in% input$plate_types, boro == input$boro, group %in% input$violation_categories)
  )
  
  precincts_r = reactive(
    calc_metric(nyctickettrends_r(), input$metric) %>%
      inner_join(., precincts_df, by=c('violation_precinct'='precinct_no'))
  )
  
  precincts_r2 = reactive(
    if(input$metric == 'Tickets (q2 2018) normalized by area') {
      mutate(precincts_r(), metric=metric*1000/precinct_area)} else{precincts_r()}
  )
  
  output$precinctmap = renderPlot(
    {ggplot() + geom_polygon(data = precincts_r2(), aes(x=long, y=lat, group=group, fill=metric)) + 
        #geom_text(data = precinct_centers_r(), aes(x=center_long, y=center_lat, label=precinct_no)) +
      coord_equal() + scale_fill_gradient2(mid = "#56B1F7", high =  "#132B43", guide='colorbar') + 
        theme(rect=element_blank(), title=element_blank(),
              panel.grid = element_blank(), axis.ticks = element_blank(),
              axis.text = element_blank()) },
    height = 600, bg = 'transparent'
  )

  ####HEATMAP####
  
  heatPlugin <- htmlDependency("Leaflet.heat", "99.99.99",
                               src = normalizePath("www/Leaflet.heat/dist"),
                               script = "leaflet-heat.js"
  )
  
  registerPlugin <- function(map, plugin) {
    map$dependencies <- c(map$dependencies, list(plugin))
    map
  }
  
  center = c(-73.95, 40.65)
  
  tickets_dow = reactive(
    if(input$dow !='All'){
      tickets %>%
        filter(., dow==input$dow)
    } else {tickets}
  )
  
  tickets_r = reactive({
    tickets_dow() %>%
      filter(., plate_type %in% input$plate_types2, 
             group %in% input$violation_categories2) %>%
      select(., lat, lon)
    })
  
  output$heatmap =
    renderLeaflet(leaflet(options = leafletOptions(minZoom = 11, maxZoom=17)) %>%
                    addProviderTiles('CartoDB.Positron') %>%
                    setView( lng = center[1], lat = center[2], zoom = 11) %>%
                    setMaxBounds( lng1 = -74.1
                                  , lat1 = 40.5
                                  , lng2 = -73.8
                                  , lat2 = 40.8) %>%
                    registerPlugin(heatPlugin) %>%
                    onRender("function(el, x, data) {
                             data = HTMLWidgets.dataframeToD3(data);
                             data = data.map(function(val) { return [val.lat, val.lon]; });
                             L.heatLayer(data, {radius: 5, maxZoom:1,
                             gradient:{0.4: 'grey', 0.65: 'black', 0.8: 'red'}}).addTo(this);}",
                             data = tickets_r()))
  
}
)