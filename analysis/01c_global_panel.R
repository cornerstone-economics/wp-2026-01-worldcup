# WP-2026-01: build the global analysis panel
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/01c_global_panel.R")
# Reads:    data/fifa_global.csv (parsed FIFA ranking)
#           data/diaspora_global.csv (UN DESA migrant stock)
# Writes:   data/global_panel.csv (FIFA + WDI population + UN DESA diaspora,
#           one row per country)

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(WDI)
  library(countrycode)
  library(here)
})

set.seed(20260510)

fifa <- read_csv(here("data", "fifa_global.csv"), show_col_types = FALSE)
dia  <- read_csv(here("data", "diaspora_global.csv"), show_col_types = FALSE)

# -----------------------------------------------------------------------------
# Map FIFA country names to ISO3
# countrycode handles most cases; some FIFA-specific spellings need overrides.

fifa_iso <- fifa |>
  mutate(
    iso3 = countrycode(country, "country.name", "iso3c",
                       custom_match = c(
                         "England"                    = "GBR",
                         "Wales"                      = "GBR",
                         "Scotland"                   = "GBR",
                         "Northern Ireland"           = "GBR",
                         "Curacao"                    = "CUW",
                         "Türkiye"                    = "TUR",
                         "IR Iran"                    = "IRN",
                         "Korea Republic"             = "KOR",
                         "Korea DPR"                  = "PRK",
                         "Cabo Verde"                 = "CPV",
                         "Côte d'Ivoire"              = "CIV",
                         "Hong Kong, China"           = "HKG",
                         "Chinese Taipei"             = "TWN",
                         "Republic of Ireland"        = "IRL",
                         "Czechia"                    = "CZE",
                         "USA"                        = "USA",
                         "China PR"                   = "CHN",
                         "Congo DR"                   = "COD",
                         "Congo"                      = "COG",
                         "Macau"                      = "MAC",
                         "St Kitts and Nevis"         = "KNA",
                         "St Lucia"                   = "LCA",
                         "St Vincent and the Grenadines" = "VCT",
                         "São Tomé and Príncipe"      = "STP",
                         "Antigua and Barbuda"        = "ATG",
                         "Trinidad and Tobago"        = "TTO",
                         "Bosnia and Herzegovina"     = "BIH",
                         "Brunei Darussalam"          = "BRN",
                         "Faroe Islands"              = "FRO",
                         "Cook Islands"               = "COK",
                         "Tahiti"                     = "PYF",
                         "Cayman Islands"             = "CYM",
                         "British Virgin Islands"     = "VGB",
                         "US Virgin Islands"          = "VIR",
                         "Turks and Caicos Islands"   = "TCA",
                         "American Samoa"             = "ASM",
                         "New Caledonia"              = "NCL",
                         "Aruba"                      = "ABW",
                         "Kosovo"                     = "XKX"
                       ))
  )

# UK constituent countries — keep distinct codes for the panel even though
# countrycode maps all four to GBR. Use FIFA-specific suffixes.
fifa_iso <- fifa_iso |>
  mutate(iso3 = case_when(
    country == "England"          ~ "ENG",
    country == "Wales"            ~ "WAL",
    country == "Scotland"         ~ "SCT",
    country == "Northern Ireland" ~ "NIR",
    TRUE                          ~ iso3
  ))

unmatched_fifa <- fifa_iso |> filter(is.na(iso3))
if (nrow(unmatched_fifa) > 0) {
  message("FIFA names without ISO3 (extend custom_match):")
  print(unmatched_fifa)
}

# -----------------------------------------------------------------------------
# Map UN DESA M49 origin codes to ISO3

dia_iso <- dia |>
  mutate(
    iso3 = countrycode(origin_code, "un", "iso3c"),
    iso3 = if_else(origin == "Curaçao", "CUW", iso3)
  ) |>
  filter(!is.na(iso3))

# -----------------------------------------------------------------------------
# Pull WDI population (latest year) for all FIFA ISOs we have

pop_raw <- WDI(
  country   = "all",
  indicator = c(population = "SP.POP.TOTL"),
  start     = 2020,
  end       = 2024
)

pop_latest <- pop_raw |>
  as_tibble() |>
  filter(!is.na(population)) |>
  group_by(iso3c) |>
  filter(year == max(year)) |>
  ungroup() |>
  transmute(iso3 = iso3c, population_latest = population)

# UK constituent populations (2024 estimates from ONS)
uk_pop <- tibble::tribble(
  ~iso3, ~population_latest,
  "ENG", 57106400,
  "WAL", 3164400,
  "SCT", 5490100,
  "NIR", 1910500
)
pop_latest <- bind_rows(pop_latest, uk_pop)

# -----------------------------------------------------------------------------
# Build the global panel
# UK constituents share GBR diaspora data — use NA for UK splits since UN
# DESA only tracks at sovereign level.

global_panel <- fifa_iso |>
  filter(!is.na(iso3)) |>
  left_join(pop_latest, by = "iso3") |>
  left_join(dia_iso |> select(iso3, diaspora_2024), by = "iso3") |>
  mutate(
    diaspora_per_capita = diaspora_2024 / population_latest,
    is_uk_constituent   = iso3 %in% c("ENG", "WAL", "SCT", "NIR")
  )

write_csv(global_panel, here("data", "global_panel.csv"))

message("Wrote global_panel.csv (", nrow(global_panel), " rows)")
message("Coverage:")
message("  with population:  ", sum(!is.na(global_panel$population_latest)))
message("  with diaspora:    ", sum(!is.na(global_panel$diaspora_2024)))
message("  with both:        ",
        sum(!is.na(global_panel$population_latest) &
            !is.na(global_panel$diaspora_2024)))

unmatched_pop <- global_panel |>
  filter(is.na(population_latest), !is_uk_constituent)
if (nrow(unmatched_pop) > 0) {
  message("\nFIFA countries missing population:")
  print(unmatched_pop |> select(rank, country, iso3))
}

unmatched_dia <- global_panel |>
  filter(is.na(diaspora_2024), !is_uk_constituent)
if (nrow(unmatched_dia) > 0) {
  message("\nFIFA countries missing UN DESA diaspora:")
  print(unmatched_dia |> select(rank, country, iso3) |> head(20))
}
