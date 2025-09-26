#' Validate a standardized weather table
#'
#' @param df Tibble from read_weather_csv() with at least `date` and `station`.
#' @param temp_bounds numeric(2). Allowed °C range for temps. Default c(-60, 60).
#' @param rain_max numeric(1). Max plausible daily rain (mm). Default 200.
#' @param snow_max numeric(1). Max plausible daily snow (cm). Default Inf.
#' @param check_precip_consistency logical. Check precip vs rain/SWE. Default TRUE.
#' @param swe_ratio numeric(1). mm water per cm snow (SWE). Default 10.
#' @return list(summary = tibble, flags = tibble)
#' @export
validate_weather <- function(df,
                             temp_bounds = c(-60, 60),
                             rain_max = 200,
                             snow_max = Inf,
                             check_precip_consistency = TRUE,
                             swe_ratio = 10) {
  req <- c("date", "station")
  if (!all(req %in% names(df))) {
    stop("`df` must contain at least: ", paste(req, collapse = ", "))
  }
  df <- dplyr::as_tibble(df)

  has <- function(cols) all(cols %in% names(df))

  # A) calendar completeness per station (no .data in tidyselect)
  df_complete <- df |>
    dplyr::group_by(.data$station) |>
    tidyr::complete(date = seq(min(.data$date, na.rm = TRUE),
                               max(.data$date, na.rm = TRUE),
                               by = "day")) |>
    dplyr::ungroup()

  miss <- df_complete |>
    dplyr::anti_join(
      df |> dplyr::select(dplyr::all_of(c("station","date"))),
      by = c("station","date")
    ) |>
    dplyr::mutate(flag = "missing_date")

  # B) physical / logic checks
  flags <- list()

  if (has("rain_mm")) {
    flags$negative_rain <- df |>
      dplyr::filter(!is.na(.data$rain_mm) & .data$rain_mm < 0) |>
      dplyr::mutate(flag = "negative_rain")

    if (is.finite(rain_max)) {
      flags$rain_gt_max <- df |>
        dplyr::filter(!is.na(.data$rain_mm) & .data$rain_mm > !!rain_max) |>
        dplyr::mutate(flag = "rain_gt_max")
    }
  }

  if (has("snow_cm")) {
    flags$negative_snow <- df |>
      dplyr::filter(!is.na(.data$snow_cm) & .data$snow_cm < 0) |>
      dplyr::mutate(flag = "negative_snow")

    if (is.finite(snow_max)) {
      flags$snow_gt_max <- df |>
        dplyr::filter(!is.na(.data$snow_cm) & .data$snow_cm > !!snow_max) |>
        dplyr::mutate(flag = "snow_gt_max")
    }
  }

  if (has("precip_mm")) {
    flags$negative_precip <- df |>
      dplyr::filter(!is.na(.data$precip_mm) & .data$precip_mm < 0) |>
      dplyr::mutate(flag = "negative_precip")
  }

  if (has(c("tmax_c","tmin_c"))) {
    flags$tmax_lt_tmin <- df |>
      dplyr::filter(!is.na(.data$tmax_c) & !is.na(.data$tmin_c) & .data$tmax_c < .data$tmin_c) |>
      dplyr::mutate(flag = "tmax_lt_tmin")
  }

  if (has("tmax_c") || has("tmin_c")) {
    flags$temp_out_of_range <- df |>
      dplyr::filter(
        (
          !is.na(.data$tmax_c) &
            (
              (is.finite(temp_bounds[1]) & (.data$tmax_c < !!temp_bounds[1])) |
                (is.finite(temp_bounds[2]) & (.data$tmax_c > !!temp_bounds[2]))
            )
        ) |
          (
            !is.na(.data$tmin_c) &
              (
                (is.finite(temp_bounds[1]) & (.data$tmin_c < !!temp_bounds[1])) |
                  (is.finite(temp_bounds[2]) & (.data$tmin_c > !!temp_bounds[2]))
              )
          )
      ) |>
      dplyr::mutate(flag = "temp_out_of_range")
  }

  if (has("wind_dir_deg")) {
    flags$gust_dir_out_of_range <- df |>
      dplyr::filter(!is.na(.data$wind_dir_deg) & (.data$wind_dir_deg < 0 | .data$wind_dir_deg > 360)) |>
      dplyr::mutate(flag = "gust_dir_out_of_range")
  }

  # C) precipitation consistency (optional)
  if (isTRUE(check_precip_consistency) && has("precip_mm")) {
    cons_flags <- list()

    if (has("rain_mm")) {
      cons_flags$precip_lt_rain <- df |>
        dplyr::filter(!is.na(.data$precip_mm) & !is.na(.data$rain_mm) &
                        (.data$precip_mm < .data$rain_mm)) |>
        dplyr::mutate(flag = "precip_inconsistent")
    }

    if (has("snow_cm") && is.finite(swe_ratio)) {
      cons_flags$precip_lt_swe <- df |>
        dplyr::filter(!is.na(.data$precip_mm) & !is.na(.data$snow_cm) &
                        (.data$precip_mm < (.data$snow_cm * !!swe_ratio))) |>
        dplyr::mutate(flag = "precip_inconsistent")
    }

    if (length(cons_flags)) {
      flags$precip_inconsistent <- dplyr::bind_rows(cons_flags)
    }
  }

  # Combine flags
  flags$missing_date <- miss
  flags_tbl <- dplyr::bind_rows(flags, .id = "check")
  if (nrow(flags_tbl)) {
    flags_tbl <- flags_tbl |>
      dplyr::arrange(.data$station, .data$date) |>
      dplyr::select(-check)
  }

  summary <- tibble::tibble(
    n_rows                = nrow(df),
    stations              = dplyr::n_distinct(df$station),
    span_start            = suppressWarnings(min(df$date, na.rm = TRUE)),
    span_end              = suppressWarnings(max(df$date, na.rm = TRUE)),
    n_missing_dates       = sum(flags_tbl$flag == "missing_date", na.rm = TRUE),
    n_negative_values     = sum(flags_tbl$flag %in% c("negative_rain","negative_snow","negative_precip"), na.rm = TRUE),
    n_tmax_lt_tmin        = sum(flags_tbl$flag == "tmax_lt_tmin", na.rm = TRUE),
    n_temp_oob            = sum(flags_tbl$flag == "temp_out_of_range", na.rm = TRUE),
    n_rain_gt_max         = sum(flags_tbl$flag == "rain_gt_max", na.rm = TRUE),
    n_snow_gt_max         = sum(flags_tbl$flag == "snow_gt_max", na.rm = TRUE),
    n_precip_inconsistent = sum(flags_tbl$flag == "precip_inconsistent", na.rm = TRUE)
  )

  list(summary = summary, flags = flags_tbl)
}
