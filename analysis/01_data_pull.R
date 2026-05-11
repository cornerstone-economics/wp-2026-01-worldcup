# WP-2026-01: data pull for FIFA ranking, populations, and panel construction
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
# Run: source("analysis/01_data_pull.R")
# Inputs:  manual FIFA ranking CSV in data/raw/ (see SOURCES below)
# Outputs: data/fifa_ranking_panel.csv, data/population_panel.csv, data/country_panel.csv

# -----------------------------------------------------------------------------
# SOURCES (to make this reproducible)
# -----------------------------------------------------------------------------
# FIFA men's ranking history, monthly, all federations:
#   FIFA publishes the full ranking at https://inside.fifa.com/fifa-world-ranking/men
#   For reproducible work the community-maintained CSV mirror at
#     https://github.com/cashncarry/FIFAWorldRanking
#   pulls FIFA's own data and exposes it as a stable CSV. Download
#   `fifa_ranking-2024-04-04.csv` (or latest) and save to data/raw/fifa_ranking.csv.
#   The Kaggle mirror (cashncarry/fifaworldranking) is the same source if you
#   prefer the API.
#
# Population:
#   World Bank WDI via the {WDI} package. Curaçao (ISO3 CUW) is included as a
#   high-income country in WDI from 2009 onward. Cabo Verde (CPV), Albania
#   (ALB), Suriname (SUR) are all standard WDI countries.
#
# Diaspora stocks: handled in 02_diaspora_panel.R, NOT here. Diaspora figures
# are too source-sensitive to script-pull; they get curated by hand with
# explicit citations in data/diaspora_panel.csv.
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(WDI)
  library(here)
})

set.seed(20260509)

# Country panel ---------------------------------------------------------------

countries <- tibble::tribble(
  ~iso3, ~iso2, ~country,      ~confederation, ~role,
  "CUW", "CW",  "Curaçao",     "CONCACAF",     "case",
  "CPV", "CV",  "Cabo Verde",  "CAF",          "comparator",
  "ALB", "AL",  "Albania",     "UEFA",         "comparator",
  "SUR", "SR",  "Suriname",    "CONCACAF",     "comparator"
)

# Optional reference set of small CONCACAF + UEFA states the FIFA ranking
# reaches but the empirical body does not centre on. Used in figure 5 only.
reference_states <- tibble::tribble(
  ~iso3, ~iso2, ~country,         ~confederation,
  "ISL", "IS",  "Iceland",        "UEFA",
  "MLT", "MT",  "Malta",          "UEFA",
  "LUX", "LU",  "Luxembourg",     "UEFA",
  "MNE", "ME",  "Montenegro",     "UEFA",
  "MKD", "MK",  "North Macedonia","UEFA",
  "JAM", "JM",  "Jamaica",        "CONCACAF",
  "TTO", "TT",  "Trinidad and Tobago", "CONCACAF",
  "PAN", "PA",  "Panama",         "CONCACAF",
  "HTI", "HT",  "Haiti",          "CONCACAF"
)

country_panel <- bind_rows(
  countries,
  reference_states %>% mutate(role = "reference")
)

write_csv(country_panel, here("data", "country_panel.csv"))
message("Wrote country_panel.csv (", nrow(country_panel), " rows)")

# Population pull -------------------------------------------------------------
# WDI indicator SP.POP.TOTL — total population, mid-year estimate.

pop_iso <- country_panel$iso2

pop_raw <- WDI(
  country   = pop_iso,
  indicator = c(population = "SP.POP.TOTL"),
  start     = 2010,
  end       = 2025,
  extra     = TRUE
)

population_panel <- pop_raw %>%
  as_tibble() %>%
  filter(!is.na(population)) %>%
  transmute(
    iso2 = iso2c,
    iso3 = iso3c,
    country,
    year,
    population
  ) %>%
  arrange(country, year)

# Curaçao: WDI sometimes reports CUW with gaps. CBS Curaçao publishes the
# authoritative resident-population series. Fold in any missing years from
# the CBS file if it lives at data/raw/cbs_curacao_population.csv. This is
# documented but not required for v1; WDI coverage from 2010 forward is fine.
cbs_path <- here("data", "raw", "cbs_curacao_population.csv")
if (file.exists(cbs_path)) {
  cbs <- read_csv(cbs_path, show_col_types = FALSE)
  population_panel <- population_panel %>%
    rows_upsert(cbs, by = c("iso3", "year"))
  message("Folded in CBS Curaçao population overrides")
}

write_csv(population_panel, here("data", "population_panel.csv"))
message("Wrote population_panel.csv (", nrow(population_panel), " rows, ",
        n_distinct(population_panel$country), " countries)")

