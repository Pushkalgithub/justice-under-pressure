# ============================================================
# global.R
# ------------------------------------------------------------
# Loaded once when the Shiny app starts. Everything here is
# visible to ui.R, server.R, and all module files.
#
# Keep this file lean: packages, data, constants, helpers.
# ============================================================

# ---- Packages ----
suppressPackageStartupMessages({
  library(shiny)
  library(bslib)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
  library(plotly)
  library(leaflet)
  library(sf)
  library(DT)
  library(scales)
  library(here)
})

# ---- Load prepared data ----
crime_path <- here("data", "lga_crime_long.rds")
sf_path    <- here("data", "nsw_lga_sf.rds")

if (!file.exists(crime_path)) {
  stop("Missing data/lga_crime_long.rds. ",
       "Run data-raw/01_prepare_lga_crime.R first.")
}

crime_long <- readRDS(crime_path)

# sf may not be ready yet during early development — load lazily
nsw_lga_sf <- if (file.exists(sf_path)) readRDS(sf_path) else NULL

# ---- Constants ----
OFFENCE_CHOICES <- sort(unique(crime_long$offence))
YEAR_CHOICES    <- sort(unique(crime_long$year))
LGA_CHOICES     <- sort(unique(crime_long$lga))

LATEST_YEAR <- max(crime_long$year, na.rm = TRUE)

# Greater Sydney LGAs — used for the "in and around Sydney" zoom view.
# Source: ABS Greater Capital City Statistical Area (GCCSA) definition.
SYDNEY_LGAS <- c(
  "Bayside", "Blacktown", "Blue Mountains", "Burwood", "Camden",
  "Campbelltown", "Canada Bay", "Canterbury-Bankstown", "Central Coast",
  "Cumberland", "Fairfield", "Georges River", "Hawkesbury", "Hornsby",
  "Hunters Hill", "Inner West", "Ku-ring-gai", "Lane Cove", "Liverpool",
  "Mosman", "North Sydney", "Northern Beaches", "Parramatta", "Penrith",
  "Randwick", "Ryde", "Strathfield", "Sutherland Shire", "Sydney",
  "The Hills Shire", "Waverley", "Willoughby", "Wollondilly", "Woollahra"
)

# ---- Theme ----
# Colour palette — kept consistent across all tabs so Varsha and Kavya
# can pull from these same names. Based on the learnui.design picker
# Kavya mentioned in the group chat.
APP_PALETTE <- list(
  primary    = "#1f4e79",   # deep navy — headers, primary accents
  secondary  = "#4a90c2",   # mid blue
  accent     = "#e67e22",   # warm orange for highlights / "strain"
  danger     = "#c0392b",   # red for high-rank / high-pressure
  neutral    = "#7f8c8d",   # muted grey
  bg         = "#f8f9fa",
  surface    = "#ffffff",
  text       = "#2c3e50"
)

# Diverging ramp for choropleth (low → high crime rate)
CHOROPLETH_RAMP <- c("#fff5eb", "#fdd49e", "#fdae6b",
                     "#fd8d3c", "#e6550d", "#a63603")

app_theme <- bs_theme(
  version   = 5,
  bootswatch = "flatly",
  primary   = APP_PALETTE$primary,
  secondary = APP_PALETTE$secondary,
  base_font = font_google("Inter"),
  heading_font = font_google("Inter", wght = "600"),
  "navbar-bg" = APP_PALETTE$primary
)

# ---- Helpers ----

#' Filter the long crime dataframe
#' @param offence character; one offence category
#' @param year integer; single year (or NULL for all)
#' @param lgas character vector of LGAs to keep (or NULL for all)
filter_crime <- function(offence = NULL, year = NULL, lgas = NULL) {
  df <- crime_long
  if (!is.null(offence)) df <- df |> filter(offence == !!offence)
  if (!is.null(year))    df <- df |> filter(year == !!year)
  if (!is.null(lgas))    df <- df |> filter(lga %in% lgas)
  df
}

#' Format a rate for display
fmt_rate <- function(x) {
  ifelse(is.na(x), "—", format(round(x, 0), big.mark = ","))
}

#' Format a rank with ordinal suffix
fmt_rank <- function(x) {
  ifelse(is.na(x), "—", paste0("#", x))
}
