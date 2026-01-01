# Load in packages
library(dplyr)
library(ggplot2)
library(ggbreak)
library(sf)
library(dplyr)
library(leaflet)
library(xml2)
library(stringr)
library(rvest)
library(purrr)
library(leaflet)
library(leaflet.extras)
library(htmltools)
library(htmlwidgets)
library(tidyr)


# Load in NOAA flood data
floods <- read.csv("NOAA_flood.csv")
head(floods)

# Cast date columns as dates
floods$BEGIN_DATE <- as.Date(floods$BEGIN_DATE,"%m/%d/%Y")
class(floods$BEGIN_DATE)

# Extract the years for each flood
floods$year <- as.numeric(format(floods$BEGIN_DATE,"%Y"))

# Aggregate floods by year
yearly_floods <- floods %>% group_by(year) %>% count()
yearly_floods <- data.frame(yearly_floods)
plot(x = yearly_floods$year,y = yearly_floods$n, type = "l")

# Create dataframe of dates with 0 flood events included
data <- data.frame("year" = 1996:2024)
data <- merge(data, yearly_floods, by = "year", all.x = TRUE)
data$n[is.na(data$n)] <- 0

# Get range of x values for rectangle
x_min <- min(data$year - 1)
x_max <- max(data$year + 1)

# Basic plot
ggplot(data, aes(x = year, y = n)) +
  geom_line() +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE, color = "red", linetype = "dashed", size = 1) +
  scale_y_break(c(23.9, 50.3)) +
  scale_x_continuous(breaks = min(yearly_floods$year):max(yearly_floods$year)) +
  theme_minimal() +
  geom_rect(aes(xmin = x_min, xmax = x_max, ymin = 0, ymax = 25),
            fill = NA, color = "black", size = 1) +
  geom_rect(aes(xmin = x_min, xmax = x_max, ymin = 50, ymax = 58),
            fill = NA, color = "black", size = 1) +
  labs(x = "Year",
       y = "Number of flood occurrences",
       title = "DC Flood Events by Year") +
  theme(
    plot.title = element_text(hjust = 0.5),
    plot.title.position = "plot",
    axis.text.x = element_text(angle = 45, vjust = 0.5, hjust = 1),
    axis.text.x.top = element_blank(),
    axis.ticks.x.top = element_blank(),
    panel.grid.major.x = element_line(),  
    panel.grid.minor.x = element_blank(),  
    panel.grid.major.y = element_line(),    
    panel.grid.minor.y = element_blank()    
  )

# Trying to load FEMA data
# Set the path to the extracted geodatabase or shapefile
# Replace 'path_to_your_data' with the actual path to your data
data_path <- "C:/Users/marleeyork/Documents/6289spatial_final/data/110001_20241031"  

# List available layers in the geodatabase
st_layers(data_path)

# Read a specific layer, for example, the Flood Hazard Zones layer
# Replace 'S_Fld_Haz_Ar' with the actual layer name you're interested in
flood_zones <- st_read(dsn = data_path, layer = "C:/Users/marleeyork/Documents/6289spatial_final/data/110001_20241031/S_Fld_Haz_Ar")

# View the first few rows of the data
head(flood_zones)

# Plot the flood zones
plot(st_geometry(flood_zones))

# Adding the flood points
flood_points_df <- data.frame("id" = floods$EVENT_ID,
                              "lat" = floods$BEGIN_LAT,
                              "lon" = floods$BEGIN_LON,
                              "Date" = floods$BEGIN_DATE,
                              "event_type" = floods$EVENT_TYPE)
flood_points_df <- na.omit(flood_points_df)
flood_points_sf <- st_as_sf(flood_points_df, coords = c("lon", "lat"), crs = 4326)

# Match CRS of flood zones
flood_points_sf <- st_transform(flood_points_sf, crs = st_crs(flood_zones))

# Check for validity
validity <- st_is_valid(flood_zones)

# If any are FALSE, fix them
flood_zones_fixed <- st_make_valid(flood_zones)

# Perform spatial join to check if point is in a flood zone
floods_with_zones <- st_join(flood_points_sf, flood_zones_fixed, join = st_intersects)

# Create new column to indicate whether its in the flood zone or not
floods_with_zones <- st_join(flood_points_sf, flood_zones_fixed, join = st_intersects, left = TRUE)

# Loading flood zones
flood_zones <- st_read("C:/Users/marleeyork/Documents/6289spatial_final/data/110001_20241031/S_Fld_Haz_Ar.shp")  # adjust if needed
plot(flood_zones["FLD_ZONE"])  # Or "ZONE_SUBTY", depending on FEMA schema

# Make sure points are in same CRS
flood_points_sf <- st_transform(flood_points_sf, st_crs(flood_zones))
flood_points_sf_fixed <- st_make_valid(flood_points_sf)

# Check for validity
validity <- st_is_valid(flood_points_sf_fixed)

