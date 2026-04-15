# ============================================================
# data-raw/01_prepare_lga_crime.R
# ------------------------------------------------------------
# Reshapes NSW_LGA_Crime_Statistics.xlsx (27 sheets, wide format)
# into a single tidy long dataframe with columns:
#   lga, offence, year, rate_per_100k, rank
#
# Output: data/lga_crime_long.rds
# ------------------------------------------------------------
# Run this ONCE (or whenever the raw xlsx is updated).
# The Shiny app reads the rds, never the xlsx directly.
# ============================================================

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(purrr)
library(here)

raw_path <- here("data-raw", "NSW_LGA_Crime_Statistics.xlsx")
stopifnot(file.exists(raw_path))

sheets <- excel_sheets(raw_path)
message("Found ", length(sheets), " sheets")

# ---- Helper: read & reshape one sheet ----
read_one_sheet <- function(sheet_name) {
  df <- read_excel(raw_path, sheet = sheet_name)

  # First column is always "Local Government Area"
  # Remaining columns alternate: "Jan YYYY - Dec YYYY : Rate per 100,000 population", "... : Rank"
  lga_col <- names(df)[1]
  names(df)[1] <- "lga"

  long <- df |>
    pivot_longer(
      cols = -lga,
      names_to = "col",
      values_to = "value"
    ) |>
    mutate(
      year    = as.integer(str_extract(col, "(?<=Dec )\\d{4}")),
      metric  = if_else(str_detect(col, "Rate per"), "rate_per_100k", "rank")
    ) |>
    select(-col) |>
    # "nc" = not calculable → NA
    mutate(value = na_if(as.character(value), "nc"),
           value = suppressWarnings(as.numeric(value))) |>
    pivot_wider(names_from = metric, values_from = value) |>
    mutate(offence = sheet_name, .after = lga)

  long
}

all_data <- map_dfr(sheets, read_one_sheet)

# ---- Clean up ----
all_data <- all_data |>
  mutate(
    lga     = str_trim(lga),
    offence = str_trim(offence)
  ) |>
  filter(!is.na(lga)) |>
  arrange(offence, lga, year)

# ---- Quick sanity checks ----
message("Rows: ", nrow(all_data))
message("Unique LGAs: ", n_distinct(all_data$lga))
message("Unique offences: ", n_distinct(all_data$offence))
message("Year range: ", min(all_data$year, na.rm = TRUE), " - ",
        max(all_data$year, na.rm = TRUE))
message("% missing rate: ",
        round(mean(is.na(all_data$rate_per_100k)) * 100, 1), "%")

# ---- Save ----
dir.create(here("data"), showWarnings = FALSE)
saveRDS(all_data, here("data", "lga_crime_long.rds"))
message("Saved to data/lga_crime_long.rds")
