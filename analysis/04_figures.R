# WP-2026-01: figures (paper + social-media)
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/04_figures.R")
# Reads:    data/*.csv (panels built by 01-03)
# Writes:   figures/*.png (paper-size 1600x1000) and
#           figures/social/*.png (social-card 1200x1200 + 1200x675)
#
# Each figure has a paper variant and one or two social-card variants. The
# paper variant has small text and a longer caption; the social variants have
# large text, a baked-in title, and Cornerstone-Economics attribution.
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(ggplot2)
  library(ggrepel)
  library(scales)
  library(stringr)
  library(here)
})

set.seed(20260509)

dir.create(here("figures"), showWarnings = FALSE)
dir.create(here("figures", "social"), showWarnings = FALSE)

# -----------------------------------------------------------------------------
# CE palette and theme

ce_blue       <- "#4A7A9A"
ce_coral      <- "#E76F51"
ce_gold       <- "#E8B84D"
ce_peach      <- "#F4BC8B"
ce_beige      <- "#C9B99B"
ce_powder     <- "#B8D0D8"
ce_near_black <- "#091F38"
ce_grey       <- "#8A95A0"

theme_ce <- function(base_size = 12, social = FALSE) {
  size <- if (social) base_size * 1.6 else base_size
  theme_minimal(base_size = size, base_family = "sans") +
    theme(
      plot.title         = element_text(face = "bold", color = ce_near_black,
                                        size = size * 1.4, lineheight = 1.05),
      plot.subtitle      = element_text(color = ce_near_black,
                                        size = size * 0.95, lineheight = 1.1),
      plot.caption       = element_text(color = ce_grey, hjust = 0,
                                        size = size * 0.75),
      axis.title         = element_text(color = ce_near_black, size = size),
      axis.text          = element_text(color = ce_near_black,
                                        size = size * 0.9),
      panel.grid.minor   = element_blank(),
      panel.grid.major   = element_line(color = "#E8ECEF", linewidth = 0.3),
      legend.title       = element_text(color = ce_near_black, size = size),
      legend.text        = element_text(color = ce_near_black,
                                        size = size * 0.9),
      plot.title.position   = "plot",
      plot.caption.position = "plot",
      plot.margin           = margin(16, 16, 12, 16)
    )
}

ce_attribution <- "Source: see notes. Cornerstone Economics WP-2026-01"

save_paper <- function(p, name, w = 8, h = 5) {
  ggsave(here("figures", paste0(name, ".png")), p,
         width = w, height = h, dpi = 200, bg = "white")
}

save_social <- function(p, name, format = c("square", "wide")) {
  format <- match.arg(format)
  dims <- if (format == "square") c(8, 8) else c(10, 5.625)
  ggsave(
    here("figures", "social", paste0(name, "_", format, ".png")),
    p, width = dims[1], height = dims[2], dpi = 150, bg = "white"
  )
}

# -----------------------------------------------------------------------------
# Figure 1: Smallest country to qualify for a World Cup

build_fig1 <- function() {
  path <- here("data", "smallest_qualifiers.csv")
  if (!file.exists(path)) {
    message("fig1 skipped: smallest_qualifiers.csv missing")
    return(invisible(NULL))
  }
  d <- read_csv(path, show_col_types = FALSE) |>
    mutate(
      label = paste0(country, " (", year, ")"),
      pop_k = population_qual / 1000,
      is_curacao = iso3 == "CUW"
    ) |>
    arrange(pop_k) |>
    mutate(label = factor(label, levels = label))

  p <- ggplot(d, aes(x = pop_k, y = label, fill = is_curacao)) +
    geom_col(width = 0.7) +
    geom_text(aes(label = comma(round(pop_k))),
              hjust = -0.15, size = 3.5, color = ce_near_black) +
    scale_fill_manual(values = c("FALSE" = ce_powder, "TRUE" = ce_coral),
                      guide = "none") +
    scale_x_continuous(labels = comma,
                       expand = expansion(mult = c(0, 0.18))) +
    labs(
      title    = "Curaçao is the smallest country ever to qualify for a World Cup",
      subtitle = "Population at year of qualification, countries under 5 million",
      x        = "Population (thousands) at year of qualification",
      y        = NULL,
      caption  = paste(
        "Source: FIFA tournament archive; UN DESA mid-year population estimates.",
        "Cornerstone Economics WP-2026-01."
      )
    ) +
    theme_ce()

  save_paper(p, "fig1_smallest_qualifiers", w = 8, h = 5)

  p_social <- p + theme_ce(social = TRUE)
  save_social(p_social, "fig1_smallest_qualifiers", "square")
  save_social(p_social, "fig1_smallest_qualifiers", "wide")
  invisible(p)
}

