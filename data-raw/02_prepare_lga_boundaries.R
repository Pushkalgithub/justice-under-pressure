# ============================================================
# data-raw/02_prepare_lga_boundaries.R
# ------------------------------------------------------------
# Downloads NSW LGA boundaries from the ABS and reconciles the
# LGA name column with the names used in our crime xlsx.
#
# Output: data/nsw_lga_sf.rds  (simplified sf object)
# ------------------------------------------------------------
# ABS LGA boundaries (2023):
#   https://www.abs.gov.au/statistics/standards/
#     australian-statistical-geography-standard-asgs-edition-3/
#     jul2021-jun2026/access-and-downloads/digital-boundary-files
#
# If the download URL breaks, grab the shapefile manually and
# place it in data-raw/lga_boundaries/ — the script will pick
# it up from there.
# ============================================================

library(sf)
library(dplyr)
library(stringr)
library(here)

bndry_dir <- here("data-raw", "lga_boundaries")
dir.create(bndry_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Check for existing shapefile first ----
shp_files <- list.files(bndry_dir, pattern = "\\.shp$",
                        recursive = TRUE, full.names = TRUE)

if (length(shp_files) == 0) {
  message("No shapefile found locally. Please download the ABS LGA 2023 ",
          "boundary file and place it in: ", bndry_dir)
  message("Link: https://www.abs.gov.au/statistics/standards/australian-statistical-geography-standard-asgs-edition-3/jul2021-jun2026/access-and-downloads/digital-boundary-files")
  stop("Shapefile missing.")
}

lga_all <- st_read(shp_files[1], quiet = TRUE)

# ---- Filter to NSW only ----
# Column name varies by edition; try the usual candidates.
state_col <- intersect(c("STE_NAME21", "STE_NAME_2021", "STE_NAME"),
                       names(lga_all))[1]
lga_col   <- intersect(c("LGA_NAME23", "LGA_NAME_2023", "LGA_NAME22",
                         "LGA_NAME21", "LGA_NAME"), names(lga_all))[1]

nsw_lga <- lga_all |>
  filter(.data[[state_col]] == "New South Wales") |>
  select(lga_name_raw = all_of(lga_col), geometry)

# ---- Normalise LGA names to match the xlsx ----
# ABS uses forms like "Sydney (C)", "Albury (C)", "Armidale Regional (A)"
# The xlsx uses plain forms like "Sydney", "Albury", "Armidale"
nsw_lga <- nsw_lga |>
  mutate(
    lga = lga_name_raw |>
      str_remove("\\s*\\([A-Z]{1,3}\\)$") |>   # drop "(C)", "(A)", "(S)" etc
      str_remove("\\s+Regional$") |>           # "Armidale Regional" → "Armidale"
      str_trim()
  )

# ---- Simplify geometries for faster Leaflet rendering ----
nsw_lga <- nsw_lga |>
  st_transform(4326) |>
  st_simplify(dTolerance = 100, preserveTopology = TRUE)

# ---- Report any LGAs in the xlsx that don't match ----
crime <- readRDS(here("data", "lga_crime_long.rds"))
crime_lgas <- unique(crime$lga)
sf_lgas    <- unique(nsw_lga$lga)

unmatched <- setdiff(crime_lgas, sf_lgas)
if (length(unmatched) > 0) {
  message("LGAs in crime data with no geometry match (", length(unmatched), "):")
  print(unmatched)
  message("Add manual fixes to the rename block below if needed.")
}

# ---- Manual name fixes (extend as needed) ----
# These are common mismatches — add more as you discover them.
manual_fixes <- c(
  "Albury"   = "Albury",
  "Bayside"  = "Bayside"
  # "xlsx_name" = "shapefile_name"
)

# ---- Save ----
saveRDS(nsw_lga, here("data", "nsw_lga_sf.rds"))
message("Saved to data/nsw_lga_sf.rds  (",
        nrow(nsw_lga), " LGAs)")
