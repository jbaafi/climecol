#' Export curated or simulated weather data
#'
#' Writes a weather dataset (observed, imputed, or scenario-based)
#' to a CSV file with standardized metadata for reproducibility.
#'
#' This function behaves like [utils::write.csv()] but automatically
#' embeds key metadata (station, scenario, package version, and date)
#' as commented header lines at the top of the file.
#'
#' @param df A data frame or tibble containing weather data.
#' @param path File path to write the CSV output.
#' @param meta Named list of metadata fields (optional). Typical fields include:
#'   `station`, `scenario`, `source`, and `version`.
#'   If not provided, basic metadata (date and package version) are used.
#' @param overwrite Logical; if `TRUE`, overwrite existing file (default = TRUE).
#' @return Invisibly returns the written file path.
#' @examples
#' data(weather_nl)
#' tmpfile <- tempfile(fileext = ".csv")
#' export_weather(
#'   weather_nl,
#'   path = tmpfile,
#'   meta = list(station = "St. John's", scenario = "baseline")
#' )
#' readLines(tmpfile, n = 6)  # view header
#' @export
export_weather <- function(df, path, meta = NULL, overwrite = TRUE) {
  if (!is.data.frame(df)) stop("`df` must be a data frame or tibble.")
  if (file.exists(path) && !overwrite) stop("File already exists: ", path)

  # --- metadata block ----
  base_meta <- list(
    package = paste0("climecol ", utils::packageVersion("climecol")),
    date    = as.character(Sys.Date())
  )
  all_meta <- c(base_meta, meta)

  header_lines <- paste0("# ", names(all_meta), ": ", unlist(all_meta))

  # --- write to a temporary file then rename ----
  tmp <- tempfile(fileext = ".csv")
  utils::write.csv(df, tmp, row.names = FALSE)

  # prepend header lines
  con_out <- file(path, open = "wt")
  writeLines(c("# Weather data export", header_lines, ""), con_out)
  writeLines(readLines(tmp), con_out)
  close(con_out)
  unlink(tmp)

  message("Weather data exported to ", normalizePath(path, mustWork = FALSE))
  invisible(path)
}
