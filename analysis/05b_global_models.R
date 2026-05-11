# WP-2026-01: panel regression on the global FIFA panel (n ~ 200)
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/05b_global_models.R")
# Reads:    data/global_panel.csv (one row per FIFA-ranked country)
# Writes:   data/global_regression_results.csv
#           data/global_residuals.csv
#
# Specifications, plain-English form:
#   G1: rank ~ log(population)
#   G2: rank ~ log(population) + log(diaspora_per_capita)
#   G3: rank ~ log(population) * log(diaspora_per_capita)
#   G4: rank ~ log(population) + log(diaspora_per_capita) + log(diaspora_2024)
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(broom)
  library(here)
})

set.seed(20260510)

g <- read_csv(here("data", "global_panel.csv"), show_col_types = FALSE) |>
  filter(!is.na(population_latest),
         !is.na(diaspora_2024),
         diaspora_2024 > 0,
         population_latest > 0) |>
  mutate(
    log_pop      = log(population_latest),
    log_dia      = log(diaspora_2024),
    log_dia_pc   = log(diaspora_per_capita)
  )

message("Analysis panel: n = ", nrow(g))

# Specifications
specs <- list(
  G1 = lm(rank ~ log_pop,                      data = g),
  G2 = lm(rank ~ log_pop + log_dia_pc,         data = g),
  G3 = lm(rank ~ log_pop * log_dia_pc,         data = g),
  G4 = lm(rank ~ log_pop + log_dia_pc + log_dia, data = g)
)

results <- bind_rows(lapply(names(specs), function(nm) {
  fit  <- specs[[nm]]
  tidy(fit, conf.int = TRUE) |>
    mutate(spec   = nm,
           n      = nobs(fit),
           r2     = summary(fit)$r.squared,
           adj_r2 = summary(fit)$adj.r.squared)
})) |>
  select(spec, term, estimate, std.error, statistic, p.value,
         conf.low, conf.high, n, r2, adj_r2)

write_csv(results, here("data", "global_regression_results.csv"))
message("\nRegression results:")
print(results, n = Inf)

# Residual table from the headline spec (G2)
m <- specs$G2
residuals_table <- g |>
  mutate(
    rank_pred  = predict(m, newdata = g),
    residual   = rank - rank_pred
  ) |>
  select(country, iso3, rank, rank_pred, residual,
         population_latest, diaspora_2024, diaspora_per_capita) |>
  arrange(residual)

write_csv(residuals_table, here("data", "global_residuals.csv"))

message("\nTop 10 over-ranked (negative residual = ranks BETTER than predicted):")
print(head(residuals_table, 10) |>
        select(country, rank, rank_pred, residual, diaspora_per_capita))
message("\nTop 10 under-ranked (positive residual = ranks WORSE than predicted):")
print(tail(residuals_table, 10) |>
        select(country, rank, rank_pred, residual, diaspora_per_capita))
