#' Fit seasonal temperature curve
#'
#' Fits sinusoidal/periodic models to the mean daily temperature cycle
#' (averaged across years). Supports built-ins ("sin1","sin2") and arbitrary
#' user-defined `nls()` models.
#'
#' @param df Data frame with column `date` and either `tavg_c` or both
#'   `tmin_c` and `tmax_c`.
#' @param funcs Character vector of built-in models to fit. Options:
#'   - "sin1": \eqn{a + b_1 \sin(2\pi t / 365) + b_2 \cos(2\pi t / 365)}
#'   - "sin2": \eqn{T_0 \left(1 + T_1 \cos(2\pi(\omega t + \theta)/365)\right)}
#' @param custom Named list of user models. Each element should be a list with:
#'   - `formula`: an `nls` formula using variables `mean_temp` (response) and
#'     `day_of_year` (predictor) defined by this function.
#'   - `start`: a named list of starting parameters for `nls()`.
#'   Example:
#'   `custom = list(cos1 = list(
#'      formula = mean_temp ~ a + b * cos(2*pi*day_of_year/365),
#'      start   = list(a = 0, b = 10)))`
#' @param plot Logical; if TRUE, include a ggplot overlay of observed vs. fitted.
#'
#' @return A list with:
#' \describe{
#'   \item{daily_avg}{tibble of day-of-year (`day_of_year`), observed `mean_temp`,
#'                    and one column per fitted model (`fitted_<name>`).}
#'   \item{fits}{list of `nls` fit objects (only the ones that converged).}
#'   \item{metrics}{tibble with `model`, `AIC`, and `R2` per converged fit.}
#'   \item{plot}{ggplot object (present when `plot = TRUE`).}
#' }
#'
#' @details
#' Data are aggregated to day-of-year means across all years, then each model is
#' fit with `nls()`. R^2 is computed as 1 - SS_res/SS_tot on the aggregated series.
#' User formulas must reference `mean_temp` (lhs) and `day_of_year` (rhs).
#'
#' @examples
#' data(weather_nl)
#' # Built-ins
#' res <- fit_seasonal_temp(weather_nl, funcs = c("sin1","sin2"), plot = TRUE)
#' res$metrics
#'
#' # Add a user-defined cosine model
#' res2 <- fit_seasonal_temp(
#'   weather_nl,
#'   funcs = "sin1",
#'   custom = list(
#'     cos1 = list(
#'       formula = mean_temp ~ a + b * cos(2*pi*day_of_year/365),
#'       start   = list(a = mean(weather_nl$tavg_c, na.rm = TRUE), b = 5)
#'     )
#'   ),
#'   plot = TRUE
#' )
#' res2$metrics
#' @export
#' @importFrom stats nls AIC
fit_seasonal_temp <- function(df,
                              funcs  = c("sin1","sin2"),
                              custom = NULL,
                              plot   = FALSE) {
  stopifnot("date" %in% names(df))

  # choose temperature series
  if ("tavg_c" %in% names(df)) {
    temp <- df$tavg_c
  } else if (all(c("tmin_c","tmax_c") %in% names(df))) {
    temp <- rowMeans(df[, c("tmin_c","tmax_c")], na.rm = TRUE)
  } else {
    stop("`df` must contain `tavg_c` or both `tmin_c` and `tmax_c`.")
  }

  # aggregate to day-of-year means
  dat <- df |>
    dplyr::mutate(
      day_of_year = as.numeric(format(.data$date, "%j")),
      tavg        = temp
    ) |>
    dplyr::group_by(.data$day_of_year) |>
    dplyr::summarise(mean_temp = mean(.data$tavg, na.rm = TRUE), .groups = "drop")

  # built-in model definitions
  temp.func1 <- function(t, a, b1, b2) a + b1 * sin(2 * pi * t / 365) + b2 * cos(2 * pi * t / 365)
  temp.func2 <- function(t, T0, T1, omega, theta) T0 * (1 + T1 * cos(2 * pi * (omega * t + theta) / 365))

  builtins <- list(
    sin1 = list(
      formula = mean_temp ~ temp.func1(day_of_year, a, b1, b2),
      start   = list(a = mean(dat$mean_temp),
                     b1 = stats::sd(dat$mean_temp) * 0.5,
                     b2 = stats::sd(dat$mean_temp) * 0.5)
    ),
    sin2 = list(
      formula = mean_temp ~ temp.func2(day_of_year, T0, T1, omega, theta),
      start   = list(T0 = mean(dat$mean_temp),
                     T1 = 0.5, omega = 1, theta = 1)
    )
  )

  # assemble requested models
  model_specs <- list()
  if (length(funcs)) {
    keep <- intersect(funcs, names(builtins))
    model_specs <- c(model_specs, builtins[keep])
    unknown <- setdiff(funcs, names(builtins))
    if (length(unknown)) {
      warning("Ignoring unknown built-in model(s): ", paste(unknown, collapse = ", "))
    }
  }
  if (!is.null(custom)) {
    stopifnot(is.list(custom), length(names(custom)) == length(custom),
              all(nzchar(names(custom))))
    # validate each custom entry
    for (nm in names(custom)) {
      spec <- custom[[nm]]
      if (!is.list(spec) || is.null(spec$formula) || is.null(spec$start)) {
        stop("Each custom model must be a list with `formula` and `start`. Bad entry: ", nm)
      }
      model_specs[[nm]] <- list(formula = spec$formula, start = spec$start)
    }
  }
  if (!length(model_specs)) {
    stop("No models to fit. Provide built-ins via `funcs` and/or `custom` models.")
  }

  calc_r2 <- function(y, yhat) {
    ss_res <- sum((y - yhat)^2, na.rm = TRUE)
    ss_tot <- sum((y - mean(y, na.rm = TRUE))^2, na.rm = TRUE)
    1 - ss_res / ss_tot
  }

  fits    <- list()
  metrics <- list()
  dat_out <- dat

  # fit loop
  for (nm in names(model_specs)) {
    spec <- model_specs[[nm]]
    fit <- try(
      stats::nls(formula = spec$formula, data = dat, start = spec$start),
      silent = TRUE
    )
    if (inherits(fit, "try-error")) {
      warning("Model '", nm, "' failed to converge; skipping.")
      next
    }
    fits[[nm]] <- fit
    yhat <- stats::predict(fit)
    dat_out[[paste0("fitted_", nm)]] <- as.numeric(yhat)
    metrics[[nm]] <- list(AIC = stats::AIC(fit),
                          R2  = calc_r2(dat_out$mean_temp, yhat))
  }

  out <- list(
    daily_avg = dat_out,
    fits      = fits,
    metrics   = if (length(metrics)) {
      tibble::tibble(
        model = names(metrics),
        AIC   = vapply(metrics, function(m) m$AIC, numeric(1)),
        R2    = vapply(metrics, function(m)  m$R2, numeric(1))
      )
    } else {
      tibble::tibble(model = character(), AIC = numeric(), R2 = numeric())
    }
  )

  if (plot) {
    # long format for automatic legend over any number of models
    fitted_cols <- grep("^fitted_", names(dat_out), value = TRUE)
    pdat <- if (length(fitted_cols)) {
      tidyr::pivot_longer(
        dat_out,
        cols = dplyr::all_of(fitted_cols),
        names_to = "model",
        values_to = "fitted"
      ) |>
        dplyr::mutate(model = sub("^fitted_", "", .data$model))
    } else {
      NULL
    }

    gp <- ggplot2::ggplot(dat_out, ggplot2::aes(x = day_of_year)) +
      ggplot2::geom_line(ggplot2::aes(y = mean_temp), linewidth = 0.9, color = "black") +
      { if (!is.null(pdat))
        ggplot2::geom_line(
          data = pdat,
          mapping = ggplot2::aes(y = fitted, color = model, linetype = model),
          linewidth = 0.9
        )
      } +
      ggplot2::labs(title = "Seasonal temperature fit",
                    x = "Day of year", y = "Mean temperature (deg C)",
                    color = "Model", linetype = "Model") +
      ggplot2::theme_minimal()
    out$plot <- gp
  }

  out
}
