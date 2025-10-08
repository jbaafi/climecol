#' Sample daily rainfall by month
#'
#' Generates a synthetic **daily** rainfall series by resampling observed
#' daily values from the **same calendar month** across years. This preserves
#' each month's empirical distribution (including dry-day frequency) without
#' imposing a parametric model.
#'
#' The function is robust to varied input column names: it will first attempt
#' to standardize with `normalize_weather_names()`, then look for a rainfall
#' column (`rain_mm` by default) and derive the month from `date` if present.
#'
#' @param dates A vector of `Date`s to simulate for (one value returned per
#'   date). Alternatively, a numeric/integer vector is treated as day offsets
#'   from `origin`.
#' @param df A data frame of observed daily rainfall. Ideally contains
#'   `date` and `rain_mm` (lowercase). If not, the function attempts to
#'   standardize via `normalize_weather_names()`. If `date` is missing, an
#'   integer `Month` or `month` column must exist.
#' @param rain_col Optional. Name of the rainfall column in `df`. By default,
#'   tries `rain_mm` after normalization, then falls back to any column whose
#'   name matches `"rain|precip"` (case-insensitive).
#' @param drop_na Logical; if `TRUE` (default) remove `NA` values from the
#'   monthly sampling pools.
#' @param na_as_zero Logical; return 0 for sampled `NA`s (default `TRUE`).
#'   Ignored when `drop_na = TRUE` since `NA`s are removed from pools.
#' @param replace Logical; sample with replacement. Default `TRUE`.
#' @param origin If `dates` is numeric, interpret as days since this origin
#'   (default `"2000-01-01"`). Ignored if `dates` are `Date`s.
#' @param seed Optional integer for reproducible sampling. Default `NULL`.
#'
#' @return A numeric vector of length `length(dates)` with simulated daily rain (mm).
#' @export
#'
#' @examples
#' # Using the shipped example data
#' data(weather_nl)
#' set.seed(123)
#' dseq <- seq.Date(as.Date("2012-01-01"), as.Date("2012-01-10"), by = "day")
#' sim  <- sample_rainfall_by_month(dseq, weather_nl)
#' sim
#'
#' # Numeric date offsets (days since origin)
#' sample_rainfall_by_month(0:9, weather_nl, origin = "2012-01-01")
sample_rainfall_by_month <- function(dates,
                                     df,
                                     rain_col   = NULL,
                                     drop_na    = TRUE,
                                     na_as_zero = TRUE,
                                     replace    = TRUE,
                                     origin     = "2000-01-01",
                                     seed       = NULL) {
  # Normalize/prepare dates
  if (is.numeric(dates)) {
    dates <- as.Date(origin) + as.integer(dates)
  }
  stopifnot(inherits(dates, "Date"))

  # Try to standardize column names if possible
  if (is.data.frame(df)) {
    df_std <- try(normalize_weather_names(df), silent = TRUE)
    if (!inherits(df_std, "try-error")) df <- df_std
  }

  # Determine rainfall column
  if (is.null(rain_col)) {
    if ("rain_mm" %in% names(df)) {
      rain_col <- "rain_mm"
    } else {
      cand <- names(df)[grepl("rain|precip", names(df), ignore.case = TRUE)]
      rain_col <- cand[1]
      if (is.na(rain_col)) {
        stop("Could not find rainfall column; specify `rain_col`.")
      }
    }
  }
  if (!rain_col %in% names(df)) {
    stop("`rain_col` '", rain_col, "' not found in `df`.")
  }

  # Derive month vector
  if ("date" %in% names(df)) {
    month_vec <- as.integer(format(as.Date(df[["date"]]), "%m"))
  } else if ("Month" %in% names(df)) {
    month_vec <- as.integer(df[["Month"]])
  } else if ("month" %in% names(df)) {
    month_vec <- as.integer(df[["month"]])
  } else {
    stop("`df` must have `date` (preferred) or an integer `Month`/`month` column.")
  }

  # Prepare pools
  pool <- as.numeric(df[[rain_col]])
  if (isTRUE(drop_na)) {
    keep <- !is.na(pool) & !is.na(month_vec)
  } else {
    keep <- !is.na(month_vec)
  }
  pool_all  <- pool[keep]
  month_all <- month_vec[keep]

  pools <- split(pool_all, month_all)  # named by month "1".."12"
  tgt_months <- as.integer(format(dates, "%m"))

  # Reproducibility
  if (!is.null(seed)) {
    old <- .Random.seed
    on.exit({ if (exists("old")) .Random.seed <<- old }, add = TRUE)
    set.seed(seed)
  }

  # Sampling loop
  out <- vapply(seq_along(tgt_months), function(i) {
    m <- tgt_months[i]
    vals <- pools[[as.character(m)]]
    if (is.null(vals) || length(vals) == 0L) {
      return(0)
    }
    s <- sample(vals, size = 1L, replace = replace)
    if (is.na(s) && isTRUE(na_as_zero)) 0 else as.numeric(s)
  }, numeric(1))

  out
}
