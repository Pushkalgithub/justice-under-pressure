# ============================================================
# data-raw/01_prepare_court.R
# ------------------------------------------------------------
# Reshapes and renames certain columns of the data
# into a single tidy long dataframe with columns:
#   lga, offence, year, rate_per_100k, rank
#
# Output: data/crime_data_clean.rds
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
library(zoo)
library(janitor)
library(DT)
library(shiny)
library(shinyWidgets)

# Path to your new raw file
raw_path <- here("data-raw", "NSW_Quarterly_Crime_Count.xlsx")
stopifnot(file.exists(raw_path))

df_raw <- read_excel(raw_path) %>% clean_names()
message("Rows: ", nrow(all_data))
message("Head: ", head(df_raw))

# Convert to long format
crime_data_long <- df_raw %>%
  select(-state) %>%
  pivot_longer(
    cols = -offence_category,
    names_to = "quarter",
    values_to = "crime_count"
  )

# Create columns to store quarter and year
crime_data_clean <- crime_data_long %>%
  mutate(
    quarter_date = as.yearqtr(quarter, format = "q%q_%Y")
  )

crime_data_clean <- crime_data_clean %>%
  mutate(
    year = as.numeric(format(quarter_date, "%Y"))
  )

# Save all dataframes as a list in one file
crime_bundle <- list(
  main = crime_data_clean
)

dir.create(here("data"), showWarnings = FALSE)
saveRDS(crime_bundle, here("data", "crime_data_clean.rds"))

message("Success! Rows: ", nrow(crime_data_clean))
message("Saved to data/crime_data_clean.rds")

