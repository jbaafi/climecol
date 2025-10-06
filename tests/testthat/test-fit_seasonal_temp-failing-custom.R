test_that("failing custom model is skipped with a warning and others still fit", {
  data(weather_nl, package = "climecol")

  # Ensure tavg exists (usually present, but keep resilient)
  df <- weather_nl
  if (!"tavg_c" %in% names(df) && all(c("tmin_c","tmax_c") %in% names(df))) {
    df$tavg_c <- rowMeans(df[, c("tmin_c","tmax_c")], na.rm = TRUE)
  }

  # BAD custom model: formula has parameter 'c' but start omits it -> nls() should fail
  bad_custom <- list(
    bad = list(
      formula = mean_temp ~ a + b * cos(2*pi*day_of_year/365) + c * sin(2*pi*day_of_year/365),
      start   = list(a = mean(df$tavg_c, na.rm = TRUE), b = 5)  # missing 'c'
    )
  )

  # Fit with one good built-in + one bad custom; expect a warning
  expect_warning(
    res <- fit_seasonal_temp(
      df,
      funcs  = "sin1",
      custom = bad_custom,
      plot   = FALSE
    ),
    regexp = "failed to converge; skipping\\."
  )

  # Structure ok
  expect_true(is.list(res))
  expect_true(all(c("daily_avg","fits","metrics") %in% names(res)))

  # The good built-in should be present
  expect_true("sin1" %in% res$metrics$model)

  # The bad model should be absent from metrics and no fitted column created
  expect_false("bad" %in% res$metrics$model)
  expect_false("fitted_bad" %in% names(res$daily_avg))

  # The fits list should not contain 'bad'
  expect_false("bad" %in% names(res$fits))
})
