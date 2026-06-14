# ============================================================================
# run_all.R - reproduce the entire project from scratch.
#
# Usage:  source("run_all.R")  from the project root (open the .Rproj first).
#
# Steps:
#   1a. (optional) restore exact package versions with renv
#   1b. install TinyTeX if no LateX engine is present (needed for the PDF output) 
#   2. clean + merge the raw CBS data        -> data/panel.csv
#   3. build the choropleth map               -> output/affordability_map_2024.png
#   4. knit the full report                    -> housing_affordability.pdf
# ============================================================================

# 1a. Restore pinned package versions if renv is set up (safe to skip if not).
if (file.exists("renv.lock") && requireNamespace("renv", quietly = TRUE)) {
  renv::restore(prompt = FALSE)
}

# 1b. Make sure a LaTeX engine exists, since the report knits to a PDF.
# Installs the lightweight TinyTeX distribution only if none is found.
if (!requireNamespace("tinytex", quietly = TRUE)) {
  install.packages("tinytex")
}
if (!tinytex::is_tinytex() && !nzchar(Sys.which("pdflatex"))) {
  message("No LaTeX found - installing TinyTeX (this can take a few minutes)...")
  tinytex::install_tinytex()
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
