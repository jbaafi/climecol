test_that("impute_weather locf fills internal and edge gaps", {
  df <- tibble::tibble(
    station = "S",
    date = as.Date("2020-01-01") + 0:4,
    tmax_c = c(NA, 1, NA, NA, 4)
  )
  out <- impute_weather(df, method = "locf", cols = "tmax_c")
  # forward then backward fill should give: 1,1,1,4,4 (first NA gets 1 from backward pass)
  expect_equal(out$tmax_c, c(1,1,1,4,4))
})

test_that("impute_weather linear respects max_gap", {
  df <- tibble::tibble(
    station = "S",
    date = as.Date("2020-01-01") + 0:9,
    tmax_c = c(0, NA, NA, 3, NA, NA, NA, NA, NA, 9) # one short gap (2) and one long (5)
  )
  # Only fill gaps up to length 2
  out <- impute_weather(df, method = "linear", cols = "tmax_c", max_gap = 2)
  # positions 2-3 (index 2:3) should be filled; 5-9 remain NA until the last obs
  expect_false(any(is.na(out$tmax_c[c(2,3)])))
  expect_true(any(is.na(out$tmax_c[5:9])))
})

test_that("impute_weather spline fills when enough points exist", {
  df <- tibble::tibble(
    station = "S",
    date = as.Date("2020-01-01") + 0:6,
    tmax_c = c(0, NA, 2, NA, 4, NA, 6)
  )
  out <- impute_weather(df, method = "spline", cols = "tmax_c", max_gap = Inf)
  expect_false(any(is.na(out$tmax_c)))
})
