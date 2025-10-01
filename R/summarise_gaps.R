#' Summarise gaps in daily weather records
#'
#' Provides simple coverage metrics per station (and optionally by month).
#'
#' @param df Tibble with at least `date` and `station`.
#' @param by Character, one of `"station"` (default) or `"month"`.
#'   If `"month"`, summaries are returned per station-month.
#'
#' @return tibble with counts: total days, missing days, coverage proportion,
#'   number of contiguous gaps, and longest gap length.
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
  # - existing row whose non-key columns are all NA
  non_key <- setdiff(names(df), c("station", "date", "is_missing_row", "month"))
  all_na_content <- if (length(non_key) == 0) {
    rep(FALSE, nrow(df))
  } else {
    apply(df[non_key], 1, function(r) all(is.na(r)))
  }
  missing_flag <- (("is_missing_row" %in% names(df)) & isTRUE(df$is_missing_row)) | all_na_content

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
