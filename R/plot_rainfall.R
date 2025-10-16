#' Plot Daily Rainfall (smart axis, optional yearly facets)
#'
#' Creates a clean ggplot2 line plot of daily rainfall totals with automatic
#' x-axis scaling (months for ≤ 1 year, years for multi-year data) and optional
#' faceting by year.
#'
#' @param df A tibble/data frame with at least `date` (Date) and `rain_mm` (numeric).
#' @param title Plot title. Default: "Daily Rainfall".
#' @param color Line color. Default: ggplot2 blue ("#0072B2").
#' @param linewidth Line width for `geom_line()`. Default: 0.5.
#' @param facet_by_year Logical; if TRUE, facet into one panel per calendar year.
#' @return A ggplot object.
#' @examples
#' data(weather_nl)
#' # Auto x-axis scaling
#' plot_rainfall(weather_nl)
#'
#' # Faceted version
#' plot_rainfall(weather_nl, facet_by_year = TRUE)
#'
#' # Custom color and title (ASCII dash)
#' plot_rainfall(weather_nl, title = "Rainfall in St John's (2008-2023)",
#'               color = "#56B4E9", linewidth = 0.8)
#' @export
#' @importFrom rlang .data
plot_rainfall <- function(df,
                          title = "Daily Rainfall",
                          color = "#0072B2",
                          linewidth = 0.5,
                          facet_by_year = FALSE) {
  stopifnot(all(c("date", "rain_mm") %in% names(df)))

  # local copy; add year for optional faceting
  df <- dplyr::as_tibble(df)
  df$year <- lubridate::year(df$date)

  # compute time span
  start_date <- min(df$date, na.rm = TRUE)
  end_date   <- max(df$date, na.rm = TRUE)
  span_years <- as.numeric(difftime(end_date, start_date, units = "days")) / 365.25

  # smart axis scale
  x_scale <- if (span_years <= 1.2) {
    ggplot2::scale_x_date(date_breaks = "1 month", date_labels = "%b", expand = c(0.01, 0))
  } else {
    ggplot2::scale_x_date(date_breaks = "1 year",  date_labels = "%Y", expand = c(0.01, 0))
  }

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$date, y = .data$rain_mm)) +
    ggplot2::geom_line(color = color, linewidth = linewidth) +
    x_scale +
    ggplot2::labs(title = title, x = "Date", y = "Rainfall (mm)") +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      plot.title   = ggplot2::element_text(hjust = 0.5, face = "bold"),
      axis.text.x  = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid.minor = ggplot2::element_blank()
    )

  if (isTRUE(facet_by_year)) {
    p <- p +
      ggplot2::facet_wrap(~year, ncol = 4, scales = "free_x") +
      ggplot2::labs(title = paste0(title, " by Year"))
  }

  p
}
