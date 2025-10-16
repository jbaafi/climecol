#' Simulate daily rainfall scenarios (monthly-seasonal sampling)
#'
#' Samples daily rainfall by drawing (with replacement) from the empirical
#' distribution of the *same calendar month* across all years, then applies
#' simple scenario transforms (baseline/dry/wet/erratic). This preserves
#' monthly seasonality while allowing stochastic realisations.
#'
#' @param df A data frame containing at least a date column and rainfall.
#'   Works out-of-the-box with `weather_nl`. If column names differ, they will
#'   be normalised via `normalize_weather_names()`.
#' @param times Either:
#'   - a vector of `Date`s to simulate for, or
#'   - an integer vector of day offsets from an origin date (see `origin`), or
#'   - `NULL` (default): use the span of `df$date`.
#' @param scenarios Character vector of scenario names to generate.
#'   Built-ins: `"baseline"`, `"dry"`, `"wet"`, `"erratic"`.
#' @param scales Named numeric multipliers for scenarios. Defaults:
#'   `list(dry = 0.5, wet = 1.5)`.
#' @param erratic_range Numeric length-2 giving min/max random factor for
#'   `"erratic"` scenario. Default `c(0.1, 2.0)`.
#' @param origin Date used when `times` are integers (day offsets).
#'   Default `"2008-01-01"`.
#' @param plot Logical; if `TRUE`, include a ggplot comparing scenarios.
#'
#' @return A list with:
#' \describe{
#'   \item{series}{Tibble with columns `date`, `month`, `scenario`, `rain_mm`.}
#'   \item{plot}{`ggplot` object if `plot = TRUE`, otherwise `NULL`.}
#' }
#'
#' @details
#' For each simulated day, the function identifies that day’s calendar month and
#' samples one value from the pool of observed daily rainfall for that month
#' across all years in `df`. Scenario transforms are applied afterwards:
#' \itemize{
#'   \item baseline: identity
#'   \item dry: multiply by `scales$dry`
#'   \item wet: multiply by `scales$wet`
#'   \item erratic: multiply by `runif(1, erratic_range[1], erratic_range[2])`
#' }
#'
#' Zeros in the empirical pool are naturally preserved by resampling.
#'
#' @examples
#' data(weather_nl)
#' set.seed(1)
#' sim <- simulate_rainfall_scenarios(weather_nl,
#'                                    times = as.Date("2010-01-01") + 0:59,
#'                                    scenarios = c("baseline","dry","wet"),
#'                                    plot = TRUE)
#' head(sim$series)
#' if (!is.null(sim$plot)) print(sim$plot)
#'
#' @export
simulate_rainfall_scenarios <- function(df,
                                        times      = NULL,
                                        scenarios  = c("baseline","dry","wet","erratic"),
                                        scales     = list(dry = 0.5, wet = 1.5),
                                        erratic_range = c(0.1, 2.0),
                                        origin     = as.Date("2008-01-01"),
                                        plot       = FALSE) {
  # Normalize column names if needed
  if (!all(c("date","rain_mm") %in% names(df))) {
    df <- normalize_weather_names(df)
  }
  stopifnot(all(c("date","rain_mm") %in% names(df)))

  df <- dplyr::as_tibble(df)
  df <- dplyr::mutate(df,
                      month = as.integer(format(.data$date, "%m")))

  # Build simulation date vector
  sim_dates <-
    if (is.null(times)) {
      seq(min(df$date, na.rm = TRUE), max(df$date, na.rm = TRUE), by = "day")
    } else if (inherits(times, "Date")) {
      times
    } else {
      # integer offsets
      origin + as.integer(times)
    }

  sim_month <- as.integer(format(sim_dates, "%m"))

  # Pre-compute per-month pools (drop NAs; keep zeros)
  pools <- lapply(1:12, function(m) {
    vals <- df$rain_mm[df$month == m]
    vals <- vals[!is.na(vals)]
    vals
  })

  # Helper: draw one sample for a given month (0 if pool empty)
  draw_one <- function(m) {
    pm <- pools[[m]]
    if (length(pm)) sample(pm, size = 1L, replace = TRUE) else 0
  }

  # Baseline samples for all days
  baseline <- vapply(sim_month, draw_one, numeric(1))

  # Build scenarios
  make_scenario <- function(name) {
    if (name == "baseline") {
      vals <- baseline
    } else if (name == "dry") {
      mult <- if (!is.null(scales$dry)) scales$dry else 0.5
      vals <- baseline * mult
    } else if (name == "wet") {
      mult <- if (!is.null(scales$wet)) scales$wet else 1.5
      vals <- baseline * mult
    } else if (name == "erratic") {
      vals <- baseline * stats::runif(length(baseline), min = erratic_range[1], max = erratic_range[2])
    } else {
      warning("Unknown scenario '", name, "'. Returning baseline for it.")
      vals <- baseline
    }
    vals
  }

  out_list <- lapply(scenarios, function(sc) {
    tibble::tibble(
      date     = sim_dates,
      month    = sim_month,
      scenario = sc,
      rain_mm  = make_scenario(sc)
    )
  })

  series <- dplyr::bind_rows(out_list)

  # Plot if requested
  gp <- NULL
  if (isTRUE(plot)) {
    gp <- ggplot2::ggplot(series, ggplot2::aes(x = .data$date, y = .data$rain_mm, color = .data$scenario)) +
      ggplot2::geom_line(alpha = 0.8) +
      ggplot2::labs(x = "Date", y = "Rainfall (mm)", color = "Scenario",
                    title = "Simulated daily rainfall scenarios (monthly-seasonal sampling)") +
      ggplot2::theme_bw()
  }

  list(series = series, plot = gp)
}
