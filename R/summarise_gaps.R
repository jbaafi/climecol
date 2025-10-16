#' Summarise gaps in daily weather records
#'
#' Provides coverage and continuity metrics per station or per station–month.
#' This function is useful for quickly checking the completeness of daily
#' weather time series before downstream analysis.
#'
#' @param df Tibble with at least `date` and `station` columns.
#' @param by Character, one of `"station"` (default) or `"month"`.
#'   If `"month"`, summaries are returned per station–month combination.
#'
#' @return
#' A tibble summarising record coverage with the following columns:
#' \describe{
#'   \item{station}{Station name or ID.}
#'   \item{n_days}{Total number of days in the span.}
#'   \item{n_missing}{Number of missing calendar days.}
#'   \item{coverage}{Proportion of days present (1 = complete).}
#'   \item{n_gaps}{Number of contiguous missing-day gaps.}
#'   \item{longest_gap}{Length (days) of the longest missing period.}
#' }
#'
#' @details
#' If the input has already been passed through
#' \code{\link{complete_daily_calendar}()}, this function will recognise and
#' reuse its internal `is_missing_row` flag; otherwise it infers missing days
#' automatically from the date span.
#'
#' @examples
#' data(weather_nl)
#'
#' # Summarise completeness by station
#' summarise_gaps(weather_nl, by = "station")
#'
#' #> # A tibble: 2 × 6
#' #>   station             n_days n_missing coverage n_gaps longest_gap
#' #>   <chr>                <int>     <int>    <dbl>  <int>       <int>
#' #> 1 ST JOHN'S A           1827         0    1.00       0           0
#' #> 2 ST. JOHN'S INTL A     4017         0    1.00       0           0
#'
#' # Monthly view (truncated example)
#' head(summarise_gaps(weather_nl, by = "month"))
#'
#' @export
summarise_gaps <- function(df, by = c("station", "month")) {
  by <- match.arg(by)

  req <- c("date", "station")
  if (!all(req %in% names(df))) {
    stop("`df` must contain at least: ", paste(req, collapse = ", "))
  }

  df <- dplyr::as_tibble(df)

  # Build a unified "missing" flag:
  # - missing row added by complete_daily_calendar(), OR
  non_key <- setdiff(names(df), c("station", "date", "is_missing_row", "month"))

  all_na_content <- if (length(non_key) == 0L) {
    rep(FALSE, nrow(df))
  } else {
    apply(df[, non_key, drop = FALSE], 1L, function(r) all(is.na(r)))
  }

  missing_flag <- (("is_missing_row" %in% names(df)) & isTRUE(df$is_missing_row)) | all_na_content

  df <- df |>
    dplyr::mutate(
      month = format(.data$date, "%Y-%m"),
      .missing_for_gaps = missing_flag
    )

  # safe access to is_missing_row (vector), default FALSE if column absent
  missing_row <- if ("is_missing_row" %in% names(df)) {
    # coerce to logical, replace NA with FALSE
    r <- as.logical(df$is_missing_row)
    r[is.na(r)] <- FALSE
    r
  } else {
    rep(FALSE, nrow(df))
  }

  missing_flag <- missing_row | all_na_content

  df <- df |>
    dplyr::mutate(
      month = format(.data$date, "%Y-%m"),
      .missing_for_gaps = missing_flag
    )

  group_vars <- if (by == "station") "station" else c("station", "month")

  dplyr::group_by(df, dplyr::across(dplyr::all_of(group_vars))) |>
    dplyr::summarise(
      n_days    = dplyr::n(),
      n_missing = sum(.data$.missing_for_gaps, na.rm = TRUE),
      coverage  = (n_days - n_missing) / n_days,
      n_gaps = {
        r <- rle(.data$.missing_for_gaps)
        sum(r$values, na.rm = TRUE)  # number of TRUE runs
      },
      longest_gap = {
        r <- rle(.data$.missing_for_gaps)
        if (any(r$values, na.rm = TRUE)) max(r$lengths[r$values], na.rm = TRUE) else 0L
      },
      .groups = "drop"
    )
}
