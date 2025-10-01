#' Summarise Rainfall by Month
#'
#' Returns monthly total rainfall from daily data, ensuring all months are present.
#'
#' @param df Data frame with columns `Date` and `Rain_mm`.
#' @return A tibble with columns `Year`, `Month`, `Rain_mm`.
#' @export
#' @importFrom lubridate floor_date
#' @importFrom tidyr complete
#' @importFrom rlang .data
#' @examples
#' data(weather_nl)
#' summarise_rainfall_monthly(weather_nl)
summarise_rainfall_monthly <- function(df) {
  # Allow legacy (Date/Rain_mm) or standardized (date/rain_mm) inputs
  df <- normalize_weather_names(df)

  # Require standardized columns for downstream steps
  stopifnot(all(c("date", "rain_mm") %in% names(df)))

  df <- dplyr::mutate(
    df,
    date = as.Date(.data$date),
    MonthDate = lubridate::floor_date(.data$date, "month")
  )
  rng <- range(df$MonthDate, na.rm = TRUE)

  out <- df |>
    dplyr::group_by(.data$MonthDate) |>
    dplyr::summarise(Rain_mm = sum(.data$rain_mm, na.rm = TRUE), .groups = "drop") |>
    tidyr::complete(MonthDate = seq(rng[1], rng[2], by = "month")) |>
    dplyr::mutate(
      Year  = as.integer(format(.data$MonthDate, "%Y")),
      Month = as.integer(format(.data$MonthDate, "%m"))
    ) |>
    dplyr::select(.data$Year, .data$Month, .data$Rain_mm)

  tibble::as_tibble(out)
}
