test_that("weather_nl dataset is available and well-formed", {
  data(weather_nl, package = "climecol")
  expect_true(is.data.frame(weather_nl))
  expect_true(all(c("Date", "Rain_mm") %in% names(weather_nl)))
  expect_true(inherits(weather_nl$Date, "Date"))
  expect_true(is.numeric(weather_nl$Rain_mm))
})

test_that("plot_rainfall returns a ggplot object", {
  data(weather_nl, package = "climecol")
  p <- plot_rainfall(weather_nl)
  expect_s3_class(p, "ggplot")
})

test_that("plot_rainfall errors clearly when required columns are missing", {
  df <- data.frame(Time = Sys.Date(), Value = 1)
  expect_error(plot_rainfall(df), "Date|Rain_mm")
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
