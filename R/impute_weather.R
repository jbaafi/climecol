#' Impute missing weather values by station
#'
#' @description
#' Lightweight imputers for common weather gaps. Operates per-station and
#' returns the same rows/columns with imputed values in selected columns.
#' Defaults are conservative (temperatures + wind speed only).
#'
#' @param df Tibble with at least `date` and `station`.
#' @param method One of `"locf"`, `"linear"`, `"spline"`.
#'   - `"locf"`: last observation carried forward (then backward pass).
#'   - `"linear"`: piecewise linear interpolation (via `approx`).
#'   - `"spline"`: cubic spline (`stats::spline`), smoothest; use with care.
#' @param cols Character vector of columns to impute. Default:
#'   c("tmax_c","tmin_c","tavg_c","wind_spd_kmh").
#'   (Precip/snow often have true zeros and bursts; include them explicitly if desired.)
#' @param max_gap Integer number of days. Only interpolate runs of NAs of length
#'   <= `max_gap`; longer runs remain NA (applies to `"linear"`/`"spline"`).
#'   Default Inf.
#' @return Tibble like `df` with imputed values in `cols`.
#' @export
impute_weather <- function(df,
                           method = c("locf","linear","spline"),
                           cols = c("tmax_c","tmin_c","tavg_c","wind_spd_kmh"),
                           max_gap = Inf) {
  stopifnot(all(c("date","station") %in% names(df)))
  method <- match.arg(method)
  df <- dplyr::as_tibble(df)

  # keep only columns that exist and are numeric
  cols <- cols[cols %in% names(df)]
  is_num <- vapply(cols, function(x) is.numeric(df[[x]]), logical(1))
  cols <- cols[is_num]
  if (!length(cols)) return(df)

  # helper: run-length finder for NA gaps
  na_runs <- function(x) {
    r <- rle(is.na(x))
    ends <- cumsum(r$lengths)
    starts <- ends - r$lengths + 1
    tibble::tibble(start = starts[r$values], end = ends[r$values])
  }

  impute_series <- function(dates, values, method, max_gap) {
    n <- length(values)
    out <- values

    # Inside R/impute_weather.R, replace the LOCF branch in impute_series()

    if (method == "locf") {
      # Two-sided nearest neighbor fill (LOCF + NOCB with tie-break to forward)
      n <- length(values)
      out <- values

      # Forward pass: last observed value + distance since last
      last_val <- NA_real_
      last_idx <- NA_integer_
      fval <- rep(NA_real_, n)
      fdist <- rep(Inf, n)
      for (i in seq_len(n)) {
        if (!is.na(values[i])) { last_val <- values[i]; last_idx <- i }
        fval[i]  <- last_val
        fdist[i] <- if (is.na(last_idx)) Inf else (i - last_idx)
      }

      # Backward pass: next observed value + distance to next
      next_val <- NA_real_
      next_idx <- NA_integer_
      bval <- rep(NA_real_, n)
      bdist <- rep(Inf, n)
      for (i in n:1) {
        if (!is.na(values[i])) { next_val <- values[i]; next_idx <- i }
        bval[i]  <- next_val
        bdist[i] <- if (is.na(next_idx)) Inf else (next_idx - i)
      }

      # Choose nearer neighbor (prefer backward/next when strictly closer)
      to_fill <- which(is.na(values))
      choose_back <- bdist[to_fill] < fdist[to_fill]
      out[to_fill[ choose_back]] <- bval[to_fill[ choose_back]]
      out[to_fill[!choose_back]] <- fval[to_fill[!choose_back]]

      return(out)
    }


    idx <- which(!is.na(values))
    if (length(idx) < 2L) return(out) # cannot interpolate

    if (is.finite(max_gap)) {
      nr <- na_runs(values)
      if (nrow(nr)) {
        for (k in seq_len(nrow(nr))) {
          if ((nr$end[k] - nr$start[k] + 1) > max_gap) {
            # mark as protected by replacing NA with sentinel that won't be filled
            # (leave as NA; we'll interpolate but only overwrite where gap <= max_gap)
          }
        }
      }
    }

    x <- as.numeric(dates)
    xi <- x[idx]; yi <- values[idx]

    if (method == "linear") {
      yhat <- stats::approx(x = xi, y = yi, xout = x, method = "linear", rule = 1, ties = "ordered")$y
    } else { # spline
      yhat <- stats::spline(x = xi, y = yi, xout = x, method = "fmm")$y
    }

    # apply max_gap rule: only fill NA-runs whose length <= max_gap
    if (is.finite(max_gap)) {
      nr <- na_runs(values)
      if (nrow(nr)) {
        for (k in seq_len(nrow(nr))) {
          len <- nr$end[k] - nr$start[k] + 1
          if (len <= max_gap) {
            out[nr$start[k]:nr$end[k]] <- yhat[nr$start[k]:nr$end[k]]
          } # else keep NAs
        }
      } else {
        out[is.na(values)] <- yhat[is.na(values)]
      }
    } else {
      out[is.na(values)] <- yhat[is.na(values)]
    }

    out
  }

  df <- df |>
    dplyr::arrange(.data$station, .data$date) |>
    dplyr::group_by(.data$station) |>
    dplyr::mutate(dplyr::across(
      dplyr::all_of(cols),
      ~ impute_series(.data$date, .x, method = method, max_gap = max_gap)
    )) |>
    dplyr::ungroup()

  df
}