# -----------------------------------------------------------------------------
# Figure 2: Where the squad lives — ABC contrast

build_fig2 <- function() {
  path <- here("data", "abc_squads_iter1.csv")
  if (!file.exists(path)) {
    message("fig2 skipped: abc_squads_iter1.csv missing")
    return(invisible(NULL))
  }
  squads <- read_csv(path, show_col_types = FALSE)

  team_labels <- c(
    "ARU-W" = "Aruba women",
    "CUW-W" = "Curaçao women",
    "ARU-M" = "Aruba men",
    "CUW-M" = "Curaçao men"
  )

  loc_levels <- c(
    "European top flight",
    "European 2nd tier",
    "European 3rd tier or amateur",
    "Other foreign professional",
    "Local island league",
    "Reserve / youth / unknown"
  )

  d <- squads |>
    mutate(
      location = case_when(
        league_tier == "L"                                      ~ "Local island league",
        league_tier == "1" & club_country %in% c("NLD","DEU","BEL","GRC","TUR","CHE","GBR") ~ "European top flight",
        league_tier == "2" & club_country %in% c("NLD","DEU","BEL","GRC","TUR","CHE","GBR") ~ "European 2nd tier",
        league_tier == "3" & club_country %in% c("NLD","DEU","BEL","GRC","TUR","CHE","GBR") ~ "European 3rd tier or amateur",
        league_tier %in% c("1","2","3") & !club_country %in% c("NLD","DEU","BEL","GRC","TUR","CHE","GBR","X") ~ "Other foreign professional",
        league_tier %in% c("R","Y","X") | club_country == "X"   ~ "Reserve / youth / unknown",
        TRUE                                                    ~ "Reserve / youth / unknown"
      ),
      location = factor(location, levels = rev(loc_levels)),
      team     = factor(team_labels[team_code],
                        levels = rev(c("Curaçao men", "Aruba men",
                                       "Curaçao women", "Aruba women")))
    ) |>
    count(team, location)

  loc_palette <- c(
    "European top flight"          = ce_coral,
    "European 2nd tier"            = ce_gold,
    "European 3rd tier or amateur" = ce_peach,
    "Other foreign professional"   = ce_blue,
    "Local island league"          = ce_powder,
    "Reserve / youth / unknown"    = ce_grey
  )

  p <- ggplot(d, aes(y = team, x = n, fill = location)) +
    geom_col(width = 0.7) +
    geom_text(aes(label = ifelse(n >= 2, n, "")),
              position = position_stack(vjust = 0.5),
              color = "white", size = 3.5, fontface = "bold") +
    scale_fill_manual(values = loc_palette,
                      breaks = loc_levels) +
    scale_x_continuous(expand = expansion(mult = c(0, 0.02))) +
    labs(
      title    = "Where the squad lives",
      subtitle = "Composition of Aruba and Curaçao national-team squads by where players play their club football",
      x        = "Number of players in squad",
      y        = NULL,
      fill     = NULL,
      caption  = paste(
        "Source: Cornerstone Economics ABC squads dataset (iter 1, Apr 2026).",
        "Most recent confirmed squad calls per team."
      )
    ) +
    theme_ce() +
    theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 2, reverse = FALSE))

  save_paper(p, "fig2_squad_location", w = 8.5, h = 5)

  p_social <- p + theme_ce(social = TRUE) +
    theme(legend.position = "bottom") +
    guides(fill = guide_legend(nrow = 3, reverse = FALSE))
  save_social(p_social, "fig2_squad_location", "square")
  save_social(p_social, "fig2_squad_location", "wide")
  invisible(p)
}

