#' Read a raw weather CSV and standardize columns
#'
#' @description
#' Imports a raw weather CSV from *any* source and returns a tibble with
#' standardized column names/units that other `climecol` functions can rely on.
#' You can pass a custom `mapping` to adapt to different header names;
#' by default, we include a mapping for Environment Canada daily files.
#'
#' **Standard schema returned (columns may be NA if not supplied):**
#' - `date` (Date)
#' - `station` (chr)
#' - `climate_id` (chr)
#' - `lon`, `lat` (numeric; degrees)
#' - `tmax_c`, `tmin_c`, `tavg_c` (°C)
#' - `rain_mm` (mm), `snow_cm` (cm), `precip_mm` (mm)
#' - `snow_on_ground_cm` (cm)
#' - `wind_spd_kmh` (km/h), `wind_dir_deg` (0–360)
#'
#' @param path Path to the CSV file.
#' @param mapping Named character vector mapping **raw CSV headers** to
#'   standardized names. See [default_weather_mapping()] for an example.
#'   Names = raw column headers (any case/punctuation), values = one of the
#'   standard names listed above.
#' @param station Optional character to override/set the `station` column.
#' @param tz Timezone used when parsing datetimes (if needed). Default "UTC".
#' @param na Character vector of strings to treat as missing.
#'
#' @return A tibble with the standard schema (columns present; some may be all NA).
#' @export
#' @examples
#' \dontrun{
#' df <- read_weather_csv("data-raw/ec_daily_2013_2023.csv")
#' head(df)
#' }
read_weather_csv <- function(path,
                             mapping = default_weather_mapping(),
                             station = NULL,
                             tz = "UTC",
                             na = c("NA", "", "M", "-9999", "-9999.9")) {
  stopifnot(file.exists(path))

  raw <- readr::read_csv(path, na = na, show_col_types = FALSE, guess_max = 100000)

  # Normalize names for robust matching (lowercase, remove non-alphanum)
  norm <- function(x) gsub("[^a-z0-9]+", "", tolower(x))
  raw_names_norm <- norm(names(raw))
  names(raw) <- names(raw) # keep original for clarity

  # Normalize mapping keys too
  map <- mapping
  names(map) <- norm(names(map))

  # Helper to pull a column by standardized target name
  pull_mapped <- function(target_std) {
    src_norm <- names(map)[map == target_std]
    src_norm <- src_norm[src_norm %in% raw_names_norm]
    if (length(src_norm) == 0) return(NULL)
    # take first match
    raw[[ which(raw_names_norm == src_norm[1])[1] ]]
  }

  # --- Build standardized tibble ---
  out <- tibble::tibble(
    date = NA_real_, station = NA_character_, climate_id = NA_character_,
    lon = NA_real_, lat = NA_real_,
    tmax_c = NA_real_, tmin_c = NA_real_, tavg_c = NA_real_,
    rain_mm = NA_real_, snow_cm = NA_real_, precip_mm = NA_real_,
    snow_on_ground_cm = NA_real_,
    wind_spd_kmh = NA_real_, wind_dir_deg = NA_real_
  )[0, ]

  n <- nrow(raw)
  if (n == 0) return(out)

  # DATE: try Date, then various datetime parsers
  date_raw <- pull_mapped("date")
  date_vec <- rep(NA_real_, n)
  if (!is.null(date_raw)) {
    # Try as.Date directly
    d <- suppressWarnings(as.Date(date_raw))
    if (all(is.na(d))) {
      # Try common formats
      d <- suppressWarnings(lubridate::ymd(date_raw, quiet = TRUE))
      if (all(is.na(d))) d <- suppressWarnings(lubridate::mdy(date_raw, quiet = TRUE))
      if (all(is.na(d))) d <- suppressWarnings(lubridate::dmy(date_raw, quiet = TRUE))
      # Try datetime
      if (all(is.na(d))) d <- suppressWarnings(as.Date(lubridate::ymd_hms(date_raw, tz = tz, quiet = TRUE)))
      if (all(is.na(d))) d <- suppressWarnings(as.Date(lubridate::mdy_hms(date_raw, tz = tz, quiet = TRUE)))
      if (all(is.na(d))) d <- suppressWarnings(as.Date(lubridate::dmy_hms(date_raw, tz = tz, quiet = TRUE)))
    }
    date_vec <- d
  }

  # Character columns
  station_vec    <- if (!is.null(station)) rep(as.character(station), n) else {
    x <- pull_mapped("station"); if (is.null(x)) rep(NA_character_, n) else as.character(x)
  }
  climate_id_vec <- { x <- pull_mapped("climate_id"); if (is.null(x)) rep(NA_character_, n) else as.character(x) }

  # Numeric helpers
  as_num <- function(x) { if (is.null(x)) rep(NA_real_, n) else suppressWarnings(as.numeric(x)) }

  # Coordinates
  lon_vec <- as_num(pull_mapped("lon"))
  lat_vec <- as_num(pull_mapped("lat"))

  # Temps (°C)
  tmax_vec <- as_num(pull_mapped("tmax_c"))
  tmin_vec <- as_num(pull_mapped("tmin_c"))
  tavg_vec <- as_num(pull_mapped("tavg_c"))

  # Precip
  rain_mm_vec   <- as_num(pull_mapped("rain_mm"))
  snow_cm_vec   <- as_num(pull_mapped("snow_cm"))
  precip_mm_vec <- as_num(pull_mapped("precip_mm"))
  sog_cm_vec    <- as_num(pull_mapped("snow_on_ground_cm"))

  # Wind
  wind_spd_vec <- as_num(pull_mapped("wind_spd_kmh"))
  wind_dir_vec <- as_num(pull_mapped("wind_dir_deg"))
  # Some sources give wind direction in tens of degrees; map provides either 'wind_dir_deg' or 'wind_dir_deg10'
  wind_dir10_vec <- as_num(pull_mapped("wind_dir_deg10"))
  if (!all(is.na(wind_dir10_vec)) && all(is.na(wind_dir_vec))) {
    wind_dir_vec <- wind_dir10_vec * 10
  }

  # Derive mean temp if missing but min/max exist
  if (all(is.na(tavg_vec)) && (any(!is.na(tmax_vec)) || any(!is.na(tmin_vec)))) {
    tavg_vec <- rowMeans(cbind(tmax_vec, tmin_vec), na.rm = TRUE)
    tavg_vec[!is.finite(tavg_vec)] <- NA_real_
  }

  std <- tibble::tibble(
    date = as.Date(date_vec),
    station = station_vec,
    climate_id = climate_id_vec,
    lon = lon_vec, lat = lat_vec,
    tmax_c = tmax_vec, tmin_c = tmin_vec, tavg_c = tavg_vec,
    rain_mm = rain_mm_vec, snow_cm = snow_cm_vec, precip_mm = precip_mm_vec,
    snow_on_ground_cm = sog_cm_vec,
    wind_spd_kmh = wind_spd_vec, wind_dir_deg = wind_dir_vec
  )

  dplyr::arrange(std, .data$date)
}

