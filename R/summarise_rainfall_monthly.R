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
  stopifnot(all(c("Date", "Rain_mm") %in% names(df)))
  df <- dplyr::mutate(df, Date = as.Date(.data$Date),
                      MonthDate = lubridate::floor_date(.data$Date, "month"))
  rng <- range(df$MonthDate, na.rm = TRUE)

  out <- df |>
    dplyr::group_by(.data$MonthDate) |>
    dplyr::summarise(Rain_mm = sum(.data$Rain_mm, na.rm = TRUE), .groups = "drop") |>
    tidyr::complete(MonthDate = seq(rng[1], rng[2], by = "month")) |>
    dplyr::mutate(Year = as.integer(format(.data$MonthDate, "%Y")),
                  Month = as.integer(format(.data$MonthDate, "%m"))) |>
    dplyr::select(.data$Year, .data$Month, .data$Rain_mm)

  out
}
