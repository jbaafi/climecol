#' Complete the daily calendar per station and mark gaps
#'
#' Expands each station's date range to a complete daily sequence and flags which
#' rows were **absent** in the original data. This is a structural step only—
#' it does not fill values (see [impute_weather()] for gap filling).
#'
#' @param df Tibble with at least `date` (Date) and `station` (character).
#' @param start Optional `Date` scalar. Overall lower bound for the calendar; if
#'   `NULL` (default), each station uses its own minimum observed date.
#' @param end   Optional `Date` scalar. Overall upper bound for the calendar; if
#'   `NULL` (default), each station uses its own maximum observed date.
#' @param by    Sequence step; only `"day"` is supported.
#'
#' @return A tibble with a full daily calendar per station and a logical column
#'   `is_missing_row` indicating rows that were not present in the input.
#'
#' @details
#' - Input rows are preserved as-is; new calendar rows get `NA` for data fields
#'   and `is_missing_row = TRUE`.
#' - Use [summarise_gaps()] to quantify coverage (e.g., counts of missing days
#'   and longest gap) after calling this function.
#' - Use [impute_weather()] if you want to fill the missing values created by
#'   the calendar expansion.
#'
#' @section Typical workflow:
#' 1. `df <- normalize_weather_names(df)` (optional—helps standardize columns)
#' 2. `cal <- complete_daily_calendar(df)` (make gaps explicit)
#' 3. `summarise_gaps(cal)` (report coverage)
#' 4. `imp <- impute_weather(cal, method = "locf")` (optional gap filling)
#'
#' @examples
#' data(weather_nl)
#'
#' # Make sure column names align with climecol helpers
#' wx <- normalize_weather_names(weather_nl)
#'
#' # Expand to full per-station daily calendar
#' cal <- complete_daily_calendar(wx)
#' head(cal)
#'
#' # Summarise coverage (per station)
#' summarise_gaps(cal, by = "station")
#'
#' # Restrict to a fixed date window for all stations
#' rng_start <- as.Date("2015-01-01")
#' rng_end   <- as.Date("2016-12-31")
#' cal_fixed <- complete_daily_calendar(wx, start = rng_start, end = rng_end)
#'
#' @seealso [summarise_gaps()], [impute_weather()], [validate_weather()]
#' @export
complete_daily_calendar <- function(df, start = NULL, end = NULL, by = "day") {
  stopifnot(all(c("date","station") %in% names(df)))
  if (!identical(by, "day")) stop("Only by = 'day' is supported.")

  df <- dplyr::as_tibble(df)

  # Per-station ranges (honour global start/end if supplied)
  ranges <- df |>
    dplyr::group_by(.data$station) |>
    dplyr::summarise(
      start = if (is.null(start)) min(.data$date, na.rm = TRUE) else as.Date(start),
      end   = if (is.null(end))   max(.data$date, na.rm = TRUE) else as.Date(end),
      .groups = "drop"
    )

  # Build complete calendar without rowwise/.data NSE
  full_list <- lapply(seq_len(nrow(ranges)), function(i) {
    tibble::tibble(
      station = ranges$station[i],
      date = seq(ranges$start[i], ranges$end[i], by = "day")
    )
  })
  full <- dplyr::bind_rows(full_list)

  # Join original data
  out <- full |>
    dplyr::left_join(df, by = c("station","date"))

  # Flag rows that were missing in the input
  have <- df |> dplyr::select(dplyr::all_of(c("station","date")))
  out <- out |>
    dplyr::mutate(
      is_missing_row = !paste(.data$station, .data$date) %in% paste(have$station, have$date)
    )

  out
}