# FIFA ranking pull -----------------------------------------------------------
# Two supported paths:
#
#   (A) Historical CSV: data/raw/fifa_ranking.csv with columns rank_date,
#       country_abrv, rank, total_points. Source: any maintained mirror of
#       FIFA's monthly ranking (e.g. samuraitruong/fifa-ranking-data, FIFA's
#       own export from inside.fifa.com). Gives the full time series for the
#       trajectory figure.
#
#   (B) Current snapshot: data/raw/fifa_current.csv with one row per panel
#       country (iso3, rank, points, as_of_date, verified). Faster to fill —
#       13 numbers from FIFA's current-ranking page. Sufficient for figs 4-5
#       and the regression; only the trajectory figure (fig3) is skipped.
#
# (A) is preferred when available; (B) is the fallback.

fifa_hist_path <- here("data", "raw", "fifa_ranking.csv")
fifa_curr_path <- here("data", "raw", "fifa_current.csv")

fifa_panel <- NULL

if (file.exists(fifa_hist_path)) {
  fifa_raw <- read_csv(fifa_hist_path, show_col_types = FALSE)
  expected <- c("rank_date", "country_abrv", "rank", "total_points")
  missing  <- setdiff(expected, names(fifa_raw))
  if (length(missing)) {
    stop("fifa_ranking.csv missing columns: ",
         paste(missing, collapse = ", "))
  }
  fifa_panel <- fifa_raw %>%
    transmute(
      iso3   = country_abrv,
      date   = as.Date(rank_date),
      rank   = as.integer(rank),
      points = as.numeric(total_points)
    ) %>%
    inner_join(country_panel %>% select(iso3, country, role),
               by = "iso3") %>%
    arrange(country, date)
  message("Read FIFA history (", nrow(fifa_panel), " rows, ",
          format(min(fifa_panel$date)), " to ",
          format(max(fifa_panel$date)), ")")
}

if (file.exists(fifa_curr_path)) {
  curr <- read_csv(fifa_curr_path, show_col_types = FALSE)
  curr_unverified <- curr %>% filter(!verified)
  if (nrow(curr_unverified) > 0) {
    warning(
      nrow(curr_unverified),
      " rows in fifa_current.csv are unverified. ",
      "Fill rank/points/as_of_date and set verified=TRUE."
    )
  } else {
    curr_panel <- curr %>%
      transmute(
        iso3,
        date   = as.Date(as_of_date),
        rank   = as.integer(rank),
        points = as.numeric(points)
      ) %>%
      inner_join(country_panel %>% select(iso3, country, role),
                 by = "iso3")
    if (is.null(fifa_panel)) {
      fifa_panel <- curr_panel
      message("Read FIFA current snapshot (", nrow(curr_panel),
              " countries) — no history; trajectory fig will be skipped.")
    } else {
      fifa_panel <- bind_rows(
        fifa_panel,
        curr_panel %>% anti_join(fifa_panel, by = c("iso3", "date"))
      ) %>% arrange(country, date)
      message("Folded current snapshot into history.")
    }
  }
}

if (is.null(fifa_panel)) {
  warning(
    "No FIFA ranking source found. Either:\n",
    "  (A) put a historical CSV at ", fifa_hist_path, ", OR\n",
    "  (B) fill ", fifa_curr_path, " with current ranks for the 13 panel ",
    "countries and set verified=TRUE.\nSkipping fifa_ranking_panel.csv."
  )
} else {
  write_csv(fifa_panel, here("data", "fifa_ranking_panel.csv"))
  message("Wrote fifa_ranking_panel.csv (", nrow(fifa_panel),
          " rows, ", n_distinct(fifa_panel$country), " countries)")
}

# Smallest-ever-WC-qualifier ground truth -------------------------------------
# Static panel of every WC qualification by countries below 1M population.
# Sourced from FIFA archive + UN DESA mid-year population estimates at the
# year of qualification. This drives Figure 1 (the social-media hook chart).
# Verify each row against FIFA's tournament archive before publication.

smallest_qualifiers <- tibble::tribble(
  ~country,         ~iso3, ~year, ~population_qual,
  "Iceland",        "ISL", 2018,  338000,
  "Trinidad and Tobago", "TTO", 2006, 1330000,
  "Jamaica",        "JAM", 1998,  2580000,
  "Slovenia",       "SVN", 2002,  2000000,
  "Slovenia",       "SVN", 2010,  2050000,
  "Northern Ireland","NIR", 1986,  1570000,
  "Wales",          "WAL", 1958,  2620000,
  "Wales",          "WAL", 2022,  3130000,
  "Cuba",           "CUB", 1938,  4150000,
  "Curaçao",        "CUW", 2026,  150000   # the case
)

write_csv(smallest_qualifiers, here("data", "smallest_qualifiers.csv"))
message("Wrote smallest_qualifiers.csv — REVIEW manually against FIFA archive")

message("\n01_data_pull.R complete.")
