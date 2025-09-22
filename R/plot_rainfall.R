#' Plot Daily Rainfall
#'
#' Creates a simple bar chart of daily rainfall totals using ggplot2.
#'
#' @param df A data frame with at least two columns:
#'   \describe{
#'     \item{Date}{Date of observation (Date or character convertible to Date)}
#'     \item{Rain_mm}{Daily rainfall total in millimeters (numeric)}
#'   }
#' @return A ggplot object showing rainfall over time.
#' @export
#' @examples
#' data(weather_nl)
#' plot_rainfall(weather_nl)
plot_rainfall <- function(df) {
  stopifnot(all(c("Date", "Rain_mm") %in% names(df)))

  df <- df %>%
    dplyr::mutate(Date = as.Date(Date))

  ggplot2::ggplot(df, ggplot2::aes(x = Date, y = Rain_mm)) +
    ggplot2::geom_col(fill = "steelblue") +
    ggplot2::labs(
      title = "Daily Rainfall",
      x = "Date",
      y = "Rainfall (mm)"
    ) +
    ggplot2::theme_bw()
}
