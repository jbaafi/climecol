test_that("simulate_rainfall_scenarios returns expected structure and size", {
  set.seed(123)
  data(weather_nl)
  dates <- as.Date("2012-01-01") + 0:29  # 30 days
  sims  <- simulate_rainfall_scenarios(weather_nl,
                                       times = dates,
                                       scenarios = c("baseline","dry","wet"),
                                       plot = FALSE)
  ser <- sims$series
  expect_s3_class(ser, "tbl_df")
  expect_true(all(c("date","month","scenario","rain_mm") %in% names(ser)))
  expect_equal(nrow(ser), length(dates) * 3L)
  expect_true(is.null(sims$plot))
})

test_that("dry is drier and wet is wetter on average", {
  set.seed(42)
  data(weather_nl)
  dates <- as.Date("2011-06-01") + 0:59
  sims  <- simulate_rainfall_scenarios(weather_nl,
                                       times = dates,
                                       scenarios = c("baseline","dry","wet"),
                                       plot = FALSE)
  ser <- sims$series
  m <- ser |>
    dplyr::group_by(.data$scenario) |>
    dplyr::summarise(mean_rain = mean(.data$rain_mm, na.rm = TRUE), .groups = "drop")
  mr <- stats::setNames(m$mean_rain, m$scenario)
  expect_lt(mr[["dry"]], mr[["baseline"]])
  expect_gt(mr[["wet"]], mr[["baseline"]])
})

test_that("erratic increases variability", {
  set.seed(7)
  data(weather_nl)
  dates <- as.Date("2013-03-01") + 0:89
  sims  <- simulate_rainfall_scenarios(weather_nl,
                                       times = dates,
                                       scenarios = c("baseline","erratic"),
                                       erratic_range = c(0.2, 2.0),
                                       plot = FALSE)
  ser <- sims$series
  v <- ser |>
    dplyr::group_by(.data$scenario) |>
    dplyr::summarise(sd_rain = stats::sd(.data$rain_mm, na.rm = TRUE), .groups = "drop")
  vr <- stats::setNames(v$sd_rain, v$scenario)
  expect_gt(vr[["erratic"]], vr[["baseline"]])
})

test_that("plot = TRUE returns a ggplot object", {
  set.seed(99)
  data(weather_nl)
  sims <- simulate_rainfall_scenarios(weather_nl,
                                      times = as.Date("2014-01-01") + 0:14,
                                      scenarios = c("baseline","wet"),
                                      plot = TRUE)
  expect_true(inherits(sims$plot, "ggplot"))
})
