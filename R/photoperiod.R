#' Daylength (photoperiod) in hours (Forsythe et al. 1995)
#'
#' Fast, dependency-free daylight length given date and latitude.
#' @param date Date vector.
#' @param lat  Latitude in decimal degrees (-90..90).
#' @return Numeric vector of daylight length in hours.
#' @references Forsythe, W. C. et al. (1995) Ecol. Modelling 80: 1–13.
#' @export
daylength_f95 <- function(date, lat) {
  date <- as.Date(date)
  lat  <- as.numeric(lat)
  latr <- lat * pi/180
  n <- as.integer(strftime(date, "%j"))    # day-of-year 1..366

  # Solar declination (radians)
  delta <- 0.409 * sin(2 * pi * n/365 - 1.39)

  # Atmospheric refraction + solar disk radius at sunrise/sunset: -0.833 degrees
  sinH0 <- -0.01454
  cosH  <- (sinH0 - sin(latr) * sin(delta)) / (cos(latr) * cos(delta))
  cosH  <- pmin(1, pmax(-1, cosH))         # clamp for numerical safety
  H     <- acos(cosH)                      # hour angle [rad]
  24 * H / pi                              # hours
}

#' Built-in latitudes for convenience
#'
#' Small named vector so users can supply `location` instead of `lat`.
#' Extend/modify as you like.
#' @keywords internal
.photoperiod_sites <- c(
  "st_johns"   = 47.56,   # St. John's, NL, Canada
  "saint_john"  = 45.27,  # Saint John, NB, Canada
  "kumasi"     = 6.69,    # Ghana
  "nairobi"    = -1.29,   # Kenya
  "cape_town"  = -33.92,  # South Africa
  "ain_mahbel" = 34.24    # Algeria
)

# Normalize to a safe ASCII key: transliterate, lowercase, "st" -> "saint", strip non-alnum
normalize_key <- function(x) {
  # Convert to ASCII (handles curly quotes, accents, etc.)
  x <- iconv(x, from = "", to = "ASCII//TRANSLIT")
  x <- tolower(x)
  # Treat "St", "St.", "st " at beginning as "saint "
  x <- sub("^st\\.?\\s*", "saint ", x, perl = TRUE)
  # Remove non-alphanumeric chars (keep letters & digits only)
  gsub("[^[:alnum:]]+", "", x, perl = TRUE)
}

# Build a lookup (keys -> index into .photoperiod_sites), including aliases
.build_site_keymap <- function() {
  site_names <- names(.photoperiod_sites)
  n_sites    <- length(site_names)

  # Base keys
  base_keys  <- vapply(site_names, normalize_key, character(1))
  # Alias keys: also allow "saint ..." versions of the names
  saint_names <- sub("^st\\b", "saint", site_names, ignore.case = TRUE, perl = TRUE)
  alias_keys  <- vapply(saint_names, normalize_key, character(1))

  # Map both base & alias keys back to canonical indices 1..n_sites
  all_keys <- c(base_keys, alias_keys)
  all_idx  <- c(seq_len(n_sites), seq_len(n_sites))

  # Deduplicate by first occurrence
  keep <- !duplicated(all_keys)
  stats::setNames(all_idx[keep], all_keys[keep])
}

#' Photoperiod table for a given year and location/latitude
#'
#' Returns daily daylight length (hours) for the specified year.
#' @param year Integer year (e.g., 2020).
#' @param lat Latitude in decimal degrees. Ignored if `location` is supplied.
#' @param location Optional location key; case-insensitive, ignores spaces/punct.
#'   Aliases like "saint johns" also work for "st_johns".
#' @param aggregate Return daily values (`"none"`) or monthly means (`"month"`).
#' @return `data.frame` with columns: `date`, `daylength_hours`, `lat`, `location`.
#' @examples
#' # Daily photoperiod for 2020 at 47.56°N (St. John's, NL)
#' photoperiod_year(2020, lat = 47.56)
#'
#' # Using a built-in location name (case/punctuation agnostic)
#' photoperiod_year(2020, location = "St John's")
#'
#' # Monthly means at 47.56°N
#' photoperiod_year(2020, lat = 47.56, aggregate = "month")
#' @export
photoperiod_year <- function(year, lat = NULL, location = NULL,
                             aggregate = c("none", "month")) {
  aggregate <- match.arg(aggregate)

  # Resolve latitude
  loc_label <- NA_character_
  if (!is.null(location)) {
    key_in <- normalize_key(location)
    keymap <- .build_site_keymap()

    idx <- unname(keymap[key_in])
    if (is.na(idx)) {
      # Fuzzy fallback (edit distance 1) on normalized keys
      cand <- agrep(key_in, names(keymap), max.distance = 1, ignore.case = TRUE)
      if (length(cand) == 1L) {
        idx <- keymap[[cand]]
      } else {
        stop("Unknown `location`. Try one of: ",
             paste(sort(names(.photoperiod_sites)), collapse = ", "),
             call. = FALSE)
      }
    }
    lat <- unname(.photoperiod_sites[[idx]])
    loc_label <- names(.photoperiod_sites)[[idx]]
  }

  # ---- place the new lines RIGHT AFTER this validation ----
  if (is.null(lat) || is.na(lat)) stop("Please supply `lat` or a valid `location`.")

  # NEW: give a placeholder label when called by latitude only (prevents aggregate() error)
  if (is.na(loc_label) || !nzchar(loc_label)) {
    loc_label <- sprintf("lat_%.2f", lat)
  }
  # ---------------------------------------------------------

  # Build date sequence for the whole year (handles leap years automatically)
  start <- as.Date(paste0(year, "-01-01"))
  end   <- as.Date(paste0(year, "-12-31"))
  dates <- seq(start, end, by = "day")

  dl <- daylength_f95(dates, lat)

  out <- data.frame(
    date = dates,
    daylength_hours = dl,
    lat = rep(lat, length(dates)),
    location = rep(loc_label, length(dates)),
    row.names = NULL
  )

  if (aggregate == "none") return(out)

  # Monthly means
  out$month <- as.integer(format(out$date, "%m"))
  agg <- stats::aggregate(daylength_hours ~ month + lat + location, out, mean)
  agg$date <- as.Date(paste(year, sprintf("%02d", agg$month), "01", sep = "-"))
  agg[order(agg$month), c("date", "daylength_hours", "lat", "location")]
}


#' List available built-in photoperiod sites
#' @return Named numeric vector of latitudes.
#' @export
photoperiod_sites <- function() .photoperiod_sites
