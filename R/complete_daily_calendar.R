#' Complete the daily calendar per station and mark gaps
#'
#' @param df Tibble with at least `date` and `station`.
#' @param start Optional `Date` scalar. If `NULL`, uses per-station min date.
#' @param end   Optional `Date` scalar. If `NULL`, uses per-station max date.
#' @param by    Sequence step; only `"day"` is supported.
#' @return A tibble with a full daily calendar per station and a logical
#'   column `is_missing_row` indicating rows that were absent in the input.
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
