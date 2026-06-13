# Out of Reach: Quantifying Housing Affordability across Dutch Provinces (2013-2025)

Programming for Economists - group project.

**Tutorial 5, Group 8:**
Noureddine El Kaouakib (2863711), Imad el Fakiri (2863975), Achraf Saih (2865196)

Repository: https://github.com/noureddineek/Housing_affordability

## What this project does

Merges two public CBS datasets to build a **price-to-income ratio** per Dutch
province (average home price expressed in years of median household income) and
tracks how housing affordability changed from 2013 to 2024, including around the
**2022 interest-rate shock**.

## Data sources

Both datasets come from CBS Open Data (opendata.cbs.nl) and are kept unmodified
in `data/raw/`:

1. **House prices** - "Existing own homes; average purchase prices, region"
   (CBS / Kadaster). Average purchase price of existing owner-occupied homes,
   per province, 2013-2025. One file.
2. **Income** - "Income of persons; characteristics, region (indeling 2025)"
   (CBS). Median standardised household income per province. One file per year,
   2013-2024 (2024 is provisional).

All cleaning happens in code, so the pipeline is fully reproducible from the
raw files.

## How to run

Open `housing_project.Rproj` in RStudio first (this sets the working directory
to the project root so the file paths resolve). Then:

```r
install.packages(c("tidyverse", "sf", "rmarkdown"))   # once

source("run_all.R")        # does everything end to end:
                           #   R/01_clean_merge.R  -> data/panel.csv
                           #   R/02_make_map.R     -> output/affordability_map_2024.png
                           #   knit                -> housing_affordability.pdf
```

Or run the pieces individually:

```r
source("R/01_clean_merge.R")   # clean + merge the CBS data
source("R/02_make_map.R")      # download boundaries + build the choropleth
rmarkdown::render("housing_affordability.Rmd")
```

Knitting produces a PDF, so a LaTeX engine is needed. If you don't have one:

```r
install.packages("tinytex"); tinytex::install_tinytex()   # once
```

The map step needs internet the first time to download province boundaries
(CBS/PDOK via the public cartomap repository); it caches them in `data/raw/`
afterwards so the project knits offline on later runs.

## Project structure

```
housing_project/
  housing_project.Rproj         # open this in RStudio
  README.md
  run_all.R                     # reproduces everything end to end
  housing_affordability.Rmd     # the report
  R/01_clean_merge.R            # cleaning + merge -> data/panel.csv
  R/02_make_map.R               # downloads boundaries + builds the choropleth
  data/raw/                     # the unmodified CBS downloads
  data/panel.csv                # generated (git-ignored)
  output/                       # generated map + knitted pdf (git-ignored)
```

## What the cleaning does

`R/01_clean_merge.R` reshapes prices wide->long, stacks the yearly income files,
collapses any duplicate year, filters to the 12 provinces, fixes the Dutch
decimal comma, joins on province x year, and constructs the two analysis
variables (`price_income_ratio`, `ratio_index`).

`R/02_make_map.R` downloads simplified province boundaries, caches them in
`data/raw/`, joins the 2024 ratio, and renders an `sf` choropleth.
