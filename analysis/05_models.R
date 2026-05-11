# WP-2026-01: panel regression of ranking residual on diaspora moderation
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/05_models.R")
# Reads:    data/diaspora_panel.csv, data/squad_values_panel.csv,
#           data/fifa_ranking_panel.csv, data/country_panel.csv
# Writes:   data/regression_panel.csv (analysis-ready merged panel)
#           data/regression_results.csv (tidy coefficients across specs)
#           data/residuals_table.csv (per-country residuals for figure 5)
#
# Specifications:
#   M1: rank ~ log(squad_value)                          (baseline)
#   M2: rank ~ log(squad_value) + ratio_un               (additive)
#   M3: rank ~ log(squad_value) * ratio_un               (interaction = headline)
#   M4: rank ~ log(squad_value) + ratio_un + confederation
#
# Robustness:
#   M3a: same as M3 with ratio_heritage on the 4-country focal subset
#   M3b: same as M3 with rank window-averaged over last 12 months
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(broom)
  library(here)
})

set.seed(20260509)

# -----------------------------------------------------------------------------
# Build the analysis panel

dia  <- read_csv(here("data", "diaspora_panel.csv"),       show_col_types = FALSE)
sq   <- read_csv(here("data", "squad_values_panel.csv"),   show_col_types = FALSE)
ctry <- read_csv(here("data", "country_panel.csv"),        show_col_types = FALSE)

fifa <- read_csv(here("data", "fifa_ranking_panel.csv"),
                 show_col_types = FALSE) |>
  arrange(iso3, date)

fifa_latest <- fifa |>
  group_by(iso3) |>
  filter(date == max(date)) |>
  ungroup() |>
  transmute(iso3, rank, points)

fifa_avg12 <- fifa |>
  group_by(iso3) |>
  filter(date >= max(date) - 365) |>
  summarise(rank_avg12 = mean(rank, na.rm = TRUE),
            points_avg12 = mean(points, na.rm = TRUE),
            .groups = "drop")

panel <- ctry |>
  select(iso3, country, role, confederation) |>
  inner_join(dia |> select(iso3, residents, ratio_un, ratio_heritage),
             by = "iso3") |>
  inner_join(sq |> select(iso3, total_value_mil, median_value_mil,
                          n_valued, n_players),
             by = "iso3") |>
  inner_join(fifa_latest, by = "iso3") |>
  left_join(fifa_avg12,   by = "iso3") |>
  mutate(
    log_squad_value = log(total_value_mil),
    confederation   = factor(confederation,
                             levels = c("UEFA", "CONCACAF", "CAF"))
  )

write_csv(panel, here("data", "regression_panel.csv"))
message("Wrote regression_panel.csv (", nrow(panel), " countries)")

if (nrow(panel) < 8) {
  warning(
    "Regression panel has ", nrow(panel), " rows. ",
    "Specifications below run but inferences should be treated as illustrative."
  )
}

# -----------------------------------------------------------------------------
# Specifications

m1 <- lm(rank ~ log_squad_value, data = panel)
m2 <- lm(rank ~ log_squad_value + ratio_un, data = panel)
m3 <- lm(rank ~ log_squad_value * ratio_un, data = panel)
m4 <- lm(rank ~ log_squad_value + ratio_un + confederation, data = panel)

# Robustness: heritage-pool ratio on focal subset
panel_heritage <- panel |> filter(!is.na(ratio_heritage))
m3a <- if (nrow(panel_heritage) >= 4) {
  lm(rank ~ log_squad_value * ratio_heritage, data = panel_heritage)
} else NULL

# Robustness: 12-month-average rank as outcome
m3b <- if (sum(!is.na(panel$rank_avg12)) >= 8) {
  lm(rank_avg12 ~ log_squad_value * ratio_un, data = panel)
} else NULL

specs <- list(M1 = m1, M2 = m2, M3 = m3, M4 = m4,
              M3a = m3a, M3b = m3b)
specs <- specs[!sapply(specs, is.null)]

results <- bind_rows(lapply(names(specs), function(nm) {
  fit  <- specs[[nm]]
  tidy(fit, conf.int = TRUE) |>
    mutate(spec = nm,
           n    = nobs(fit),
           r2   = summary(fit)$r.squared,
           adj_r2 = summary(fit)$adj.r.squared)
})) |>
  select(spec, term, estimate, std.error, statistic, p.value,
         conf.low, conf.high, n, r2, adj_r2)

write_csv(results, here("data", "regression_results.csv"))

message("\nRegression results:")
print(results, n = Inf)

# -----------------------------------------------------------------------------
# Residual table for figure 5 caption + paper findings section
#
# Define under-ranking as the gap between actual rank and the rank predicted by
# squad value alone (M1). Positive residual = ranked worse than squad value
# alone predicts. Used as the y-axis in figure 5.

residuals_table <- panel |>
  mutate(
    rank_pred_m1 = predict(m1, newdata = panel),
    residual_m1  = rank - rank_pred_m1
  ) |>
  select(country, iso3, role, confederation,
         residents, ratio_un, ratio_heritage,
         total_value_mil, rank, rank_pred_m1, residual_m1) |>
  arrange(desc(residual_m1))

write_csv(residuals_table, here("data", "residuals_table.csv"))

message("\nResiduals (positive = under-ranked given squad value):")
print(residuals_table |>
        select(country, ratio_un, total_value_mil, rank,
               rank_pred_m1, residual_m1),
      n = Inf)

message("\n05_models.R complete.")
