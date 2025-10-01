test_that("weather_nl dataset is available and well-formed", {
  data(weather_nl, package = "climecol")
  df <- normalize_weather_names(weather_nl)
  expect_true(all(c("date", "rain_mm") %in% names(df)))
  expect_true(inherits(df$date, "Date"))
  expect_true(is.numeric(df$rain_mm) || is.integer(df$rain_mm))
})

test_that("plot_rainfall returns a ggplot object", {
  data(weather_nl, package = "climecol")
  p <- plot_rainfall(weather_nl)
  expect_s3_class(p, "ggplot")
})

test_that("plot_rainfall errors clearly when required columns are missing", {
  df <- tibble::tibble(x = 1:3, y = 2:4)
  expect_error(plot_rainfall(df), regexp = "date|rain_mm")
})

test_that("plot_rainfall accepts character dates and coerces to Date", {
  df <- data.frame(
    Date    = c("2020-01-01", "2020-01-02"),
    Rain_mm = c(0, 5)
  )
  p <- plot_rainfall(df)
  expect_s3_class(p, "ggplot")
})

test_that("plot_rainfall handles zero and NA rainfall values", {
  df <- data.frame(
    Date    = as.Date(c("2020-01-01", "2020-01-02", "2020-01-03")),
    Rain_mm = c(0, NA_real_, 12.5)
  )
  p <- plot_rainfall(df)
  expect_s3_class(p, "ggplot")
})