# If any are FALSE, fix them
flood_zones_fixed <- st_make_valid(flood_zones)
st_is_valid(flood_zones_fixed)

# Spatial join
floods_with_zones <- st_join(flood_points_sf, flood_zones_fixed, join = st_intersects, left = TRUE)
floods_with_zones_fixed <- st_make_valid(floods_with_zones)

# Assign flood zone status
floods_with_zones_fixed$in_flood_zone <- floods_with_zones$FLD_ZONE %in% c("A", "AE", "VE")  # add more if needed

# Map!
ggplot() +
  geom_sf(data = flood_zones, aes(fill = FLD_ZONE), alpha = 0.4, color = NA) +
  geom_sf(data = floods_with_zones_fixed, aes(color = in_flood_zone), size = 2) +
  scale_color_manual(values = c("black", "red"), labels = c("Outside", "Inside")) +
  labs(title = "DC Flood Events and FEMA Flood Zones", color = "Flood Zone Status") +
  theme_minimal()


################### Making interactive map #########################################
# First, add polygon identifiers to each flood zone
flood_zones_fixed <- flood_zones_fixed %>%
  mutate(polygon_id = paste0("polygon_", row_number()))

print("Column names before join:")
print(colnames(floods_with_zones_fixed))

# Join flood points with specific zones
# This will associate each flood point with the specific polygon it falls within
floods_with_specific_zones <- st_join(
  floods_with_zones_fixed,
  flood_zones_fixed %>% select(polygon_id, FLD_ZONE),
  left = TRUE
) %>%
  mutate(
    marker_id = paste0("marker_", row_number()),
    # If point doesn't fall within any polygon, in_flood_zone will be FALSE
    in_flood_zone = (!is.na(FLD_ZONE.y) & (FLD_ZONE.y == "X"))
  )

print("Column names after join:")
print(colnames(floods_with_specific_zones))

# Start with your existing data preparation
floods_with_zones_fixed <- floods_with_specific_zones %>%
  mutate(
    marker_id = paste0("marker_", row_number()),
    in_flood_zone = (!is.na(FLD_ZONE.y) & (FLD_ZONE.y == "X"))
  )

# Calculate statistics for each specific polygon
zone_specific_stats <- floods_with_zones_fixed %>%
  st_drop_geometry() %>%
  group_by(polygon_id) %>%
  summarise(
    FLD_ZONE = first(FLD_ZONE.y),
    n_events = n(),
    n_floods = sum(if_else(event_type=="Flood",1,0)),
    n_flash = sum(if_else(event_type=="Flash Flood",1,0)),
    n_coastal = sum(if_else(event_type=="Coastal Flood",1,0))
  )

# Join these stats back to the original polygons
flood_zones_stats <- flood_zones_fixed %>%
  left_join(zone_specific_stats, by = "polygon_id") %>%
  mutate(
    n_events = replace_na(n_events, 0),
    zone_status = ifelse(n_events > 0, "In", "Out"),
  )

# Create zone labels
zone_labels <- c("In" = "Zone X (Minimal Risk)", "Out" = "Zone AE (Moderate Risk)")

# Assign zone status
flood_zones_stats$zone_status[flood_zones_stats$FLD_ZONE.x=="X"] <- "In"
flood_zones_stats$zone_status[flood_zones_stats$FLD_ZONE.x=="AE"] <- "Out"
floods_with_zones_fixed$zone_status <- ifelse(floods_with_zones_fixed$FLD_ZONE.x=="X","In","Out")

# Create color palette based on whether zone is a flood zone (Zone X) or not
pal_flood <- colorFactor(
  palette = c("In" = "#d6c6a8", "Out" = "#397fa3"),
  domain = c("In", "Out")
)

pal_zone <- colorFactor(
  palette = c("Zone AE (Moderate Risk)" = "#397fa3", "Zone X (Minimal Risk)" = "#d6c6a8"),
  domain = c("Zone AE (Moderate Risk)","Zone X (Minimal Risk)")
)

# Transform both to WGS84
flood_zones_stats <- st_transform(flood_zones_stats, crs = 4326)
floods_with_zones_fixed <- st_transform(floods_with_zones_fixed, crs = 4326)

