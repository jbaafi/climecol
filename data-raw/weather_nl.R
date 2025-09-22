## code to prepare `weather_nl` dataset goes here

# data-raw/weather_nl.R

# ---- packages (only for this script) ----
library(readr)
library(dplyr)

# ---- read raw CSV (keep the raw file intact) ----
raw <- read_csv("data-raw/weather_nl.csv", show_col_types = FALSE)

# ---- curate: keep the fields you want to ship ----
# NOTE: ECCC column names have dots; use backticks exactly as below.
weather_nl <- raw |>
  transmute(
    Date      = as.Date(`Date.Time`),
    Year      = as.integer(Year),
    Month     = as.integer(Month),
    Day       = as.integer(Day),

    # temperatures (°C)
    T_min_C   = suppressWarnings(as.numeric(`Min.Temp...C.`)),
    T_max_C   = suppressWarnings(as.numeric(`Max.Temp...C.`)),
    T_mean_C  = suppressWarnings(as.numeric(`Mean.Temp...C.`)),

    # precipitation (mm) and snow (cm)
    Rain_mm   = suppressWarnings(as.numeric(`Total.Rain..mm.`)),
    Precip_mm = suppressWarnings(as.numeric(`Total.Precip..mm.`)),
    Snow_cm   = suppressWarnings(as.numeric(`Total.Snow..cm.`))
  ) |>
  arrange(Date)

# ---- basic sanity checks (optional but helpful) ----
stopifnot(all(weather_nl$Month %in% 1:12))
stopifnot(all(weather_nl$Day   %in% 1:31))
stopifnot(inherits(weather_nl$Date, "Date"))

# ---- save curated object to the package ----
usethis::use_data(weather_nl, overwrite = TRUE)

