## data-raw/weather_nl.R
# Build the shipped `weather_nl` dataset

# ---- packages
library(readr)
library(dplyr)
library(usethis)

# ---- read raw CSV
raw <- read_csv("data-raw/weather_nl.csv", show_col_types = FALSE)

# ---- curate: keep the fields you want to ship
weather_nl <- raw |>
  transmute(
    # lowercase 'date' to match package API
    date      = as.Date(`Date.Time`),
    Year      = as.integer(Year),
    Month     = as.integer(Month),
    Day       = as.integer(Day),

    # temperatures (°C)
    tmin_c    = suppressWarnings(as.numeric(`Min.Temp...C.`)),
    tmax_c    = suppressWarnings(as.numeric(`Max.Temp...C.`)),
    tavg_c    = suppressWarnings(as.numeric(`Mean.Temp...C.`)),

    # precipitation (mm) and snow (cm)
    rain_mm   = suppressWarnings(as.numeric(`Total.Rain..mm.`)),
    precip_mm = suppressWarnings(as.numeric(`Total.Precip..mm.`)),
    snow_cm   = suppressWarnings(as.numeric(`Total.Snow..cm.`)),

    # metadata
    Station.Name = Station.Name,
    Climate.ID   = Climate.ID,

    # canonical key for internal functions
    station = Station.Name
  ) |>
  arrange(date)

# ---- basic sanity checks
stopifnot(all(weather_nl$Month %in% 1:12))
stopifnot(all(weather_nl$Day   %in% 1:31))
stopifnot(inherits(weather_nl$date, "Date"))
stopifnot("station" %in% names(weather_nl))

# ---- save curated object to the package
usethis::use_data(weather_nl, overwrite = TRUE)
