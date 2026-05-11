# WP-2026-01: export a Datawrapper-ready CSV for the global panel chart
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/06_datawrapper_export.R")
# Reads:    data/global_panel.csv
# Writes:   data/fig6_datawrapper.csv (formatted for Datawrapper scatter plot)
#
# The exported CSV has the columns Datawrapper expects for a scatter plot
# with country labels and a single highlighted point (Curaçao).

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(here)
})

g <- read_csv(here("data", "global_panel.csv"), show_col_types = FALSE) |>
  filter(!is.na(population_latest), !is.na(rank), !is_uk_constituent) |>
  mutate(country = if_else(iso3 == "CUW", "Curaçao", country))

dw <- g |>
  transmute(
    Country         = country,
    `FIFA rank`     = rank,
    Population      = population_latest,
    `Diaspora per resident` = round(diaspora_per_capita, 3),
    Highlight       = if_else(iso3 == "CUW", "Curaçao", "Other")
  ) |>
  arrange(`FIFA rank`)

write_csv(dw, here("data", "fig6_datawrapper.csv"))

message("Wrote fig6_datawrapper.csv (", nrow(dw), " countries)")
message("Columns: Country, FIFA rank, Population, Diaspora per resident, Highlight")
