test_that("normalize_weather_names standardizes common variants", {
  df <- tibble::tibble(
    Date = as.Date("2000-01-01"),
    T_min_C = -5,
    T_max_C = 3,
    Total.Rain..mm. = 2,
    Station.Name = "TestStation"
  )

  out <- normalize_weather_names(df)

  expect_true(all(c("date","tmin_c","tmax_c","rain_mm","station") %in% names(out)))
  expect_s3_class(out$date, "Date")
  expect_equal(out$station, "TestStation")
})

test_that("normalize_weather_names uses Climate.ID fallback", {
  df <- tibble::tibble(
    Date = as.Date("2000-01-01"),
    Climate.ID = "12345"
  )

  out <- normalize_weather_names(df)
  expect_equal(out$station, "12345")
})
