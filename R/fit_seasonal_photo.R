#' Fit seasonal photoperiod curve
#'
#' Fits sinusoidal/periodic models to the mean daily photoperiod cycle
#' (averaged across years). Supports built-ins ("sin1","sin2") and user-defined
#' `nls()` models.
#'
#' You can supply a data frame with columns `date` and `photoperiod_hours`,
#' or let the function generate photoperiod using `photoperiod_year()` by
#' specifying `location` (preferred) or `lat` and the `years` to average over.
#'
#' @param df Optional data frame with columns `date` and `photoperiod_hours`.
#'   If omitted, you must provide `location` or `lat` and `years`.
#' @param location Optional character key understood by `photoperiod_year()` (e.g. "St John's").
#' @param lat Optional numeric latitude in decimal degrees (used if `location` is NULL).
#' @param years Integer vector of years to generate and average (default: last two completed years).
#' @param funcs Character vector of built-in models to fit. Options:
#'   - "sin1": a + b1 * sin(2*pi*t/365) + b2 * cos(2*pi*t/365)
#'   - "sin2": T0 * (1 + T1 * cos(2*pi*(omega*t + theta)/365))
#' @param custom Named list of user models. Each element: `list(formula = <nls-formula>, start = <named list>)`.
#'   The formula must use `avg_photo` (lhs) and `day_of_year` (rhs) defined inside this function.
#'   Example:
#'   `custom = list(cos1 = list(
#'      formula = avg_photo ~ a + b * cos(2*pi*day_of_year/365),
#'      start   = list(a = 12, b = 6)))`
#' @param plot Logical; if TRUE, include a ggplot overlay of observed vs. fitted.
#'
#' @return A list with:
#' \describe{
#'   \item{daily_avg}{tibble of `day_of_year`, observed `avg_photo`,
#'                    and one column per fitted model (`fitted_<name>`).}
#'   \item{fits}{list of `nls` fit objects (only those that converged).}
#'   \item{metrics}{tibble with `model`, `AIC`, and `R2`.}
#'   \item{plot}{ggplot object (present when `plot = TRUE`).}
#' }
#'
#' @details
#' Data are aggregated to day-of-year means across all years, then each model is
#' fit with `nls()`. R^2 is computed as 1 - SS_res/SS_tot on the aggregated series.
#'
#' @examples
#' # Example 1: from shipped data (if you have photoperiod column)
#' # df <- data.frame(date = as.Date('2020-01-01') + 0:729,
#' #                  photoperiod_hours = 12 + 6*cos(2*pi*(1:730)/365) + rnorm(730,0,0.1))
#' # res <- fit_seasonal_photo(df = df, funcs = c("sin1","sin2"), plot = TRUE)
#' # res$metrics
#'
#' # Example 2: generate via location for two years and add a custom model
#' # res2 <- fit_seasonal_photo(
#' #   location = "St John's",
#' #   years = c(2023, 2024),
#' #   funcs = "sin1",
#' #   custom = list(
#' #     cos1 = list(
#' #       formula = avg_photo ~ a + b * cos(2*pi*day_of_year/365),
#' #       start   = list(a = 12, b = 6)
#' #     )
#' #   ),
#' #   plot = TRUE
#' # )
#' # res2$metrics
#'
#' @export
#' @importFrom stats nls AIC
fit_seasonal_photo <- function(df = NULL,
                               location = NULL,
                               lat = NULL,
                               years = NULL,
                               funcs = c("sin1","sin2"),
                               custom = NULL,
                               plot = FALSE) {
  # ----- Source data -----
  if (is.null(df)) {
    if (is.null(years)) {
      # default to last two full years relative to today
      this_year <- as.integer(format(Sys.Date(), "%Y"))
      years <- c(this_year - 2, this_year - 1)
    }
    if (!is.null(location)) {
      # build via photoperiod_year for each year then bind
      lst <- lapply(years, function(y) {
        photoperiod_year(y, location = location)
      })
      pp <- dplyr::bind_rows(lst)
    } else if (!is.null(lat)) {
      # label results using a generic key
      lst <- lapply(years, function(y) {
        photoperiod_year(y, lat = lat)
      })
      pp <- dplyr::bind_rows(lst)
    } else {
      stop("Provide either `df` with columns (date, photoperiod_hours) or `location`/`lat` and `years`.")
    }
    if (!all(c("date", "daylength_hours") %in% names(pp))) {
      stop("`photoperiod_year()` must return columns `date` and `daylength_hours`.")
    }
    df <- dplyr::tibble(date = pp$date, photoperiod_hours = pp$daylength_hours)
  } else {
    if (!all(c("date", "photoperiod_hours") %in% names(df))) {
      stop("`df` must contain columns: date, photoperiod_hours")
    }
  }

  # ----- Aggregate to day-of-year means -----
  dat <- df |>
    dplyr::mutate(day_of_year = as.numeric(format(.data$date, "%j"))) |>
    dplyr::group_by(.data$day_of_year) |>
    dplyr::summarise(avg_photo = mean(.data$photoperiod_hours, na.rm = TRUE),
                     .groups = "drop")

  # ----- Built-in models -----
  photo.func1 <- function(t, a, b1, b2) a + b1 * sin(2 * pi * t / 365) + b2 * cos(2 * pi * t / 365)
  photo.func2 <- function(t, T0, T1, omega, theta) T0 * (1 + T1 * cos(2 * pi * (omega * t + theta) / 365))

  builtins <- list(
    sin1 = list(
      formula = avg_photo ~ photo.func1(day_of_year, a, b1, b2),
      start   = list(a = mean(dat$avg_photo),
                     b1 = stats::sd(dat$avg_photo) * 0.5,
                     b2 = stats::sd(dat$avg_photo) * 0.5)
    ),
    sin2 = list(
      formula = avg_photo ~ photo.func2(day_of_year, T0, T1, omega, theta),
      start   = list(T0 = mean(dat$avg_photo),
                     T1 = 0.5, omega = 1, theta = 1)
    )
  )

  # ----- Assemble requested models -----
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
    stopifnot(is.list(custom), length(names(custom)) == length(custom), all(nzchar(names(custom))))
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

  # ----- Metrics helpers -----
  calc_r2 <- function(y, yhat) {
    ss_res <- sum((y - yhat)^2, na.rm = TRUE)
    ss_tot <- sum((y - mean(y, na.rm = TRUE))^2, na.rm = TRUE)
    if (is.finite(ss_tot) && ss_tot > 0) 1 - ss_res / ss_tot else NA_real_
  }

  fits    <- list()
  metrics <- list()
  dat_out <- dat

  # ----- Fit loop -----
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
                          R2  = calc_r2(dat_out$avg_photo, yhat))
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
      ggplot2::geom_line(ggplot2::aes(y = avg_photo), linewidth = 0.9, color = "black") +
      { if (!is.null(pdat))
        ggplot2::geom_line(
          data = pdat,
          mapping = ggplot2::aes(y = fitted, color = model, linetype = model),
          linewidth = 0.9
        )
      } +
      ggplot2::scale_x_continuous(
        breaks = seq(0, 365, by = 30),
        labels = function(x) format(as.Date(x, origin = "2020-01-01"), "%b")
      ) +
      ggplot2::labs(title = "Seasonal photoperiod fit",
                    x = "Day of year", y = "Photoperiod (hours)",
                    color = "Model", linetype = "Model") +
      ggplot2::theme_minimal()
    out$plot <- gp
  }

  out
}
