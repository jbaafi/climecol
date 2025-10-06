test_that("fit_seasonal_temp accepts and fits a custom model", {
  data(weather_nl, package = "climecol")

  # Ensure tavg exists (it should in weather_nl, but be robust)
  df <- weather_nl
  if (!"tavg_c" %in% names(df) && all(c("tmin_c","tmax_c") %in% names(df))) {
    df$tavg_c <- rowMeans(df[, c("tmin_c","tmax_c")], na.rm = TRUE)
  }

  # Custom cosine model
  custom_models <- list(
    cos1 = list(
      formula = mean_temp ~ a + b * cos(2*pi*day_of_year/365),
      start   = list(a = mean(df$tavg_c, na.rm = TRUE), b = 5)
    )
  )

  res <- fit_seasonal_temp(
    df,
    funcs  = "sin1",          # keep a built-in so we exercise multiple fits
    custom = custom_models,
    plot   = TRUE
  )

  # Structure checks
  expect_true(is.list(res))
  expect_true(all(c("daily_avg","fits","metrics") %in% names(res)))
  expect_s3_class(res$daily_avg, "data.frame")
  expect_s3_class(res$metrics, "data.frame")

  # Metrics must include the custom model
  expect_true("cos1" %in% res$metrics$model)

  # Reasonable metric ranges
  cos_row <- res$metrics[res$metrics$model == "cos1", ]
  expect_true(is.finite(cos_row$AIC))
  expect_true(cos_row$R2 >= 0 && cos_row$R2 <= 1)

  # Daily output should include fitted_cos1
  expect_true("fitted_cos1" %in% names(res$daily_avg))
  expect_true(all(is.finite(res$daily_avg$fitted_cos1) | is.na(res$daily_avg$fitted_cos1)))

  # Plot object present when plot=TRUE
  expect_true("plot" %in% names(res))
  expect_s3_class(res$plot, "ggplot")
})

test_that("Unknown built-in model names are ignored with a warning", {
  data(weather_nl, package = "climecol")

  expect_warning(
    res <- fit_seasonal_temp(
      weather_nl,
      funcs  = c("sin1", "cos1", "not_a_model"),  # cos1 is NOT a built-in
      custom = NULL,
      plot   = FALSE
    ),
    regexp = "Ignoring unknown built-in model\\(s\\):"
  )

  # Should still fit sin1 at least
  expect_true("sin1" %in% res$metrics$model)
})