# -----------------------------------------------------------------------------
# Figure 3: FIFA ranking trajectory 2014-2026, 4 focal countries

build_fig3 <- function() {
  path <- here("data", "fifa_ranking_panel.csv")
  if (!file.exists(path)) {
    message("fig3 skipped: fifa_ranking_panel.csv missing")
    return(invisible(NULL))
  }
  d <- read_csv(path, show_col_types = FALSE) |>
    filter(role %in% c("case", "comparator")) |>
    filter(date >= as.Date("2014-01-01"))

  if (nrow(d) == 0) {
    message("fig3 skipped: no rows in fifa_ranking_panel for focal four")
    return(invisible(NULL))
  }

  # Need ≥2 observations per country for a trajectory line.
  per_country <- d |> count(country)
  if (max(per_country$n) < 2) {
    message("fig3 skipped: only snapshot data, no time series")
    return(invisible(NULL))
  }

  endpoints <- d |>
    group_by(country) |>
    filter(date == max(date)) |>
    ungroup()

  focal_palette <- c(
    "Curaçao"    = ce_coral,
    "Cabo Verde" = ce_blue,
    "Albania"    = ce_gold,
    "Suriname"   = ce_peach
  )

  p <- ggplot(d, aes(x = date, y = rank, color = country)) +
    geom_step(linewidth = 0.9) +
    geom_point(data = endpoints, aes(x = date, y = rank), size = 2.5) +
    geom_text(data = endpoints,
              aes(label = paste0(country, " (", rank, ")")),
              hjust = -0.05, size = 3.6, fontface = "bold") +
    scale_y_reverse(breaks = c(1, 25, 50, 75, 100, 125, 150, 175, 200)) +
    scale_x_date(date_breaks = "2 years", date_labels = "%Y",
                 expand = expansion(mult = c(0.02, 0.18))) +
    scale_color_manual(values = focal_palette, guide = "none") +
    labs(
      title    = "FIFA ranking trajectories",
      subtitle = "Curaçao and three small-state-with-diaspora comparators, 2014-2026",
      x        = NULL,
      y        = "FIFA rank (1 = best)",
      caption  = paste(
        "Source: FIFA monthly ranking history (cashncarry/FIFAWorldRanking mirror of FIFA inside.fifa.com).",
        "Cornerstone Economics WP-2026-01."
      )
    ) +
    theme_ce()

  save_paper(p, "fig3_ranking_trajectory", w = 9, h = 5)

  p_social <- p + theme_ce(social = TRUE)
  save_social(p_social, "fig3_ranking_trajectory", "wide")
  invisible(p)
}

# -----------------------------------------------------------------------------
# Figure 4: Population vs current FIFA rank, 13-country panel

