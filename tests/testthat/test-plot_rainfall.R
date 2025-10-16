# tests/testthat/test-plot_rainfall.R

test_that("plot_rainfall returns a ggplot for single-year data", {
  data(weather_nl)
  one_year <- subset(weather_nl, date >= as.Date("2012-01-01") & date <= as.Date("2012-12-31"))

  p <- plot_rainfall(one_year)
  expect_s3_class(p, "ggplot")
  # should have one layer (geom_line)
  expect_equal(length(p$layers), 1L)
  # data attached to the plot has needed columns
  expect_true(all(c("date", "rain_mm") %in% names(p$data)))
})

test_that("plot_rainfall returns a ggplot for multi-year data", {
  data(weather_nl)
  p <- plot_rainfall(weather_nl)
  expect_s3_class(p, "ggplot")
  expect_equal(length(p$layers), 1L)
  expect_true(all(c("date", "rain_mm") %in% names(p$data)))
})

test_that("plot_rainfall honors color and linewidth", {
  data(weather_nl)
  col <- "#56B4E9"
  lw  <- 0.8
  p <- plot_rainfall(weather_nl, color = col, linewidth = lw)

  lp <- p$layers[[1]]$aes_params
  # ggplot2 stores these as 'colour' and 'linewidth'
  expect_identical(lp$colour, col)
  expect_identical(lp$linewidth, lw)
})

test_that("plot_rainfall faceting by year works", {
  data(weather_nl)
  p <- plot_rainfall(weather_nl, facet_by_year = TRUE)
  expect_s3_class(p, "ggplot")
  expect_true(inherits(p$facet, "FacetWrap"))
})

test_that("plot_rainfall errors when required columns are missing", {
  bad <- data.frame(date = as.Date("2020-01-01") + 0:5, rain = runif(6))
  expect_error(plot_rainfall(bad), "date.*rain_mm")
})