#' Default column mapping for raw weather CSVs
#'
#' @description
#' A starter mapping (names = raw headers; values = standardized names) based on
#' Environment Canada daily CSVs. Edit or extend this to match your data source.
#'
#' Standard target names you can map to:
#' `date`, `station`, `climate_id`, `lon`, `lat`,
#' `tmax_c`, `tmin_c`, `tavg_c`,
#' `rain_mm`, `snow_cm`, `precip_mm`, `snow_on_ground_cm`,
#' `wind_spd_kmh`, `wind_dir_deg`, `wind_dir_deg10`.
#'
#' @return A named character vector for use in `read_weather_csv(mapping = ...)`.
#' @export
#' @examples
#' default_weather_mapping()
default_weather_mapping <- function() {
  c(
    # timing / id
    "Date.Time"               = "date",
    "Station.Name"            = "station",
    "Climate.ID"              = "climate_id",
    # location
    "Longitude..x."           = "lon",
    "Latitude..y."            = "lat",
    # temperature (°C)
    "Max.Temp...C."           = "tmax_c",
    "Min.Temp...C."           = "tmin_c",
    "Mean.Temp...C."          = "tavg_c",
    # precipitation
    "Total.Rain..mm."         = "rain_mm",
    "Total.Snow..cm."         = "snow_cm",
    "Total.Precip..mm."       = "precip_mm",
    "Snow.on.Grnd..cm."       = "snow_on_ground_cm",
    # wind
    "Spd.of.Max.Gust..km.h."  = "wind_spd_kmh",
    "Dir.of.Max.Gust..10s.deg." = "wind_dir_deg10"
  )
}
