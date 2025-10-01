#' Normalize weather data column names
#'
#' Ensures standardized column naming (lowercase + expected keys) for use with
#' climecol functions such as `validate_weather()`, `complete_daily_calendar()`,
#' `summarise_gaps()`, and `impute_weather()`.
#'
#' @param df A data frame or tibble of daily weather data.
#' @param station_preference One of `"auto"` (default), `"Station.Name"`,
#'   or `"Climate.ID"`. Controls which column becomes the canonical `station`.
#'
#' @return A tibble with standardized columns where present:
#'   `date`, `tmin_c`, `tmax_c`, `tavg_c`, `rain_mm`, `precip_mm`, `snow_cm`,
#'   and a `station` key (created if a reasonable source exists).
#' @export
normalize_weather_names <- function(df, station_preference = "auto") {
  stopifnot(is.data.frame(df))
  df <- dplyr::as_tibble(df)

  # Map standardized names to regexes matching common variants (case/format)
  rename_map <- c(
    "date"      = "^(date|Date|DATE|Date.Time)$",
    "tmin_c"    = "^(tmin_c|T_min_C|Min.Temp...C.)$",
    "tmax_c"    = "^(tmax_c|T_max_C|Max.Temp...C.)$",
    "tavg_c"    = "^(tavg_c|T_mean_C|Mean.Temp...C.)$",
    "rain_mm"   = "^(rain_mm|Rain_mm|Rain.MM|Total.Rain..mm.)$",
    "precip_mm" = "^(precip_mm|Precip_mm|Precip.MM|Total.Precip..mm.)$",
    "snow_cm"   = "^(snow_cm|Snow_cm|Snow.CM|Total.Snow..cm.)$"
  )

  # Rename first matching column for each standardized name
  for (std in names(rename_map)) {
    hits <- grep(rename_map[[std]], names(df), value = TRUE)
    if (length(hits) >= 1 && !(std %in% names(df))) {
      # base rename avoids rlang::`:=` NOTE
      idx <- match(hits[1], names(df))
      names(df)[idx] <- std
    }
  }

  # Ensure `date` is Date if present
  if ("date" %in% names(df) && !inherits(df$date, "Date")) {
    df$date <- as.Date(df$date)
  }

  # Create canonical `station` if missing
  if (!"station" %in% names(df)) {
    n <- nrow(df)
    if (station_preference == "Station.Name" && "Station.Name" %in% names(df)) {
      df$station <- df[["Station.Name"]]
    } else if (station_preference == "Climate.ID" && "Climate.ID" %in% names(df)) {
      df$station <- df[["Climate.ID"]]
    } else {
      # auto preference: Station.Name if available, else Climate.ID, else "unknown_station"
      if ("Station.Name" %in% names(df)) {
        df$station <- df[["Station.Name"]]
      } else if ("Climate.ID" %in% names(df)) {
        df$station <- df[["Climate.ID"]]
      } else {
        df$station <- rep("unknown_station", length.out = n)
      }
    }
  }

  df
}
