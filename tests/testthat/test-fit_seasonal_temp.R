test_that("fit_seasonal_temp returns metrics and optional plot", {
  data(weather_nl, package = "climecol")
  res <- fit_seasonal_temp(weather_nl, funcs = c("sin1","sin2"), plot = TRUE)

  # structure
  expect_true(is.list(res))
  expect_true(all(c("daily_avg","fits","metrics") %in% names(res)))
  expect_s3_class(res$daily_avg, "data.frame")
  expect_s3_class(res$metrics, "data.frame")

  # metrics contents
  expect_true(all(c("model","AIC","R2") %in% names(res$metrics)))
  expect_true(all(res$metrics$R2 >= 0 & res$metrics$R2 <= 1))
  expect_true(all(is.finite(res$metrics$AIC)))

  # fits list non-empty if any model converged
  expect_true(length(res$fits) >= 1)

  # plot when requested
  expect_true("plot" %in% names(res))
  expect_true(inherits(res$plot, "ggplot"))
})

test_that("fit_seasonal_temp works with tmin/tmax when tavg is missing", {
  # create a small example without tavg_c
  df <- head(weather_nl, 400)
  df$tavg_c <- NULL
  expect_true(all(c("tmin_c","tmax_c") %in% names(df)))

  res <- fit_seasonal_temp(df, funcs = "sin1", plot = FALSE)
  expect_true(nrow(res$metrics) >= 1)
  expect_true(all(res$metrics$R2 >= 0 & res$metrics$R2 <= 1))
})

test_that("fit_seasonal_temp errors if no temperature columns present", {
  df <- data.frame(date = as.Date("2020-01-01") + 0:10)
  expect_error(fit_seasonal_temp(df), "tavg_c|tmin_c")
})