# Leaflet map
m <- leaflet() %>%
  addTiles() %>%
  # Add a div to display hover statistics
  addControl(
    html = "<div id='hover-stats' style='padding: 6px 8px; background: white; background: rgba(255,255,255,0.8); box-shadow: 0 0 15px rgba(0,0,0,0.2); border-radius: 5px;'>Hover over a zone to see statistics</div>",
    position = "bottomleft"
  ) %>%
  addPolygons(
    data = flood_zones_stats,
    fillColor = ~pal_flood(zone_status),  # Color based on whether it's Zone X
    fillOpacity = 0.6,
    color = "white",
    weight = 1,
    layerId = ~polygon_id,  # Use the unique polygon ID
    popup = ~paste0(
      "<strong>Zone:</strong> ", zone_labels[zone_status], "<br/>",
      "<strong>Events in this specific zone:</strong> ", n_events, "<br/>",
      "<strong>Number of each event type:</strong> ", "<br/>",
      
    ),
    highlightOptions = highlightOptions(
      color = "black",
      weight = 2,
      bringToFront = TRUE
    )
  ) %>%
  addCircleMarkers(
    data = floods_with_zones_fixed,
    color = ~ifelse(in_flood_zone, "red", "black"),
    radius = 5,
    layerId = ~marker_id,
    popup = ~paste0(
      "<strong>Date:</strong> ", Date, "<br/>",
      "<strong>In zone?</strong> ", ifelse(in_flood_zone, "Yes", "No"), "<br/>",
      "<strong>Zone polygon:</strong> ", ifelse(is.na(polygon_id), "None", polygon_id)
    )
  ) %>% 
  addLegend(
    position = "bottomright",
    pal = pal_flood,
    zone_labels[unique(flood_zones_stats$zone_status)],
    title = "Flood Zone Type",
    opacity = 0.7
  )

# Create a lookup object for zone statistics to use in JavaScript
zone_stats_lookup <- flood_zones_stats %>%
  st_drop_geometry() %>%
  select(polygon_id, FLD_ZONE.x, n_events) %>%
  jsonlite::toJSON()

# Add custom JavaScript for interaction
js_code <- sprintf("
function(el, x) {
  var map = this;
  
  // Parse the zone statistics lookup
  var zoneStats = %s;
  
  // Create a div for hover stats if it doesn't exist
  var statsDiv = document.getElementById('hover-stats');
  if (!statsDiv) {
    statsDiv = document.createElement('div');
    statsDiv.id = 'hover-stats';
    statsDiv.style.padding = '6px 8px';
    statsDiv.style.background = 'white';
    statsDiv.style.boxShadow = '0 0 15px rgba(0,0,0,0.2)';
    statsDiv.style.borderRadius = '5px';
    statsDiv.innerHTML = 'Hover over a zone to see statistics';
    
    var statsControl = L.control({position: 'bottomleft'});
    statsControl.onAdd = function() {
      return statsDiv;
    };
    statsControl.addTo(map);
  }
  
  // Function to update stats display
  function updateStats(polygonId) {
    for (var i = 0; i < zoneStats.length; i++) {
      if (zoneStats[i].polygon_id === polygonId) {
        var zone = zoneStats[i];
        var zoneLabel = '';
        if (zone.FLD_ZONE === 'X') zoneLabel = 'Zone X (Minimal Risk)';
        else if (zone.FLD_ZONE === 'AE') zoneLabel = 'Zone AE (High Risk)';
        else if (zone.FLD_ZONE === 'A') zoneLabel = 'Zone A (No Risk)';
        else zoneLabel = 'Zone ' + zone.FLD_ZONE;
        
        statsDiv.innerHTML = '<strong>' + zoneLabel + '</strong><br/>' +
                            'Events in this zone: ' + zone.n_events + '<br/>' +
                            'Mean depth: ' + zone.mean_depth.toFixed(2) + ' ft';
        return;
      }
    }
    // If no match found
    statsDiv.innerHTML = 'Hover over a zone to see statistics';
  }
  
  // Add event handlers to each polygon
  map.eachLayer(function(layer) {
    if (layer.options && layer.options.layerId && layer.options.layerId.startsWith('polygon_')) {
      layer.on('mouseover', function(e) {
        updateStats(layer.options.layerId);
        layer.setStyle({
          weight: 3,
          color: 'black',
          fillOpacity: 0.7
        });
        
        // Highlight all markers within this polygon
        map.eachLayer(function(markerLayer) {
          if (markerLayer.options && 
              markerLayer.options.layerId && 
              markerLayer.options.layerId.startsWith('marker_') &&
              markerLayer.feature && 
              markerLayer.feature.properties && 
              markerLayer.feature.properties.polygon_id === layer.options.layerId) {
            markerLayer.setStyle({
              radius: 7,
              fillOpacity: 1.0,
              weight: 2
            });
          }
        });
      });
      
      layer.on('mouseout', function(e) {
        statsDiv.innerHTML = 'Hover over a zone to see statistics';
        layer.setStyle({
          weight: 1,
          color: 'white',
          fillOpacity: 0.6
        });
        
        // Reset all markers
        map.eachLayer(function(markerLayer) {
          if (markerLayer.options && 
              markerLayer.options.layerId && 
              markerLayer.options.layerId.startsWith('marker_')) {
            markerLayer.setStyle({
              radius: 5,
              fillOpacity: 0.6,
              weight: 1
            });
          }
        });
      });
    }
  });
}
", zone_stats_lookup)

# Render with JavaScript
htmlwidgets::onRender(m, js_code)
