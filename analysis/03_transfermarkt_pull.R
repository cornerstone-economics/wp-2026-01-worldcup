# WP-2026-01: Transfermarkt squad values — hand-curated panel
# Iteration: 2 (replaces the iter-1 rvest scraper)
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/03_transfermarkt_pull.R")
# Reads:    data/raw/squad_values_input.csv (hand-curated, must be verified)
# Writes:   data/squad_values_panel.csv

# -----------------------------------------------------------------------------
# Why hand-curated and not scraped:
#
# Earlier draft used rvest against speculative TM team URLs. Two problems:
# (1) the URL slug + ID guesses were unreliable; (2) Transfermarkt occasionally
# adjusts squad-table markup which silently breaks parse logic. For 13
# country-level totals — TM displays them at the top of every team page —
# manual curation is faster, fully auditable, and cites the source URL per
# row.
#
# How to fill the input CSV:
#   1. Open transfermarkt.com.
#   2. For each country: search the team name in TM's search box, click into
#      the men's national team, land on its squad / "Kader" page.
#   3. Copy the page URL into tm_url.
#   4. Copy the three numbers TM shows in the team-header block:
#        total_value_mil_eur (TM "Total market value")
#        mean_value_mil_eur  (TM "Average market value")
#        n_players           (TM squad size)
#   5. Note today's date in access_date (YYYY-MM-DD).
#   6. Flip verified to TRUE only after you have eyes on the page.
#
# A typical 13-country pass takes 5-10 minutes.
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(here)
})

set.seed(20260509)

input_path <- here("data", "raw", "squad_values_input.csv")
if (!file.exists(input_path)) {
  stop(
    "squad_values_input.csv missing. ",
    "See header comment in 03_transfermarkt_pull.R for how to fill it."
  )
}
input <- read_csv(input_path, show_col_types = FALSE)

unverified <- input |> filter(!verified)
if (nrow(unverified) > 0) {
  message(
    "ERROR: ", nrow(unverified),
    " rows in squad_values_input.csv are not verified."
  )
  print(unverified |> select(country, iso3, tm_url, verified))
  stop(
    "Visit each TM team page, fill the four numbers + URL + access date, ",
    "set verified=TRUE, then re-run."
  )
}

required_cols <- c("total_value_mil_eur", "n_players")
miss_required <- input |>
  filter(if_any(all_of(required_cols), is.na))
if (nrow(miss_required) > 0) {
  message("ERROR: rows verified but missing required values:")
  print(miss_required |> select(country, total_value_mil_eur, n_players))
  stop("Fill the missing numbers, then re-run.")
}

squad_values_panel <- input |>
  transmute(
    country,
    iso3,
    n_players,
    total_value_mil  = total_value_mil_eur,
    mean_value_mil   = mean_value_mil_eur,
    median_value_mil = NA_real_,
    n_valued         = n_players,
    tm_url,
    access_date      = as.Date(access_date)
  ) |>
  arrange(desc(total_value_mil))

write_csv(squad_values_panel, here("data", "squad_values_panel.csv"))

message("Wrote squad_values_panel.csv:")
print(squad_values_panel, n = Inf)

message("\n03_transfermarkt_pull.R complete.")
