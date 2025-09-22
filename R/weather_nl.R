#' Daily Weather Data for Newfoundland (2013–2023)
#'
#' Curated daily fields (temperature, precipitation, snow) from Environment and
#' Climate Change Canada, standardized for ecological modeling workflows.
#'
#' @format A data frame with 5844 rows and 10 columns:
#' \describe{
#'   \item{Date}{Date of observation (Date)}
#'   \item{Year}{Calendar year (integer)}
#'   \item{Month}{Calendar month 1–12 (integer)}
#'   \item{Day}{Day of month 1–31 (integer)}
#'   \item{T_min_C}{Daily minimum temperature (°C, numeric)}
#'   \item{T_max_C}{Daily maximum temperature (°C, numeric)}
#'   \item{T_mean_C}{Daily mean temperature (°C, numeric)}
#'   \item{Rain_mm}{Daily rainfall (mm, numeric)}
#'   \item{Precip_mm}{Total precipitation (mm, numeric)}
#'   \item{Snow_cm}{Total snow (cm, numeric)}
#' }
#'
#' @details
#' Fields are curated from the raw ECCC station export. Values are as reported
#' (no gap-filling); missing values are `NA`. Column names are standardized for
#' use across \pkg{climecol} functions.
#'
#' @source Environment and Climate Change Canada. (Add station name/ID here.)
#' @examples
#' data(weather_nl)
#' dplyr::glimpse(weather_nl)
"weather_nl"
