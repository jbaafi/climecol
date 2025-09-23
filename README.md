
<!-- README.md is generated from README.Rmd. Please edit that file -->

# climecol

<!-- badges: start -->

[![R-CMD-check](https://github.com/jbaafi/climecol/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jbaafi/climecol/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

## Overview

`climecol` provides tools for archiving, cleaning, analyzing, and
visualizing weather and climate data for ecological and
infectious-disease modeling. It ships curated daily weather data and
simple helpers for quick plotting and analysis.

## Installation

You can install the development version of `climecol` from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("jbaafi/climecol")
```

(Alternatively: `pak::pak("jbaafi/climecol")`.)

## Example

Load the package and explore the included Newfoundland dataset
(2008–2023):

``` r
library(climecol)

# Load dataset
data(weather_nl)

# Peek at structure
dplyr::glimpse(weather_nl)
#> Rows: 5,844
#> Columns: 10
#> $ Date      <date> 2008-01-01, 2008-01-02, 2008-01-03, 2008-01-04, 2008-01-05,…
#> $ Year      <int> 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, 2008, …
#> $ Month     <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, …
#> $ Day       <int> 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 1…
#> $ T_min_C   <dbl> -6.6, -8.1, -11.0, -12.6, -9.6, -10.5, -4.2, -1.2, -2.5, 0.0…
#> $ T_max_C   <dbl> 1.6, 2.0, -0.4, -5.9, -2.4, -2.5, 2.5, 3.8, 0.5, 9.5, 0.5, 7…
#> $ T_mean_C  <dbl> -2.5, -3.1, -5.7, -9.3, -6.0, -6.5, -0.9, 1.3, -1.0, 4.8, -1…
#> $ Rain_mm   <dbl> 0.2, 0.0, 0.2, 0.0, 0.0, 0.0, 0.0, 0.6, 0.8, 8.2, 0.0, 11.0,…
#> $ Precip_mm <dbl> 2.0, 4.5, 0.2, 0.0, 1.6, 2.2, 0.0, 0.6, 1.8, 8.2, 0.0, 11.0,…
#> $ Snow_cm   <dbl> 1.8, 5.0, 0.0, 0.0, 2.6, 6.4, 0.0, 0.0, 1.8, 0.0, 0.0, 0.0, …
```

Plot daily rainfall:

``` r
plot_rainfall(weather_nl)
```

<img src="man/figures/README-rainfall-plot-1.png" width="100%" />

> This figure was generated when knitting this README.

## Contributing

Issues and pull requests are welcome via the repo’s [issue
tracker](https://github.com/jbaafi/climecol/issues).

## License

MIT © Joseph Baafi
