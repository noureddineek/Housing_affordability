# ============================================================================
# 01_clean_merge.R
# Out of Reach: Quantifying Housing Affordability across Dutch Provinces
# ----------------------------------------------------------------------------
# Reads the raw CBS files (house prices + 13 yearly income files), cleans them,
# merges into one tidy province x year panel, and writes data/panel.csv.
#
# Run from the project root:  source("R/01_clean_merge.R")
# ============================================================================

library(tidyverse)

# ---- 0. Paths --------------------------------------------------------------
# All raw files live in data/raw/ . Copy the CBS downloads there unchanged.
raw_dir   <- "data/raw"
price_file <- file.path(raw_dir,
  "Existing_own_homes__average_purchase_prices__region_04062026_182405.csv")

# The 12 provinces we keep (CBS marks them with the "(PV)" suffix).
keep_provinces <- c(
  "Groningen", "Fryslan", "Drenthe", "Overijssel", "Flevoland",
  "Gelderland", "Utrecht", "Noord-Holland", "Zuid-Holland",
  "Zeeland", "Noord-Brabant", "Limburg"
)

# Helper: strip the " (PV)" suffix and normalise the Fryslan spelling
clean_prov <- function(x) {
  x <- str_remove(x, "\\s*\\(PV\\)\\s*$")
  x <- str_trim(x)
  x <- str_replace(x, "Frysl\u00e2n", "Fryslan")   # remove the accent for joining
  x
}

# ----------------------------------------------------------------------------
# 1. House prices  (wide -> long)
# ----------------------------------------------------------------------------
# The CBS price file has 5 metadata/header lines before the data and uses ";"
# as separator. We read it raw, locate the data block, then reshape to long.

price_raw <- read_delim(
  price_file, delim = ";", skip = 5, col_names = FALSE,
  locale = locale(encoding = "UTF-8"),
  show_col_types = FALSE
)

# Column 1 = region; columns 2..14 = years 2013..2025
price_years <- as.character(2013:2025)

prices <- price_raw %>%
  rename(region = X1) %>%
  filter(str_detect(region, "\\(PV\\)$")) %>%        # keep provinces only
  set_names(c("region", price_years)) %>%
  mutate(province = clean_prov(region), .keep = "unused") %>%
  pivot_longer(all_of(price_years),
               names_to = "year", values_to = "avg_price") %>%
  mutate(
    year      = as.integer(year),
    avg_price = as.numeric(avg_price)                 # already plain euros
  ) %>%
  filter(province %in% keep_provinces) %>%
  select(province, year, avg_price)

# ----------------------------------------------------------------------------
# 2. Income  (13 yearly files -> one stacked long table)
# ----------------------------------------------------------------------------
# Each income file is ONE year. The year is stored on line 4 ("Perioden: 2013").
# We read every Inkomen*.csv, pull the year from line 4, grab the
# "Mediaan gestandaardiseerd inkomen" column, and stack the results.
#
# NOTE: two of the supplied files are byte-identical 2018 duplicates; because we
# key on province + year and then distinct(), the duplicate collapses safely.

income_files <- list.files(raw_dir, pattern = "^Inkomen.*\\.csv$",
                           full.names = TRUE)

read_income_year <- function(path) {
  lines <- read_lines(path, locale = locale(encoding = "UTF-8"))

  # year sits on the "Perioden:" line, possibly flagged provisional with "*"
  yr <- lines %>%
    str_subset("Perioden") %>%
    str_extract("\\d{4}") %>%
    as.integer()

  # data starts after the 7 metadata/header lines; ";" separated.
  # Read EVERY column as character (col_types = .default "c") so the Dutch
  # decimal comma in "23,9" survives - otherwise read_delim guesses "numeric"
  # and turns "23,9" into 239 by treating the comma as a thousands separator.
  df <- read_delim(path, delim = ";", skip = 7, col_names = FALSE,
                   locale = locale(encoding = "UTF-8"),
                   col_types = cols(.default = "c"))

  # Column order in these files:
  # X1 region | X2 Personen | X3 Personen met ink | X4 Aandeel |
  # X5 Gem.gestand | X6 MEDIAAN gestand | X7 Gem.persoonlijk | X8 Mediaan persoonlijk
  df %>%
    rename(region = X1, med_std_income_k = X6) %>%
    filter(str_detect(region, "\\(PV\\)$")) %>%
    transmute(
      province = clean_prov(region),
      year     = yr,
      # Values use a Dutch decimal comma and are in THOUSANDS of euros.
      # Swap the comma for a decimal point, convert to a number, x1000 -> euros.
      med_income = as.numeric(str_replace(med_std_income_k, ",", ".")) * 1000
    )
}

income <- map_dfr(income_files, read_income_year) %>%
  filter(province %in% keep_provinces) %>%
  distinct(province, year, .keep_all = TRUE)   # collapse the duplicate 2018

# ----------------------------------------------------------------------------
# 3. Merge  (price x income on province + year)
# ----------------------------------------------------------------------------
# Prices cover 2013-2025; income covers 2013-2024 (2024 provisional, no 2025).
# An inner join keeps the years where BOTH exist -> the ratio panel (2013-2024).
panel <- prices %>%
  inner_join(income, by = c("province", "year")) %>%
  arrange(province, year)

# ----------------------------------------------------------------------------
# 4. New variables (rubric: >= 2 constructed variables with analytical value)
# ----------------------------------------------------------------------------
panel <- panel %>%
  group_by(province) %>%
  mutate(
    # (1) headline affordability: avg price expressed in YEARS of median income
    price_income_ratio = avg_price / med_income,
    # (2) affordability index relative to that province's 2013 level (=100),
    #     so we can compare CHANGE in affordability across provinces fairly
    ratio_index = 100 * price_income_ratio /
                  price_income_ratio[year == 2013]
  ) %>%
  ungroup()

# ----------------------------------------------------------------------------
# 5. Quick sanity checks + write output
# ----------------------------------------------------------------------------
stopifnot(
  n_distinct(panel$province) == 12,          # all 12 provinces present
  all(!is.na(panel$price_income_ratio))       # no missing ratios
)

dir.create("data", showWarnings = FALSE)
write_csv(panel, "data/panel.csv")

message("panel.csv written: ",
        n_distinct(panel$province), " provinces x ",
        n_distinct(panel$year), " years (",
        min(panel$year), "-", max(panel$year), ")")

# Leave `panel`, `prices`, `income` in the environment for the .Rmd to reuse.
