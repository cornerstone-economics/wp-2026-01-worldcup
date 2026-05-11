# WP-2026-01: parse the FIFA-paste text file into a global ranking panel
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/01b_fifa_global.R")
# Reads:    data/raw/fifa_paste.txt (cleaned manual paste of FIFA's site)
# Writes:   data/fifa_global.csv

# -----------------------------------------------------------------------------
# Each FIFA-page entry was reduced to a fixed 3-line block:
#   <rank>            (line 1, integer)
#   [<movement>]      (optional line, integer)
#   <country name>    (line, string)
#   [<delta>]         (optional line, "+1.23" or "-1.23")
#   <points>          (line, decimal NNNN.NN)
#
# Walk linearly: a "points" line marks the end of an entry. Walk backward from
# each points line to find the country name (line that's neither integer nor
# signed-decimal nor empty).
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(stringr)
  library(here)
})

raw <- readLines(here("data", "raw", "fifa_paste.txt"))
raw <- str_trim(raw)
raw <- raw[raw != ""]

is_points    <- function(x) str_detect(x, "^[0-9]{3,4}\\.[0-9]{2}$")
is_signed    <- function(x) str_detect(x, "^[+-][0-9]+\\.[0-9]+$")
is_int       <- function(x) str_detect(x, "^[0-9]+$")

points_idx <- which(is_points(raw))

records <- lapply(points_idx, function(i) {
  # Walk backward to find the country, rank
  j <- i - 1
  if (is_signed(raw[j])) j <- j - 1
  country <- raw[j]
  k <- j - 1
  rank_line <- NA_integer_
  while (k >= 1 && is_int(raw[k])) {
    rank_line <- as.integer(raw[k])
    k <- k - 1
  }
  tibble(rank = rank_line, country = country,
         points = as.numeric(raw[i]))
})

fifa_global <- bind_rows(records) |>
  filter(!is.na(rank)) |>
  arrange(rank)

# Sanity check: ranks should be 1..N with no gaps
gaps <- setdiff(seq_len(max(fifa_global$rank)), fifa_global$rank)
if (length(gaps) > 0) {
  warning("Missing ranks: ", paste(head(gaps, 20), collapse = ","))
}
dups <- fifa_global |> count(rank) |> filter(n > 1)
if (nrow(dups) > 0) {
  warning("Duplicate ranks: ", paste(head(dups$rank, 20), collapse = ","))
}

write_csv(fifa_global, here("data", "fifa_global.csv"))
message("Wrote fifa_global.csv (", nrow(fifa_global), " countries, ranks ",
        min(fifa_global$rank), "-", max(fifa_global$rank), ")")
print(head(fifa_global, 5))
print(tail(fifa_global, 5))
