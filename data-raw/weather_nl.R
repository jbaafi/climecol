## code to prepare `weather_nl` dataset goes here

# data-raw/weather_nl.R

# ---- packages ----
library(readr)
library(dplyr)

# ---- read raw csv ----
weather_nl <- read_csv("data-raw/weather_nl.csv", show_col_types = FALSE)

# ---- clean / standardize ----
weather_nl <- weather_nl %>%
  rename(
    Date    = Date.Time,
    Rain_mm = Total.Rain..mm.
  ) %>%
  mutate(
    Date    = as.Date(Date),
    Year    = as.integer(Year),
    Month   = as.integer(Month),
    Day     = as.integer(Day),
    Rain_mm = as.numeric(Rain_mm)
  ) %>%
  arrange(Date)

# ---- save to package ----
usethis::use_data(weather_nl, overwrite = TRUE)