build_fig4 <- function() {
  pop_path  <- here("data", "population_panel.csv")
  fifa_path <- here("data", "fifa_ranking_panel.csv")
  if (!file.exists(pop_path) || !file.exists(fifa_path)) {
    message("fig4 skipped: missing population or fifa panel")
    return(invisible(NULL))
  }
  pop <- read_csv(pop_path, show_col_types = FALSE) |>
    group_by(iso3) |>
    filter(year == max(year)) |>
    ungroup() |>
    select(iso3, country, population)

  fifa_latest <- read_csv(fifa_path, show_col_types = FALSE) |>
    group_by(iso3) |>
    filter(date == max(date)) |>
    ungroup() |>
    select(iso3, role, rank)

  d <- pop |>
    inner_join(fifa_latest, by = "iso3") |>
    mutate(highlight = role == "case")

  if (nrow(d) == 0) {
    message("fig4 skipped: empty join")
    return(invisible(NULL))
  }

  p <- ggplot(d, aes(x = population, y = rank)) +
    geom_smooth(method = "lm", se = TRUE,
                color = ce_grey, fill = ce_powder, alpha = 0.4,
                linewidth = 0.6, formula = y ~ log(x)) +
    geom_point(aes(color = highlight), size = 3.5) +
    geom_text_repel(
      aes(label = country, fontface = ifelse(highlight, "bold", "plain")),
      size = 3.6, color = ce_near_black,
      box.padding = 0.4, max.overlaps = 20
    ) +
    scale_x_log10(labels = comma) +
    scale_y_reverse() +
    scale_color_manual(values = c("FALSE" = ce_blue, "TRUE" = ce_coral),
                       guide = "none") +
    labs(
      title    = "Same population, very different FIFA rank",
      subtitle = "Population alone leaves the rank under-determined for small states",
      x        = "Population (log scale)",
      y        = "FIFA rank (1 = best)",
      caption  = paste(
        "Source: World Bank WDI; FIFA men's ranking (10 May 2026).",
        "Trend line: rank ~ log(population), 95% CI."
      )
    ) +
    theme_ce()

  save_paper(p, "fig4_pop_vs_rank", w = 8, h = 5.5)

  p_social <- p + theme_ce(social = TRUE)
  save_social(p_social, "fig4_pop_vs_rank", "square")
  invisible(p)
}

# -----------------------------------------------------------------------------
# Figure 5: Per-capita squad value vs population — headline finding
#
# Replaces an earlier residual-vs-diaspora-ratio version. The original
# regression (rank ~ squad_value × diaspora_ratio) did not produce a
# detectable interaction at n=13. The descriptive per-capita-squad pattern
# is the empirical claim the data does support: Curaçao matches Iceland
# at 38% of Iceland's population.

build_fig5 <- function() {
  sq_path  <- here("data", "squad_values_panel.csv")
  pop_path <- here("data", "population_panel.csv")
  if (!file.exists(sq_path) || !file.exists(pop_path)) {
    message("fig5 skipped: requires squad_values_panel and population_panel")
    return(invisible(NULL))
  }
  sq <- read_csv(sq_path, show_col_types = FALSE)
  pop <- read_csv(pop_path, show_col_types = FALSE) |>
    group_by(iso3) |>
    filter(year == max(year)) |>
    ungroup() |>
    select(iso3, country, population)

  d <- sq |>
    select(-country) |>
    inner_join(pop, by = "iso3") |>
    mutate(
      per_capita_eur = total_value_mil * 1e6 / population,
      highlight = iso3 %in% c("CUW", "ISL")
    )

  if (nrow(d) < 5) {
    message("fig5 skipped: panel join produced <5 rows")
    return(invisible(NULL))
  }

  p <- ggplot(d, aes(x = population, y = per_capita_eur)) +
    geom_smooth(method = "lm", se = TRUE,
                color = ce_grey, fill = ce_powder, alpha = 0.3,
                linewidth = 0.5, formula = y ~ log(x)) +
    geom_point(aes(color = highlight), size = 3.5) +
    geom_text_repel(
      aes(label = country, fontface = ifelse(highlight, "bold", "plain")),
      size = 3.6, color = ce_near_black,
      box.padding = 0.4, max.overlaps = 20
    ) +
    scale_x_log10(labels = comma) +
    scale_y_continuous(labels = function(x) paste0("€", round(x))) +
    scale_color_manual(values = c("FALSE" = ce_blue, "TRUE" = ce_coral),
                       guide = "none") +
    labs(
      title    = "Curaçao sits level with Iceland in per-capita squad value",
      subtitle = paste0(
        "Transfermarkt squad value per resident, 13-country panel. ",
        "Curaçao at €184 sits level with Iceland's €192 on 40% of Iceland's population."
      ),
      x        = "Population (log scale)",
      y        = "Squad market value per resident",
      caption  = paste(
        "Sources: Transfermarkt national-team headers (10 May 2026);",
        "World Bank WDI population (latest)."
      )
    ) +
    theme_ce()

  save_paper(p, "fig5_per_capita_squad", w = 8.5, h = 5.5)

  p_social <- p + theme_ce(social = TRUE)
  save_social(p_social, "fig5_per_capita_squad", "square")
  save_social(p_social, "fig5_per_capita_squad", "wide")
  invisible(p)
}

