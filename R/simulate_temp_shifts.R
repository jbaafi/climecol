#' Simulate temperature shift scenarios from a fitted seasonal curve
#'
#' Given the output of [fit_seasonal_temp()], generate temperature scenarios
#' by adding fixed deltas (e.g., +1°C to +5°C) to the fitted daily mean cycle.
#'
#' @param fit A result list from [fit_seasonal_temp()].
#' @param deltas Numeric vector of °C increments to add (default 1:5).
#' @param model Which fitted model to use. Use `"best"` (default; lowest AIC)
#'   or a specific model name present in `fit$metrics$model` (e.g., `"sin1"`).
#' @param dates Optional Date vector. If supplied, the fitted day-of-year curve
#'   is mapped to these dates (using `lubridate::yday`); otherwise the native
#'   `day_of_year` from `fit$daily_avg` (1–365) is used.
#' @param as_long Logical; if `TRUE` (default) return long format with columns
#'   `key` (scenario label) and `temp_c`. If `FALSE`, return wide columns
#'   `baseline`, `Temp+1C`, `Temp+2C`, ...
#'
#' @return A tibble with either `day_of_year` (no `dates`) or `date` (if
#'   provided), plus simulated temperatures across scenarios.
#' @export
#' @examples
#' data(weather_nl)
#' fit <- fit_seasonal_temp(weather_nl, funcs = c("sin1","sin2"))
#' sims <- simulate_temp_shifts(fit, deltas = 1:5)      # long format over DOY
#' head(sims)
#'
#' # Map to actual dates:
#' days <- seq(as.Date("2024-01-01"), as.Date("2024-12-31"), by = "day")
#' sims_dates <- simulate_temp_shifts(fit, deltas = c(1, 3, 5), dates = days, model = "best")
#' head(sims_dates)
simulate_temp_shifts <- function(fit,
                                 deltas = 1:5,
                                 model   = "best",
                                 dates   = NULL,
                                 as_long = TRUE) {
  # drop 0 to avoid duplicate of baseline
  deltas <- setdiff(as.numeric(deltas), 0)

  stopifnot(is.list(fit), !is.null(fit$daily_avg), !is.null(fit$metrics))
  if (!length(deltas)) stop("`deltas` must have length >= 1.")

  # pick model
  metrics <- fit$metrics
  if (!nrow(metrics)) stop("No converged models found in `fit`.")
  if (identical(model, "best")) {
    model <- metrics$model[which.min(metrics$AIC)]
  } else {
    if (!model %in% metrics$model) {
      stop("Requested `model` not found. Available: ",
           paste(metrics$model, collapse = ", "))
    }
  }

  # extract baseline fitted series for the chosen model
  col_nm <- paste0("fitted_", model)
  if (!col_nm %in% names(fit$daily_avg)) {
    stop("Fitted values column '", col_nm, "' not found in `fit$daily_avg`.")
  }

  curve <- fit$daily_avg[, c("day_of_year", "mean_temp", col_nm)]
  names(curve)[names(curve) == col_nm] <- "baseline"

  # If dates provided, map fitted DOY curve to those dates
  if (!is.null(dates)) {
    stopifnot(inherits(dates, "Date"))
    doy <- lubridate::yday(dates)
    # approx for safety (though x are integers 1..365)
    baseline <- stats::approx(x = curve$day_of_year,
                              y = curve$baseline,
                              xout = doy,
                              rule = 2)$y
    out <- tibble::tibble(date = dates, baseline = baseline)
    key_col <- "date"
  } else {
    out <- tibble::tibble(day_of_year = curve$day_of_year,
                          baseline    = curve$baseline)
    key_col <- "day_of_year"
  }

  # Build scenario columns
  labs <- paste0("Temp+", deltas, "C")
  for (i in seq_along(deltas)) {
    out[[labs[i]]] <- out$baseline + deltas[i]
  }

  if (isTRUE(as_long)) {
    out <- tidyr::pivot_longer(
      out,
      cols = c("baseline", dplyr::all_of(labs)),
      names_to = "key",
      values_to = "temp_c"
    )
    # order scenarios nicely
    out$key <- factor(out$key, levels = c("baseline", labs))
  }

  out
}
