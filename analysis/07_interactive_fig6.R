# WP-2026-01: build interactive HTML version of fig 6 for the blog
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/07_interactive_fig6.R")
# Reads:    data/global_panel.csv
# Writes:   figures/interactive/fig6_global_pop_vs_rank.html (self-contained)
#
# The output is a single standalone HTML file with all dependencies inlined.
# Drop it into Wix's HTML embed widget, or host it on the GitHub Pages site
# and iframe it into the blog post.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(plotly)
  library(htmlwidgets)
  library(here)
  library(scales)
})

# CE palette (same as 04_figures.R)
ce_blue       <- "#4A7A9A"
ce_coral      <- "#E76F51"
ce_powder     <- "#B8D0D8"
ce_grey       <- "#8A95A0"
ce_near_black <- "#091F38"

g <- read_csv(here("data", "global_panel.csv"), show_col_types = FALSE) |>
  filter(!is.na(population_latest), !is.na(rank), !is_uk_constituent) |>
  mutate(country = if_else(iso3 == "CUW", "Curaçao", country))

# Residual vs population-only specification (for tooltip)
m <- lm(rank ~ log(population_latest), data = g)
g$rank_pred <- predict(m)
g$residual  <- g$rank - g$rank_pred

g <- g |>
  mutate(
    is_highlight = iso3 == "CUW",
    tooltip = paste0(
      "<b>", country, "</b><br>",
      "FIFA rank: ", rank, "<br>",
      "Population: ", comma(population_latest), "<br>",
      "Residual: ", round(residual), " places ",
      if_else(residual < 0, "better than population alone predicts",
              "worse than population alone predicts"),
      if_else(!is.na(diaspora_per_capita),
              paste0("<br>Diaspora per resident: ",
                     round(diaspora_per_capita, 2)),
              "")
    )
  )

p <- ggplot(g, aes(x = population_latest, y = rank, text = tooltip)) +
  geom_smooth(method = "lm", se = TRUE,
              color = ce_grey, fill = ce_powder, alpha = 0.35,
              linewidth = 0.5, formula = y ~ log(x), inherit.aes = FALSE,
              aes(x = population_latest, y = rank)) +
  geom_point(aes(color = is_highlight, size = is_highlight, alpha = is_highlight)) +
  scale_x_log10(labels = comma) +
  scale_y_reverse(breaks = c(1, 25, 50, 100, 150, 200)) +
  scale_color_manual(values = c("FALSE" = ce_blue, "TRUE" = ce_coral),
                     guide = "none") +
  scale_size_manual(values = c("FALSE" = 2.4, "TRUE" = 4.8),
                    guide = "none") +
  scale_alpha_manual(values = c("FALSE" = 0.55, "TRUE" = 1),
                     guide = "none") +
  labs(
    title    = "Curaçao ranks 80 places better than its population alone predicts",
    subtitle = "Hover any country. FIFA rank vs population, 202 countries.",
    x        = "Population (log scale)",
    y        = "FIFA rank (lower = better)"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold", color = ce_near_black,
                                 size = 15, lineheight = 1.05),
    plot.subtitle = element_text(color = ce_near_black, size = 11),
    axis.title    = element_text(color = ce_near_black),
    axis.text     = element_text(color = ce_near_black),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "#E8ECEF", linewidth = 0.3)
  )

pp <- ggplotly(p, tooltip = "text") |>
  config(displayModeBar = FALSE) |>
  layout(
    margin = list(l = 60, r = 20, t = 60, b = 50),
    hoverlabel = list(
      bgcolor = "white",
      bordercolor = ce_blue,
      font = list(family = "Arial", size = 12, color = ce_near_black)
    )
  )

dir.create(here("figures", "interactive"), showWarnings = FALSE, recursive = TRUE)
out <- here("figures", "interactive", "fig6_global_pop_vs_rank.html")
saveWidget(pp, out, selfcontained = TRUE,
           title = "Curaçao at the 2026 World Cup: FIFA rank vs population")

message("Wrote ", out)
message("File size: ",
        format(file.info(out)$size / 1024 / 1024, digits = 2),
        " MB")