# -----------------------------------------------------------------------------
# Figure 6: Rank vs population, GLOBAL panel (n=202)
#
# The headline empirical claim of the paper. Built on UN DESA + WDI + the
# parsed global FIFA ranking. Curaçao is the 7th-most-over-ranked country in
# the world relative to its population alone (residual ~ -80 ranks).

build_fig6 <- function() {
  path <- here("data", "global_residuals.csv")
  if (!file.exists(path)) {
    message("fig6 skipped: global_residuals.csv missing")
    return(invisible(NULL))
  }
  d <- read_csv(path, show_col_types = FALSE) |>
    mutate(
      highlight = iso3 == "CUW",
      label_it  = iso3 %in% c("CUW", "ISL", "URY", "HRV", "PRT", "BEL",
                              "NLD", "PAN", "BRA", "ARG", "DEU", "ESP",
                              "PAK", "IND", "BGD", "CHN")
    )

  p <- ggplot(d, aes(x = population_latest, y = rank)) +
    geom_smooth(method = "lm", se = TRUE,
                color = ce_grey, fill = ce_powder, alpha = 0.4,
                linewidth = 0.5, formula = y ~ log(x)) +
    geom_point(aes(color = highlight, alpha = highlight,
                   size = highlight)) +
    geom_text_repel(
      data = d |> filter(label_it),
      aes(label = country,
          fontface = ifelse(highlight, "bold", "plain")),
      size = 3.6, color = ce_near_black,
      box.padding = 0.45, max.overlaps = 30
    ) +
    scale_x_log10(labels = comma) +
    scale_y_reverse(breaks = c(1, 25, 50, 100, 150, 200)) +
    scale_color_manual(values = c("FALSE" = ce_blue, "TRUE" = ce_coral),
                       guide = "none") +
    scale_alpha_manual(values = c("FALSE" = 0.55, "TRUE" = 1),
                       guide = "none") +
    scale_size_manual(values = c("FALSE" = 2, "TRUE" = 4.2),
                      guide = "none") +
    labs(
      title    = "Curaçao ranks 80 places better than its population alone predicts",
      subtitle = paste0(
        "FIFA rank vs population, 202 countries. Curaçao sits with Uruguay, ",
        "Croatia, Portugal — at a fraction of the population."
      ),
      x        = "Population (log scale)",
      y        = "FIFA rank (1 = best)",
      caption  = paste(
        "Sources: FIFA men's ranking (10 May 2026); World Bank WDI population.",
        "Trend: rank ~ log(population), 95% CI."
      )
    ) +
    theme_ce()

  save_paper(p, "fig6_global_pop_vs_rank", w = 9, h = 5.5)

  p_social <- p + theme_ce(social = TRUE)
  save_social(p_social, "fig6_global_pop_vs_rank", "wide")
  save_social(p_social, "fig6_global_pop_vs_rank", "square")
  invisible(p)
}

# -----------------------------------------------------------------------------

build_fig1()
build_fig2()
build_fig3()
build_fig4()
build_fig5()
build_fig6()

message("\n04_figures.R complete. Outputs in figures/ and figures/social/.")
