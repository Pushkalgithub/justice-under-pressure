# Justice Under Pressure

**NSW Crime & Court Dashboard** — DATA5002 Assignment 2, UNSW Sydney.

An interactive Shiny dashboard exploring the gap between crime-driven demand
and court capacity across New South Wales.

**Team:** Pushkal Garg · Srivarsha Elangovan · Kavya Geetha Balaji

---

## Repository structure

```
justice-under-pressure/
├── app.R                         # main Shiny entry point
├── global.R                      # packages, data, constants, helpers
├── R/
│   ├── tab1_crime_overview.R     # Varsha — crime trends, breakdowns
│   ├── tab2_court_demand.R       # Kavya  — processing, finalisations
│   └── tab3_regional.R           # Pushkal — choropleth, rankings
├── data-raw/                     # raw inputs + prep scripts (not loaded at runtime)
│   ├── NSW_LGA_Crime_Statistics.xlsx
│   ├── 01_prepare_lga_crime.R
│   └── 02_prepare_lga_boundaries.R
├── data/                         # cleaned .rds files (loaded by global.R)
│   ├── lga_crime_long.rds
│   └── nsw_lga_sf.rds
├── www/
│   └── custom.css
└── README.md
```

## Setup

1. **Clone** this repo.
2. **Install packages:**
   ```r
   install.packages(c(
     "shiny", "bslib", "dplyr", "tidyr", "stringr", "ggplot2",
     "plotly", "leaflet", "sf", "DT", "scales", "here",
     "readxl", "purrr"
   ))
   ```
3. **Prepare data** (run once):
   ```r
   source("data-raw/01_prepare_lga_crime.R")
   source("data-raw/02_prepare_lga_boundaries.R")
   ```
   The second script needs the ABS NSW LGA boundary shapefile — see the
   comments at the top of `02_prepare_lga_boundaries.R` for where to
   download it.
4. **Run the app:**
   ```r
   shiny::runApp()
   ```

## Ownership

| Owner   | Responsibilities |
|---------|------------------|
| Pushkal | Tab 3 (Regional), data cleaning, deployment, app shell |
| Varsha  | Tab 1 (Crime Overview), data cleaning, proposal lead |
| Kavya   | Tab 2 (Court Demand), data visualisation, court data prep |

## Working in your own tab

Each tab is a self-contained Shiny module in `R/tabN_*.R`. The pattern:

```r
tabN_ui <- function(id) { ... }            # UI for the tab
tabN_server <- function(id, filters) { ... }  # Server logic; `filters`
                                               # is a list of reactives for
                                               # the global sidebar filters
```

Use `filter_crime(offence, year, lgas)` from `global.R` to get filtered data.
Use `APP_PALETTE` for colours so all tabs stay consistent.

## Data sources

- **BOCSAR LGA Crime Statistics** (2016–2025) — rate per 100,000 population
  and rank, 27 offence categories across ~128 NSW LGAs.
- **ABS LGA Boundaries** (ASGS 2023) — geometry for the choropleth.
- Court processing data: TBD (Kavya's tab).

## Deployment

App will be deployed to [shinyapps.io](https://www.shinyapps.io) — URL
added here once live.
