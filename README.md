# Justice Under Pressure

**NSW Crime & Court Dashboard** — DATA5002 Assignment 2, UNSW Sydney.

An interactive Shiny dashboard exploring the gap between crime-driven demand
and court capacity across New South Wales.

**Team:** Pushkal Garg · Srivarsha Elangovan · Kavya Geetha Balaji

---

## Repository structure

```
justice-under-pressure/
├── .devcontainer/
│   ├── devcontainer.json             # Codespaces config (R + geospatial)
│   └── Dockerfile                    # rocker/geospatial base image
├── data/
│   ├── lga_crime_long.rds            # Tidy long-format LGA crime data
│   ├── nsw_lga_sf.rds                # Simplified NSW LGA boundaries (sf)
│   ├── court_data_clean.rds          # Court processing data (Kavya)
│   └── crime_data_clean.rds          # Quarterly crime data (Varsha)
├── data-raw/
│   ├── lga_boundaries/               # ABS LGA 2023 shapefile (not tracked)
│   ├── NSW_LGA_Crime_Statistics.xlsx  # BOCSAR LGA crime rates + ranks
│   ├── NSW_Court_Finalization_Statistics.xlsx
│   ├── NSW_Quarterly_Crime_Count.xlsx
│   ├── 01_prepare_lga_crime.R        # xlsx → lga_crime_long.rds
│   ├── 02_prepare_lga_boundaries.R   # Shapefile → nsw_lga_sf.rds
│   ├── 03_prepare_court.R            # Court data → court_data_clean.rds
│   └── 04_prepare_crime.R            # Quarterly crime → crime_data_clean.rds
├── R/
│   ├── tab1_crime_overview.R         # Varsha — crime trends, breakdowns
│   ├── tab2_court_demand.R           # Kavya — processing times, finalisations
│   └── tab3_regional.R               # Pushkal — choropleth, rankings, Sydney zoom
├── www/
│   └── custom.css                    # App-wide styling overrides
├── app.R                             # Main Shiny entry point
├── global.R                          # Packages, data loading, constants, helpers
├── AI_LLM_Transcripts.md            # Generative AI usage log
├── README.md
└── .gitignore
```

## Setup

1. **Clone** this repo.
2. **Install R packages:**
   ```r
   install.packages(c(
     "shiny", "bslib", "dplyr", "tidyr", "stringr", "ggplot2",
     "plotly", "leaflet", "sf", "DT", "scales", "here", "readxl",
     "purrr", "zoo", "htmlwidgets", "shinyWidgets"
   ))
   ```
3. **Prepare data** (run once, in order):
   ```r
   source("data-raw/01_prepare_lga_crime.R")
   source("data-raw/02_prepare_lga_boundaries.R")
   source("data-raw/03_prepare_court.R")
   source("data-raw/04_prepare_crime.R")
   ```
   Script 02 requires the ABS LGA 2023 boundary shapefile in
   `data-raw/lga_boundaries/`. See comments in the script for the
   download link.
4. **Run the app:**
   ```r
   shiny::runApp()
   ```

### Using GitHub Codespaces

The repo includes a `.devcontainer` config. Create a Codespace from the
repo page and the R environment + system dependencies install automatically.
Then run the prep scripts and launch with:

```bash
Rscript -e 'shiny::runApp(host = "0.0.0.0", port = 3838)'
```

## Ownership

| Owner   | Tab | Responsibilities |
|---------|-----|------------------|
| Varsha  | 1 — Crime Overview | Crime trend, offence breakdown, top offences table, data cleaning |
| Kavya   | 2 — Court Demand | Processing time distribution, finalisations, YoY change, court data prep |
| Pushkal | 3 — Regional Analysis | NSW choropleth, ranked bar chart, Sydney zoom, app shell, deployment |

## Data sources

- **BOCSAR LGA Crime Statistics** (2016–2025) — rate per 100k and rank across 27 offence categories and ~130 NSW LGAs.
- **BOCSAR Court Finalization Statistics** — court processing times, lodgements, and finalisations by court type.
- **BOCSAR Quarterly Crime Count** — quarterly incident counts by offence category.
- **ABS LGA Boundaries** (ASGS 2023) — geometry for the choropleth maps.

## Deployment

App is deployed to [unsw.shinyapps.io/justice-under-pressure](https://unsw.shinyapps.io/justice-under-pressure/)
