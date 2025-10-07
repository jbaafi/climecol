test_that("fit_seasonal_photo works from generated location data", {
  skip_on_cran()
  res <- fit_seasonal_photo(location = "St John's", years = c(2023, 2024),
                            funcs = c("sin1","sin2"), plot = FALSE)
  expect_true(is.list(res))
  expect_true(all(c("daily_avg","fits","metrics") %in% names(res)))
  expect_true(all(c("model","AIC","R2") %in% names(res$metrics)))
  expect_true(nrow(res$metrics) >= 1)
  expect_true(all(c("day_of_year","avg_photo") %in% names(res$daily_avg)))
})

test_that("fit_seasonal_photo accepts df with photoperiod_hours", {
  set.seed(1)
  d <- data.frame(
    date = as.Date("2023-01-01") + 0:729
  )
  # make a smooth fake photoperiod
  t <- as.numeric(format(d$date, "%j"))
  d$photoperiod_hours <- 12 + 6 * cos(2*pi*(t)/365) + rnorm(nrow(d), 0, 0.05)
  res <- fit_seasonal_photo(df = d, funcs = "sin1", plot = TRUE)
  expect_true("plot" %in% names(res))
  expect_true(nrow(res$metrics) == 1)
  expect_true(all(c("fitted_sin1") %in% names(res$daily_avg)))
})

test_that("fit_seasonal_photo supports custom formula", {
  set.seed(2)
  d <- data.frame(
    date = as.Date("2024-01-01") + 0:729
  )
  t <- as.numeric(format(d$date, "%j"))
  d$photoperiod_hours <- 12 + 6 * cos(2*pi*(t)/365) + rnorm(nrow(d), 0, 0.05)

  res <- fit_seasonal_photo(
    df = d,
    funcs = character(0),
    custom = list(
      cos1 = list(
        formula = avg_photo ~ a + b * cos(2*pi*day_of_year/365),
        start   = list(a = 12, b = 6)
      )
    ),
    plot = FALSE
  )
  expect_true(nrow(res$metrics) == 1)
  expect_equal(res$metrics$model, "cos1")
  expect_true(is.finite(res$metrics$AIC[1]))
})
