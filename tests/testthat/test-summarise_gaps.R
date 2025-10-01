test_that("summarise_gaps works per station", {
  df <- tibble::tibble(
    station = "A",
    date = seq(as.Date("2000-01-01"), as.Date("2000-01-10"), by = "day"),
    rain_mm = c(1, 2, NA, NA, 3, 4, 5, NA, 6, 7)
  )
  df_cal <- complete_daily_calendar(df)

  out <- summarise_gaps(df_cal, by = "station")

  expect_s3_class(out, "data.frame")
  expect_equal(out$station, "A")
  expect_equal(out$n_days, 10L)
  # Should count content-NA rows as missing (rows 3,4,8 in this example if all other cols are NA)
  expect_gte(out$n_missing, 1L)
  expect_true(out$coverage <= 1 && out$coverage >= 0)
})

test_that("summarise_gaps works per month", {
  df <- tibble::tibble(
    station = "A",
    date = seq(as.Date("2000-01-01"), as.Date("2000-02-05"), by = "day"),
    rain_mm = 1
  )
  df_cal <- complete_daily_calendar(df)
  out <- summarise_gaps(df_cal, by = "month")

  expect_true(all(c("station", "month", "n_days") %in% names(out)))

  jan <- out[out$month == "2000-01", , drop = FALSE]
  feb <- out[out$month == "2000-02", , drop = FALSE]
  expect_equal(jan$n_days, 31L)
  expect_equal(feb$n_days, 5L)   # partial February in this example
})
