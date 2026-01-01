<!-- Geospatial-Flood-Zones README (HTML) -->

<h1>Geospatial-Flood-Zones</h1>
<p><strong>Overlapping FEMA flood zones and NOAA recorded floods to determine trends and identify mismatch</strong></p>

<hr>

<h2>TLDR</h2>
<p>
  Flooding in the DMV is rising fast, both in frequency and severity, and the vast majority of these events—nearly 90%—are happening outside 
  FEMA‑designated flood zones. By integrating NOAA storm records, FEMA hazard maps, Census geometries, and socioeconomic data, this project 
  shows that official flood maps dramatically underestimate real‑world risk, especially in communities that are already socioeconomically 
  vulnerable. Montgomery County (MD) and Fairfax County (VA) emerge as regional hotspots, while a bivariate spatial analysis highlights block 
  groups that experience repeated flooding despite having little mapped hazard area. The result is a clear, data‑driven picture of a growing 
  flood‑risk mismatch with major implications for planning, equity, and climate resilience.
</p>

<h2>Highlights</h2>
<ul>
  <li><strong>Multi-Source Geospatial Pipeline</strong>: Automated extraction of NOAA archives and 5GB+ of FEMA shapefiles</li>
  <li><strong>Flood Zone Mismatch Analysis</strong>: Intersecting NOAA event coordinates with FEMA hazard polygons through spatial joins</li>
  <li><strong>Interactive Mapping</strong>: Visualized temporal and spatial patterns with interactive Leaflet map</li>
  <li><strong>Lagre-Scale Geospatial Analytics</strong>: Coordinate systems, shapefile handling, spatial indexing, API interaction</li>
</ul>

<h2>Data Visualization</h2>
<p>
  <img src="figures/extreme_identification.png" width="400" alt="Identification of Extreme Carbon Fluxes">
</p>

<h2>Skills</h2>
<ul>
  <li><strong>Languages</strong>: R</li>
  <li><strong>Libraries</strong>: raster, spatialreg, spdep, tigris, terra, leaflet</li>
  <li><strong>Collaboration</strong>: Group project maintained through GitHub</li>
  <li><strong>Data Source</strong>: <a href="https://github.com/marleeyork-pf/Geospatial-Flood-Zones/blob/main/datasources.txt"> Data Source (txt) </a> </li>
</ul>

<h2>Why this project?</h2>
<p>
  Flood risk in the Mid‑Atlantic is changing faster than the maps meant to represent it, and communities are increasingly exposed to hazards that 
  official FEMA flood zones fail to capture. This project tackles that gap by integrating decades of NOAA storm data, FEMA hazard layers, and Census 
  socioeconomic information to reveal where real‑world flooding diverges from mapped risk. The goal is to provide a clearer, data‑driven foundation 
  for planning, equity, and climate resilience in a region experiencing rapid environmental change.
</p>

<h2>Workflow Overview</h2>
<pre>
carbonflux/
├── data_sources.txt        # Directory for all data sources
├── floodzone_analysis.rmd  # Analysis and visualization code
├── interactive_plot.R      # Leaflet interactive flood zone map
├── project_writeup.docx    # Project writeup
├── figures/                # Data visalization of results
└── README.md
</pre>

<h2>Key Results</h2>
<ul>
  <li>Flood events in the DMV have surged dramatically, with total events doubling or tripling each decade since the 1990s.</li>
  <li>Only ~10% of flood events occur inside FEMA‑designated flood zones, revealing a major mismatch between mapped risk and real‑world flooding.</li>
  <li>The absolute number of floods outside hazard zones is rising every year, even as the inside/outside ratio stays constant.</li>
  <li>Montgomery County (MD) and Fairfax County (VA) consistently rank as the most flood‑impacted counties across multiple metrics.</li>
  <li>Bivariate mapping identifies highly vulnerable areas where frequent flooding coincides with minimal mapped hazard area.</li>
  <li>Socioeconomic disparities are evident: higher vulnerability correlates with lower income, higher poverty, and greater reliance on public assistance.</li>
</ul>
