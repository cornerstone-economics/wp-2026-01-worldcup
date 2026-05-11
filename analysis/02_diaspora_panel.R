# WP-2026-01: diaspora panel construction
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/02_diaspora_panel.R")
# Reads:    data/raw/diaspora_sources.csv (hand-curated, must be verified)
# Writes:   data/diaspora_panel.csv

# -----------------------------------------------------------------------------
# Two diaspora measures travel through the panel:
#
#   M1: migrant_stock_un  — persons born in country X currently living abroad
#       (UN DESA International Migrant Stock 2020). Cross-country comparable,
#       1st-generation only. Regression input because methodology is consistent
#       across all 13 countries.
#
#   M2: heritage_pool     — football-eligibility pool, including 2nd-generation
#       descendants. CBS NL for CUW/SUR, government/IOM estimates for CPV/ALB.
#       Available only for the 4 focal countries; NA elsewhere. Used for case
#       discussion, not for the regression.
#
# Both ratios = stock / residents. Residents are 2024 mid-year.
#
# Every row in diaspora_sources.csv carries a verified flag. The script
# refuses to write the panel if any row is FALSE. This enforces the
# validate_inputs_before_headline discipline.
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(here)
})

set.seed(20260509)

src_path <- here("data", "raw", "diaspora_sources.csv")
src <- read_csv(src_path, show_col_types = FALSE)

unverified <- src |> filter(!verified)
if (nrow(unverified) > 0) {
  message(
    "ERROR: ", nrow(unverified),
    " unverified rows in diaspora_sources.csv:"
  )
  print(unverified |> select(country, measure, value, source_short))
  stop(
    "Verify each value against its cited source, ",
    "set verified=TRUE, then re-run."
  )
}

country_roles_path <- here("data", "country_panel.csv")
if (!file.exists(country_roles_path)) {
  stop("country_panel.csv missing. Run 01_data_pull.R first.")
}
country_roles <- read_csv(country_roles_path, show_col_types = FALSE) |>
  select(iso3, role, confederation)

dia <- src |>
  select(country, iso3, measure, value) |>
  pivot_wider(names_from = measure, values_from = value)

heritage_cols <- intersect(
  c("heritage_pool_nl", "heritage_pool_govt"),
  names(dia)
)
if (length(heritage_cols) == 0) {
  stop("No heritage_pool_* columns found in diaspora_sources.csv")
}

dia <- dia |>
  mutate(heritage_pool = coalesce(!!!rlang::syms(heritage_cols)))

diaspora_panel <- dia |>
  transmute(
    country,
    iso3,
    residents,
    migrant_stock_un,
    heritage_pool,
    ratio_un       = migrant_stock_un / residents,
    ratio_heritage = heritage_pool    / residents
  ) |>
  left_join(country_roles, by = "iso3") |>
  arrange(desc(ratio_un))

write_csv(diaspora_panel, here("data", "diaspora_panel.csv"))

message("Wrote diaspora_panel.csv:")
print(diaspora_panel, n = Inf)

message("\n02_diaspora_panel.R complete.")
