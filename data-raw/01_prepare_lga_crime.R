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
  # Read everything as character so mixed "nc" + numeric columns don't
  # force pivot_longer into a list column. We coerce to numeric later.
  df <- read_excel(raw_path, sheet = sheet_name, col_types = "text")

  # First column is always "Local Government Area"
  # Remaining columns alternate: "Jan YYYY - Dec YYYY : Rate per 100,000 population", "... : Rank"
  lga_col <- names(df)[1]
  names(df)[1] <- "lga"

  # Drop footer/note rows. Every sheet ends with a block of citation
  # notes, hyperlinks, and broken cell references (e.g.
  #   ='Assault - Domestic Violence'!#REF!
  # ) where the first column has text but all data columns are NA.
  # Keep only rows where at least one data column has a value.
  data_cols <- names(df)[-1]
  df <- df |>
    filter(if_any(all_of(data_cols), ~ !is.na(.))) |>
    # Also drop anything that obviously isn't an LGA name
    filter(!is.na(lga),
           !str_detect(lga, "^="),              # formula refs
           !str_detect(lga, "^\\*"),            # footnote markers
           !str_detect(lga, "^\\^"),            # footnote markers
           !str_detect(lga, "^NOTE"),
           !str_detect(lga, "acknowledgement"),
           !str_detect(lga, "^HYPERLINK|^=HYPERLINK"))

  long <- df |>
    pivot_longer(
      cols = -lga,
      names_to = "col",
      values_to = "value"
    ) |>
    mutate(
      year    = as.integer(str_extract(col, "(?<=Dec )\\d{4}")),
      metric  = if_else(str_detect(col, "Rate per"), "rate_per_100k", "rank"),
      value   = suppressWarnings(as.numeric(na_if(value, "nc")))
    ) |>
    select(-col) |>
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
  # Drop aggregate/summary rows that aren't real LGAs
  filter(!str_detect(lga, "^Total NSW")) |>
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