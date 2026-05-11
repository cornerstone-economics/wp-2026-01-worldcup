# WP-2026-01: build diaspora panel from UN DESA migrant stock 2024
# Iteration: 1
# Author: Rendell de Kort, Cornerstone Economics
#
# Run with: source("analysis/02b_undesa_diaspora.R")
# Reads:    data/raw/undesa_migrant_stock.xlsx (downloaded from un.org)
# Writes:   data/diaspora_global.csv (one row per origin country, all available)

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(readr)
  library(here)
})

set.seed(20260510)

xlsx_path <- here("data", "raw", "undesa_migrant_stock.xlsx")
if (!file.exists(xlsx_path)) {
  stop("undesa_migrant_stock.xlsx missing in data/raw/")
}

# Table 1 = long-format bilateral migrant stock 1990-2024
# Spreadsheet rows 1-10 are titles + multi-row headers; row 11+ is data
raw <- read_excel(xlsx_path, sheet = "Table 1",
                  skip = 10, col_names = FALSE)

# Cols 1-7 are identifiers; cols 8-15 are both-sexes year columns
# (1990, 1995, 2000, 2005, 2010, 2015, 2020, 2024). Cols 16+ are by sex.
names(raw)[1:7]  <- c("idx", "dest", "coverage", "data_type",
                      "dest_code", "origin", "origin_code")
year_cols <- paste0("y", c(1990, 1995, 2000, 2005, 2010, 2015, 2020, 2024))
names(raw)[8:15] <- year_cols

# Diaspora from origin X = total stock of X-born people living abroad.
# In Table 1 this is the row where destination == "World" (the global
# aggregate of all destinations) and origin == X.
diaspora_long <- raw |>
  filter(dest == "World") |>
  mutate(across(all_of(year_cols), as.numeric))

diaspora_global <- diaspora_long |>
  transmute(
    origin,
    origin_code = as.integer(origin_code),
    diaspora_1990 = y1990,
    diaspora_2010 = y2010,
    diaspora_2024 = y2024
  ) |>
  filter(!is.na(diaspora_2024))

write_csv(diaspora_global, here("data", "diaspora_global.csv"))

message("Wrote diaspora_global.csv (", nrow(diaspora_global),
        " origin areas)")
print(head(diaspora_global, 10))
print(tail(diaspora_global, 10))
