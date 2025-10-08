test_that("sample_rainfall_by_month returns correct length and type", {
  data(weather_nl)
  dseq <- seq.Date(as.Date("2012-03-01"), as.Date("2012-03-10"), by = "day")
  set.seed(42)
  sim <- sample_rainfall_by_month(dseq, weather_nl)
  expect_type(sim, "double")
  expect_length(sim, length(dseq))
})

test_that("sample_rainfall_by_month is reproducible with a seed", {
  data(weather_nl)
  dseq <- as.Date("2015-06-01") + 0:20
  sim1 <- sample_rainfall_by_month(dseq, weather_nl, seed = 123)
  sim2 <- sample_rainfall_by_month(dseq, weather_nl, seed = 123)
  expect_equal(sim1, sim2)
})

test_that("numeric dates are supported via origin", {
  data(weather_nl)
  idx <- 0:9
  sim_idx <- sample_rainfall_by_month(idx, weather_nl, origin = "2010-01-01", seed = 1)
  expect_length(sim_idx, length(idx))
  expect_true(all(sim_idx >= 0, na.rm = TRUE))
})

test_that("custom rain_col is respected when needed", {
  df <- data.frame(
    date = as.Date("2020-01-01") + 0:30,
    Month = as.integer(format(as.Date("2020-01-01") + 0:30, "%m")),
    Total.Rain.mm = c(rep(0, 10), rep(5, 21))
  )
  dseq <- as.Date("2020-02-01") + 0:5
  sim <- sample_rainfall_by_month(dseq, df, rain_col = "Total.Rain.mm", seed = 2)
  expect_true(all(sim %in% c(0, 5)))
})

test_that("gracefully returns zeros if a month has no pool", {
  # Build a tiny df with only January values
  df <- data.frame(
    date = as.Date("2020-01-01") + 0:5,
    rain_mm = c(0, 1, 0, 2, NA, 0)
  )
  # Ask for July dates (no pool -> 0s)
  dseq <- as.Date("2020-07-01") + 0:3
  sim <- sample_rainfall_by_month(dseq, df, seed = 9)
  expect_true(all(sim == 0))
})
