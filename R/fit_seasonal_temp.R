#' Fit seasonal temperature curve
#'
#' Fits sinusoidal/periodic models to the mean daily temperature cycle (averaged across years).
#' Returns fitted objects, AIC and R^2 metrics, and an optional plot overlay.
#'
#' @param df A data frame with column `date` and either `tavg_c` or both `tmin_c` and `tmax_c`.
#' @param funcs Character vector of models to fit. Options are:
#'   - "sin1": \eqn{a + b_1 \sin(2\pi t / 365) + b_2 \cos(2\pi t / 365)}
#'   - "sin2": \eqn{T_0 \left(1 + T_1 \cos(2\pi(\omega t + \theta)/365)\right)}
#' @param plot Logical; if TRUE, include a ggplot overlay of observed vs. fitted curves.
#'
#' @return A list with:
#' \describe{
#'   \item{daily_avg}{tibble of day-of-year (`day_of_year`), observed `mean_temp`, and fitted columns.}
#'   \item{fits}{list of `nls` fit objects for each model.}
#'   \item{metrics}{tibble with `model`, `AIC`, and `R2` per fit.}
#'   \item{plot}{ggplot object (present when `plot = TRUE`).}
#' }
#'
#' @details
#' The function aggregates input to daily means by day-of-year across all years,
#' then fits each requested model with `nls`. R^2 is computed as 1 - SS_res/SS_tot
#' on the aggregated series.
#'
#' @examples
#' data(weather_nl)
#' res <- fit_seasonal_temp(weather_nl, funcs = c("sin1","sin2"), plot = TRUE)
#' res$metrics
#' if (!is.null(res$plot)) print(res$plot)
#'
#' @export
#' @importFrom stats nls AIC
fit_seasonal_temp <- function(df, funcs = c("sin1","sin2"), plot = FALSE) {
  stopifnot("date" %in% names(df))

  # Choose temperature series
  if ("tavg_c" %in% names(df)) {
    temp <- df$tavg_c
  } else if (all(c("tmin_c","tmax_c") %in% names(df))) {
    temp <- rowMeans(df[, c("tmin_c","tmax_c")], na.rm = TRUE)
  } else {
    stop("`df` must contain `tavg_c` or both `tmin_c` and `tmax_c`.")
  }

  # Aggregate to mean per day-of-year
  dat <- df |>
    dplyr::mutate(
      day_of_year = as.numeric(format(.data$date, "%j")),
      tavg = temp
    ) |>
    dplyr::group_by(.data$day_of_year) |>
    dplyr::summarise(mean_temp = mean(.data$tavg, na.rm = TRUE), .groups = "drop")

  # Candidate functions
  temp.func1 <- function(t, a, b1, b2) a + b1 * sin(2 * pi * t / 365) + b2 * cos(2 * pi * t / 365)
  temp.func2 <- function(t, T0, T1, omega, theta) T0 * (1 + T1 * cos(2 * pi * (omega * t + theta) / 365))

  calc_r2 <- function(y, yhat) {
    ss_res <- sum((y - yhat)^2, na.rm = TRUE)
    ss_tot <- sum((y - mean(y, na.rm = TRUE))^2, na.rm = TRUE)
    1 - ss_res / ss_tot
  }

  fits <- list()
  metrics <- list()

  # sin1
  if ("sin1" %in% funcs) {
    fit <- try(
      nls(mean_temp ~ temp.func1(day_of_year, a, b1, b2),
          data = dat,
          start = list(
            a  = mean(dat$mean_temp),
            b1 = stats::sd(dat$mean_temp) * 0.5,
            b2 = stats::sd(dat$mean_temp) * 0.5
          )),
      silent = TRUE
    )
    if (inherits(fit, "try-error")) {
      warning("sin1 model failed to converge; skipping.")
    } else {
      fits$sin1 <- fit
      dat$fitted_sin1 <- stats::predict(fit)
      metrics$sin1 <- list(AIC = stats::AIC(fit),
                           R2  = calc_r2(dat$mean_temp, dat$fitted_sin1))
    }
  }

  # sin2
  if ("sin2" %in% funcs) {
    fit <- try(
      nls(mean_temp ~ temp.func2(day_of_year, T0, T1, omega, theta),
          data = dat,
          start = list(
            T0    = mean(dat$mean_temp),
            T1    = 0.5,
            omega = 1,
            theta = 1
          )),
      silent = TRUE
    )
    if (inherits(fit, "try-error")) {
      warning("sin2 model failed to converge; skipping.")
    } else {
      fits$sin2 <- fit
      dat$fitted_sin2 <- stats::predict(fit)
      metrics$sin2 <- list(AIC = stats::AIC(fit),
                           R2  = calc_r2(dat$mean_temp, dat$fitted_sin2))
    }
  }

  out <- list(
    daily_avg = dat,
    fits      = fits,
    metrics   = {
      if (length(metrics)) {
        tibble::tibble(
          model = names(metrics),
          AIC   = vapply(metrics, function(m) m$AIC, numeric(1)),
          R2    = vapply(metrics, function(m) m$R2,  numeric(1))
        )
      } else {
        tibble::tibble(model = character(), AIC = numeric(), R2 = numeric())
      }
    }
  )

  if (plot) {
    p <- ggplot2::ggplot(dat, ggplot2::aes(x = day_of_year)) +
      ggplot2::geom_line(ggplot2::aes(y = mean_temp), linewidth = 0.8) +
      { if ("fitted_sin1" %in% names(dat))
        ggplot2::geom_line(ggplot2::aes(y = fitted_sin1), linetype = "dashed", col = "darkred", linewidth = 1)} +
      { if ("fitted_sin2" %in% names(dat))
        ggplot2::geom_line(ggplot2::aes(y = fitted_sin2), linetype = "dotted", col = "blue", linewidth = 1) } +
      ggplot2::labs(title = "Seasonal temperature fit",
                    x = "Day of year", y = "Mean temperature (deg C)") +
      ggplot2::theme_minimal()
    out$plot <- p
  }

  out
}
