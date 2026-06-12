# ============================================================================
# 02_make_map.R
# Builds a real choropleth of the price-to-income ratio by province (sf).
# Downloads province boundaries from the public cartomap repo (CBS/PDOK source),
# joins them to data/panel.csv, and saves output/map_2024.rds + a PNG.
#
# Run after 01_clean_merge.R:  source("R/02_make_map.R")
# ============================================================================

library(tidyverse)
library(sf)

# ---- 1. Province boundaries -------------------------------------------------
# Public, simplified CBS/PDOK boundaries (WGS84). Cached locally so we only
# download once and the project still knits offline afterwards.
geo_path <- "data/raw/provincie_2023.geojson"
geo_url  <- "https://cartomap.github.io/nl/wgs84/provincie_2023.geojson"

if (!file.exists(geo_path)) {
  download.file(geo_url, geo_path, mode = "wb")
}

provinces_sf <- st_read(geo_path, quiet = TRUE)

# The boundary file names provinces in `statnaam` (e.g. "Fryslân",
# "Noord-Holland"). Normalise to match the panel: drop the Fryslan accent.
provinces_sf <- provinces_sf %>%
  mutate(province = str_replace(statnaam, "Frysl\u00e2n", "Fryslan"))

# ---- 2. Join the affordability data ----------------------------------------
panel <- read_csv("data/panel.csv", show_col_types = FALSE)

map_year <- 2024  # latest year with both price and income

map_data <- provinces_sf %>%
  left_join(filter(panel, year == map_year), by = "province")

# Safety check: every province polygon must have found a ratio
stopifnot(all(!is.na(map_data$price_income_ratio)))

# ---- 3. Draw the choropleth -------------------------------------------------
affordability_map <- ggplot(map_data) +
  geom_sf(aes(fill = price_income_ratio), colour = "white", linewidth = 0.3) +
  scale_fill_viridis_c(option = "magma", direction = -1,
                       name = "Years of\nincome") +
  labs(
    title    = paste0("Housing affordability by province, ", map_year),
    subtitle = "Average home price expressed in years of median household income",
    caption  = "Data: CBS (house prices, income). Boundaries: CBS/PDOK via cartomap."
  ) +
  theme_void() +
  theme(legend.position = "right",
        plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(size = 9, colour = "grey30"))

# ---- 4. Save outputs --------------------------------------------------------
dir.create("output", showWarnings = FALSE)
ggsave("output/affordability_map_2024.png", affordability_map,
       width = 7, height = 7, dpi = 150)
saveRDS(affordability_map, "output/affordability_map_2024.rds")

message("Map built for ", map_year, " and saved to output/")

# leave `affordability_map` and `map_data` available for the .Rmd
