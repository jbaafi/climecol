#' Newfoundland (St. John's A. area) daily weather data
#'
#' A curated daily weather dataset for a Newfoundland station, suitable for
#' examples and vignettes. Columns are standardized to match the package's
#' helper functions (e.g., `validate_weather()`, `complete_daily_calendar()`).
#'
#' @format A tibble with the following columns:
#' \describe{
#'   \item{date}{Date of observation (`Date`).}
#'   \item{tmin_c}{Minimum temperature in °C (numeric).}
#'   \item{tmax_c}{Maximum temperature in °C (numeric).}
#'   \item{tavg_c}{Mean temperature in °C (numeric).}
#'   \item{rain_mm}{Total rainfall in millimetres (numeric).}
#'   \item{precip_mm}{Total precipitation in millimetres (numeric).}
#'   \item{snow_cm}{Total snowfall in centimetres (numeric).}
#'
#'   \item{Year}{Calendar year (integer).}
#'   \item{Month}{Calendar month (1–12, integer).}
#'   \item{Day}{Calendar day of month (integer).}
#'
#'   \item{Station.Name}{Station name as provided by the source (character).}
#'   \item{Climate.ID}{Environment Canada climate station ID (character).}
#'   \item{station}{Canonical station key used by climecol functions
#'                  (character). Typically set equal to `Station.Name` or
#'                  `Climate.ID`.}
#' }
#'
#' @details
#' This dataset follows the standardized column names expected by package
#' utilities. In particular, downstream helpers assume `date` (lowercase) and
#' `station` exist.
#'
#' @examples
#' data(weather_nl)
#' # Quick QA summary
#' qa <- validate_weather(weather_nl)
#' qa$summary
#'
#' # Make gaps explicit and summarise coverage
#' cal <- complete_daily_calendar(weather_nl)
#' summarise_gaps(cal, by = "station")
#'
#' @source Environment and Climate Change Canada (ECCC) daily climate data.
"weather_nl"
