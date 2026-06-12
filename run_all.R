# ============================================================================
# run_all.R - reproduce the entire project from scratch.
#
# Usage:  source("run_all.R")  from the project root (open the .Rproj first).
#
# Steps:
#   1. (optional) restore exact package versions with renv
#   2. clean + merge the raw CBS data        -> data/panel.csv
#   3. build the choropleth map               -> output/affordability_map_2024.png
#   4. knit the full report                    -> housing_affordability.pdf
# ============================================================================

# 1. Restore pinned package versions if renv is set up (safe to skip if not).
if (file.exists("renv.lock") && requireNamespace("renv", quietly = TRUE)) {
  renv::restore(prompt = FALSE)
}

# 2. Clean + merge.
source("R/01_clean_merge.R")

# 3. Build the map (needs internet the first time to fetch boundaries).
source("R/02_make_map.R")

# 4. Knit the report to PDF.
if (requireNamespace("rmarkdown", quietly = TRUE)) {
  rmarkdown::render("housing_affordability.Rmd")
}

message("\nDone. See housing_affordability.pdf and output/affordability_map_2024.png")
