# ============================================================
# data-raw/01_prepare_court.R
# ------------------------------------------------------------
# Reshapes and renames certain columns of the data
# into a single tidy long dataframe with columns:
#   lga, offence, year, rate_per_100k, rank
#
# Output: data/court_data_clean.rds
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

# Path to your new raw file
raw_path <- here("data-raw", "NSW_Court_Finalization_Statistics.xlsx")
stopifnot(file.exists(raw_path))

df_raw <- read_excel(raw_path, sheet = "CourtDelay", .name_repair = "universal")
message("Rows: ", nrow(all_data))
message("Head: ", head(df_raw))

# Create a clean dataframe with renames timeframes (for graph 2)
court_data_clean <- df_raw %>%
  mutate(Timeframe = recode(Timeframe,
                            "July 2020 - June 2021" = "2020–21",
                            "July 2021 - June 2022" = "2021–22",
                            "July 2022 - June 2023" = "2022–23",
                            "July 2023 - June 2024" = "2023–24",
                            "July 2024 - June 2025" = "2024–25")) %>%
  mutate(across(c(Arrest.to.committal..c., Committal.to.outcome, 
                  Outcome.to.sentence, Arrest.to.finalisation..c., Count), 
                ~as.numeric(.))) 

# Create a percentage change datafram (for graph 3)
court_data_percentage_change <- court_data_clean %>%
  group_by(Court.Type) %>%
  arrange(Timeframe) %>%
  # 3. Pre-calculate the percentage change (for Graph 3)
  mutate(perc_change = (Count - lag(Count)) / lag(Count) * 100) %>%
  select(Court.Type, Timeframe, Count, perc_change) %>%
  filter(!is.na(perc_change)) %>%
  ungroup()

# Create a long percentage version (for graph 1)
court_data_percentage_long <- court_data_clean %>%
  # Perform the math you had in your test script
  mutate(
    arrest_to_comm_perc  = (Arrest.to.committal..c. / Arrest.to.finalisation..c.) * 100,
    comm_to_outcome_perc = (Committal.to.outcome / Arrest.to.finalisation..c.) * 100,
    outcome_to_sent_perc = (Outcome.to.sentence / Arrest.to.finalisation..c.) * 100
  ) %>%
  # Pivot it so it's ready for the stacked bar chart
  pivot_longer(
    cols = c(arrest_to_comm_perc, comm_to_outcome_perc, outcome_to_sent_perc), 
    names_to = "stage", 
    values_to = "percentage"
  ) 

# Save all dataframes as a list in one file
court_bundle <- list(
  main = court_data_clean,
  percent_change = court_data_percentage_change,
  percent_long = court_data_percentage_long
)

dir.create(here("data"), showWarnings = FALSE)
saveRDS(court_bundle, here("data", "court_data_clean.rds"))

message("Success! Rows: ", nrow(court_data_clean))
message("Saved to data/court_data_clean.rds")