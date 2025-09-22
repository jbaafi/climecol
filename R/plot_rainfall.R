#' Plot Daily Rainfall
#'
#' Creates a simple bar chart of daily rainfall totals using ggplot2.
#'
#' @param df A data frame with columns:
#'   \describe{
#'     \item{Date}{Date of observation (Date or character convertible to Date)}
#'     \item{Rain_mm}{Daily rainfall total in millimeters (numeric)}
#'   }
#' @return A ggplot object showing rainfall over time.
#' @export
#' @importFrom dplyr mutate
#' @importFrom ggplot2 ggplot aes geom_col labs theme_minimal
#' @importFrom rlang .data
#' @examples
#' data(weather_nl)
#' plot_rainfall(weather_nl)
plot_rainfall <- function(df) {
  stopifnot(all(c("Date", "Rain_mm") %in% names(df)))

  df <- dplyr::mutate(df, Date = as.Date(.data$Date))

  ggplot2::ggplot(df, ggplot2::aes(x = .data$Date, y = .data$Rain_mm)) +
    ggplot2::geom_col() +
    ggplot2::labs(
      title = "Daily Rainfall",
      x = "Date",
      y = "Rainfall (mm)"
    ) +
    ggplot2::theme_minimal()
}
